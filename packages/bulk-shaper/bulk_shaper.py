#!/usr/bin/env python3
"""
bulk_shaper.py - keep qBittorrent and slskd from crowding everyone else off the internet.

The server can't see what the phones and laptops in the house are doing, but it can see
the one thing that gives it away: when somebody saturates the fibre link, ping times to
the internet climb (the queue in the router fills up). So:

  * Everything qBittorrent and slskd send or receive over the internet (not the LAN) is
    put in a "bulk" class with its own speed cap. Everything else on the server (Jellyfin,
    Nextcloud, updates, ping ...) is untouched. Both apps share ONE cap, per direction.
  * Every couple of seconds the latency to a few public servers is compared with the
    best latency seen recently. If it is well above that, the bulk cap is cut (x0.8). If
    the link looks healthy and the apps are using their allowance, the cap creeps back up
    towards the maximum. So the apps use up to the maximum while the house is quiet, and
    back off towards the minimum while somebody else is busy.

How it works: nftables marks packets owned by the apps' users, tc (HTB + fq_codel) shapes
the marked class on the network card (upload) and, through an IFB device, on the way in
(download; the mark is carried over on the connection, so replies are recognised).

    bulk_shaper.py run        set everything up, then adjust the caps until stopped
    bulk_shaper.py teardown   remove all of it (also done by systemd when the unit stops)
    bulk_shaper.py status     show the current caps, bulk throughput and latency

Environment (set by packages/bulk-shaper.nix)
    BULK_IFACE          network card the internet comes in on
    BULK_USERS          comma separated users whose traffic is "bulk"
    BULK_MAX_DOWN_MBIT / BULK_MAX_UP_MBIT   the most the apps may use (cap while quiet)
    BULK_MIN_DOWN_MBIT / BULK_MIN_UP_MBIT   the least they are squeezed to (while busy)
    BULK_LINE_MBIT      speed of the network card (1000 for gigabit)
    BULK_REFLECTORS     space separated hosts pinged to measure latency
    BULK_BAD_MS         latency this far above normal = somebody is using the link (default 25)
    BULK_GOOD_MS        latency this close to normal = link is idle enough (default 10)
    BULK_INTERVAL       seconds between adjustments (default 2)
"""
import json
import os
import re
import signal
import statistics
import subprocess
import sys
import threading
import time

IFB = "ifb-bulk"            # virtual card that incoming traffic is redirected through
TABLE = "bulk_shaper"       # our own nftables table (separate from the NixOS firewall)
MARK = 2                    # packet/connection mark meaning "bulk"
BULK_CLASS = "1:20"
STATE_FILE = "/run/bulk-shaper/state.json"

# Addresses that never leave the house: not counted as bulk, so the web UIs stay fast.
LAN4 = "10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16, 127.0.0.0/8, 169.254.0.0/16"
LAN6 = "fc00::/7, fe80::/10, ::1"


class Config:
    def __init__(self):
        e = os.environ
        self.iface = e["BULK_IFACE"]
        self.users = [u for u in e["BULK_USERS"].split(",") if u]
        self.max_down = int(float(e["BULK_MAX_DOWN_MBIT"]) * 1000)   # all rates in kbit/s
        self.max_up = int(float(e["BULK_MAX_UP_MBIT"]) * 1000)
        self.min_down = int(float(e["BULK_MIN_DOWN_MBIT"]) * 1000)
        self.min_up = int(float(e["BULK_MIN_UP_MBIT"]) * 1000)
        self.line = int(float(e.get("BULK_LINE_MBIT", "1000")) * 1000)
        self.reflectors = e.get("BULK_REFLECTORS", "1.1.1.1 8.8.8.8 9.9.9.9").split()
        self.bad_ms = float(e.get("BULK_BAD_MS", "25"))
        self.good_ms = float(e.get("BULK_GOOD_MS", "10"))
        self.interval = float(e.get("BULK_INTERVAL", "2"))


def log(msg):
    print(msg, flush=True)


def sh(*cmd, check=True):
    r = subprocess.run(cmd, capture_output=True, text=True)
    if check and r.returncode != 0:
        raise RuntimeError(f"{' '.join(cmd)} failed: {(r.stderr or r.stdout).strip()}")
    return r


# ─── set up / tear down ──────────────────────────────────────────────────────
def kbit(n):
    return f"{int(n)}kbit"


def build_htb(dev, lo, hi, line):
    """Two classes: 1:10 everything else (first in line), 1:20 bulk (last, capped)."""
    sh("tc", "qdisc", "add", "dev", dev, "root", "handle", "1:", "htb", "default", "10")
    sh("tc", "class", "add", "dev", dev, "parent", "1:", "classid", "1:1",
       "htb", "rate", kbit(line), "ceil", kbit(line))
    sh("tc", "class", "add", "dev", dev, "parent", "1:1", "classid", "1:10",
       "htb", "rate", kbit(line - lo), "ceil", kbit(line), "prio", "0")
    sh("tc", "class", "add", "dev", dev, "parent", "1:1", "classid", BULK_CLASS,
       "htb", "rate", kbit(lo), "ceil", kbit(hi), "prio", "7")
    sh("tc", "qdisc", "add", "dev", dev, "parent", "1:10", "handle", "10:", "fq_codel")
    sh("tc", "qdisc", "add", "dev", dev, "parent", BULK_CLASS, "handle", "20:", "fq_codel")
    sh("tc", "filter", "add", "dev", dev, "parent", "1:", "protocol", "all", "prio", "1",
       "handle", str(MARK), "fw", "classid", BULK_CLASS)


def set_cap(dev, lo, cap):
    sh("tc", "class", "change", "dev", dev, "parent", "1:1", "classid", BULK_CLASS,
       "htb", "rate", kbit(lo), "ceil", kbit(cap), "prio", "7")


def teardown():
    cfg_iface = os.environ.get("BULK_IFACE")
    if cfg_iface:
        sh("tc", "qdisc", "del", "dev", cfg_iface, "root", check=False)
        sh("tc", "qdisc", "del", "dev", cfg_iface, "ingress", check=False)
    sh("ip", "link", "del", IFB, check=False)
    sh("nft", "delete", "table", "inet", TABLE, check=False)
    try:
        os.remove(STATE_FILE)
    except FileNotFoundError:
        pass


def setup(cfg):
    teardown()
    uids = ", ".join(str(int(sh("id", "-u", u).stdout)) for u in cfg.users)

    # Mark the apps' internet traffic, on the packet (for the upload shaper) and on the
    # connection (so the replies coming back in can be recognised on the way in).
    ruleset = f"""
table inet {TABLE} {{
  chain mark_out {{
    type filter hook output priority mangle; policy accept;
    meta nfproto ipv4 ip daddr {{ {LAN4} }} return
    meta nfproto ipv6 ip6 daddr {{ {LAN6} }} return
    meta skuid {{ {uids} }} meta mark set {MARK} ct mark set {MARK}
  }}
}}
"""
    r = subprocess.run(["nft", "-f", "-"], input=ruleset, capture_output=True, text=True)
    if r.returncode != 0:
        raise RuntimeError(f"nft failed: {r.stderr.strip()}")

    # Upload: shape on the card itself.
    build_htb(cfg.iface, cfg.min_up, cfg.max_up, cfg.line)

    # Download: redirect everything arriving on the card through the IFB device, restoring
    # the connection mark first, and shape it there.
    sh("ip", "link", "add", IFB, "type", "ifb")
    sh("ip", "link", "set", IFB, "up")
    build_htb(IFB, cfg.min_down, cfg.max_down, cfg.line)
    sh("tc", "qdisc", "add", "dev", cfg.iface, "handle", "ffff:", "ingress")
    sh("tc", "filter", "add", "dev", cfg.iface, "parent", "ffff:", "protocol", "all",
       "prio", "10", "u32", "match", "u32", "0", "0",
       "action", "connmark", "action", "mirred", "egress", "redirect", "dev", IFB)


# ─── measuring ───────────────────────────────────────────────────────────────
def parse_ping(output):
    """Average round trip in ms from iputils' summary line, or None."""
    m = re.search(r"min/avg/max\S* = [\d.]+/([\d.]+)/", output)
    return float(m.group(1)) if m else None


def probe(hosts, count=4, gap=0.25):
    """Median of the average latency to each host, pinged in parallel (about 1 second)."""
    procs = [subprocess.Popen(["ping", "-n", "-q", "-c", str(count), "-i", str(gap), "-W", "1", h],
                              stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, text=True)
             for h in hosts]
    values = []
    for p in procs:
        try:
            out, _ = p.communicate(timeout=count * gap + 5)
        except subprocess.TimeoutExpired:
            p.kill()
            continue
        v = parse_ping(out)
        if v is not None:
            values.append(v)
    return statistics.median(values) if values else None


def class_bytes(dev):
    """Bytes the bulk class has sent so far on this device."""
    out = sh("tc", "-j", "-s", "class", "show", "dev", dev).stdout
    for c in json.loads(out):
        if c.get("handle") == BULK_CLASS:
            return int(c.get("bytes", c.get("stats", {}).get("bytes", 0)))
    return 0


# ─── deciding ────────────────────────────────────────────────────────────────
def classify(delta_ms, bad_ms, good_ms):
    if delta_ms > bad_ms:
        return "busy"       # somebody is using the link: back off
    if delta_ms < good_ms:
        return "quiet"      # room to spare
    return "ok"


def next_cap(cap, lo, hi, load, state, decrease=0.8, increase=10_000):
    """New cap (kbit/s) for one direction.
    Cut it when the link is busy and the apps are really using a good part of it; raise it
    when the link is quiet and the apps are pressing against it. Otherwise leave it."""
    if state == "busy" and load >= 0.5 * cap:
        return max(lo, int(cap * decrease))
    if state == "quiet" and load >= 0.7 * cap:
        return min(hi, cap + increase)
    return cap


def run(cfg):
    setup(cfg)
    stop = threading.Event()
    for sig in (signal.SIGTERM, signal.SIGINT):
        signal.signal(sig, lambda *_: stop.set())

    caps = {"down": cfg.max_down, "up": cfg.max_up}
    bounds = {"down": (cfg.min_down, cfg.max_down), "up": (cfg.min_up, cfg.max_up)}
    dev = {"down": IFB, "up": cfg.iface}
    last = {d: (time.monotonic(), class_bytes(dev[d])) for d in dev}
    base = None
    log(f"bulk-shaper: {', '.join(cfg.users)} on {cfg.iface}; down {cfg.min_down // 1000}-"
        f"{cfg.max_down // 1000} Mbit, up {cfg.min_up // 1000}-{cfg.max_up // 1000} Mbit")

    while not stop.is_set():
        started = time.monotonic()
        try:
            rtt = probe(cfg.reflectors)
            load = {}
            for d in dev:
                now, total = time.monotonic(), class_bytes(dev[d])
                t0, b0 = last[d]
                load[d] = (total - b0) * 8 / 1000 / max(now - t0, 0.001)   # kbit/s
                last[d] = (now, total)

            state, delta = "unknown", 0.0
            if rtt is not None:
                if base is None or rtt < base:
                    base = rtt                      # best latency seen: the "empty link" figure
                delta = rtt - base
                state = classify(delta, cfg.bad_ms, cfg.good_ms)
                if state != "busy":
                    base += (rtt - base) * 0.01     # let it drift up slowly if routes change

            for d in dev:
                new = next_cap(caps[d], *bounds[d], load[d], state)
                if new != caps[d]:
                    set_cap(dev[d], bounds[d][0], new)
                    if abs(new - caps[d]) >= 0.05 * bounds[d][1] or new in bounds[d]:
                        log(f"{d} cap {caps[d] // 1000} -> {new // 1000} Mbit "
                            f"(link {state}, +{delta:.0f} ms over {base:.0f} ms)")
                    caps[d] = new

            os.makedirs(os.path.dirname(STATE_FILE), exist_ok=True)
            with open(STATE_FILE, "w") as f:
                json.dump({
                    "state": state,
                    "rtt_ms": rtt, "baseline_ms": base,
                    "down_cap_mbit": caps["down"] / 1000, "up_cap_mbit": caps["up"] / 1000,
                    "down_now_mbit": load["down"] / 1000, "up_now_mbit": load["up"] / 1000,
                    "updated": time.time(),
                }, f)
        except Exception as e:      # a hiccup (card down, ping failed): keep the caps, retry
            log(f"bulk-shaper: {e}")
            stop.wait(5)
        stop.wait(max(0.0, cfg.interval - (time.monotonic() - started)))

    log("bulk-shaper: stopping")


def status():
    try:
        with open(STATE_FILE) as f:
            s = json.load(f)
    except FileNotFoundError:
        print("bulk-shaper is not running (no state file).")
        return 1
    age = time.time() - s["updated"]
    rtt = "?" if s["rtt_ms"] is None else f"{s['rtt_ms']:.0f} ms"
    base = "?" if s["baseline_ms"] is None else f"{s['baseline_ms']:.0f} ms"
    print(f"link:     {s['state']}   (latency {rtt}, normal {base}; updated {age:.0f}s ago)")
    print(f"download: {s['down_now_mbit']:.1f} Mbit/s of a {s['down_cap_mbit']:.0f} Mbit cap")
    print(f"upload:   {s['up_now_mbit']:.1f} Mbit/s of a {s['up_cap_mbit']:.0f} Mbit cap")
    return 0


def main():
    cmd = sys.argv[1] if len(sys.argv) > 1 else "status"
    if cmd == "run":
        run(Config())
    elif cmd == "teardown":
        teardown()
    elif cmd == "status":
        sys.exit(status())
    else:
        sys.exit(__doc__)


if __name__ == "__main__":
    main()
