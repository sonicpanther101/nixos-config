#!/usr/bin/env python3
"""Keep a ~100 GB, phone-sized copy of the Music library up to date.

Picks whole albums, the most listened-to ones (Last.fm play counts) plus the most
recently added ones, until the size budget is full, then mirrors them into a second
folder with the SAME layout as the library (Artist/Year - Album/NN - Title.flac).
Files are hard links, so the copy costs no extra disk space. Syncthing sends that
folder to the phone as send-only, so albums that drop out of the set are removed
from the phone as well. The real library (and Lidarr) is never touched.
"""
import argparse
import json
import os
import re
import shutil
import subprocess
import sys
import unicodedata
import urllib.parse
import urllib.request

AUDIO = {".flac", ".mp3", ".m4a", ".ogg", ".opus", ".wav", ".wma", ".aac", ".ape", ".wv"}
GIB = 1024 ** 3


def log(msg):
    print(msg, flush=True)


def load_env():
    """Read LASTFM_API_KEY / LASTFM_USER from the systemd credential or a file."""
    candidates = []
    cred = os.environ.get("CREDENTIALS_DIRECTORY")
    if cred:
        candidates.append(os.path.join(cred, "lastfm.env"))
    if os.environ.get("PHONE_SYNC_ENV_FILE"):
        candidates.append(os.environ["PHONE_SYNC_ENV_FILE"])
    for path in candidates:
        try:
            with open(path) as fh:
                for line in fh:
                    line = line.strip()
                    if line and not line.startswith("#") and "=" in line:
                        k, v = line.split("=", 1)
                        os.environ.setdefault(k.strip(), v.strip().strip("'\""))
            return
        except OSError:
            continue


def scan_library(music):
    """-> albums {(artist, album): {...}}, artist_files {artist: [(rel, size)]}"""
    out = subprocess.run(
        ["find", music, "-type", "f", "-printf", "%P\\0%s\\0%B@\\0%T@\\0"],
        check=True, capture_output=True,
    ).stdout.split(b"\0")
    albums, artist_files = {}, {}
    for i in range(0, len(out) - 3, 4):
        rel = os.fsdecode(out[i])
        parts = rel.split(os.sep)
        if any(p.startswith(".") for p in parts) or len(parts) < 2:
            continue
        size = int(out[i + 1])
        try:
            born = float(out[i + 2])
        except ValueError:
            born = 0.0
        mtime = float(out[i + 3])
        if born <= 0:
            born = mtime
        if len(parts) == 2:                       # Artist/artist.jpg and the like
            artist_files.setdefault(parts[0], []).append((rel, size))
            continue
        key = (parts[0], parts[1])
        a = albums.setdefault(key, {"files": [], "size": 0, "tracks": 0, "added": None})
        a["files"].append(rel)
        a["size"] += size
        if os.path.splitext(parts[-1])[1].lower() in AUDIO:
            a["tracks"] += 1
            # earliest file = when the album first arrived (a later Lidarr upgrade
            # replaces a file, which must not make an old album look new)
            a["added"] = born if a["added"] is None else min(a["added"], born)
    return {k: v for k, v in albums.items() if v["tracks"] > 0}, artist_files


def norm(text):
    """Lower-case, no accents, no punctuation or spaces: 'Café Tacvba!' -> 'cafetacvba'."""
    text = unicodedata.normalize("NFKD", text.replace("&", " and "))
    text = "".join(c for c in text if not unicodedata.combining(c)).casefold()
    return "".join(c for c in text if c.isalnum())


def norm_artist(text):
    return norm(re.sub(r"^the\s+", "", text.strip(), flags=re.I))


def strip_paren(text):
    return re.sub(r"\s*[(\[][^)\]]*[)\]]", "", text).strip()


def strip_year(album):
    return re.sub(r"^\d{4}\s*-\s*", "", album)


def lastfm(params):
    q = {"api_key": os.environ["LASTFM_API_KEY"], "format": "json", **params}
    url = "https://ws.audioscrobbler.com/2.0/?" + urllib.parse.urlencode(q)
    req = urllib.request.Request(url, headers={"User-Agent": "phone-music-sync/1.0"})
    with urllib.request.urlopen(req, timeout=60) as r:
        data = json.load(r)
    if "error" in data:
        raise RuntimeError(f"Last.fm error {data['error']}: {data.get('message')}")
    return data


def fetch_plays(albums):
    """-> ({(artist, album): scrobbles}, [(artist, album, scrobbles) with no local match]).

    Last.fm names albums "Artist" / "Album", the library says "Artist" / "2002 - Album",
    so both sides are normalised (case, accents, punctuation, a leading year, "The ").
    Raises on any problem.
    """
    user = os.environ["LASTFM_USER"]
    index = {}
    for k in albums:
        a, b = norm_artist(k[0]), strip_year(k[1])
        for name in (b, strip_paren(b)):           # "(Deluxe Edition)" etc. match either way
            index.setdefault((a, norm(name)), set()).add(k)

    plays, unmatched = {}, []
    page, pages = 1, 1
    while page <= min(pages, 30):                  # 30 pages x 1000 albums is plenty
        top = lastfm({"method": "user.gettopalbums", "user": user, "period": "overall",
                      "limit": 1000, "page": page})["topalbums"]
        pages = int(top.get("@attr", {}).get("totalPages", 1))
        for al in top.get("album", []):
            name, artist = al["name"], al["artist"]["name"]
            n = int(al.get("playcount") or 0)
            a = norm_artist(artist)
            hits = index.get((a, norm(name))) or index.get((a, norm(strip_paren(name))))
            if not hits:
                unmatched.append((artist, name, n))
                continue
            for k in hits:
                plays[k] = plays.get(k, 0) + n
        page += 1
    return plays, unmatched


def current_set(out_root):
    cur = set()
    try:
        for artist in os.scandir(out_root):
            if artist.name.startswith(".") or not artist.is_dir():
                continue
            for album in os.scandir(artist.path):
                if album.is_dir():
                    cur.add((artist.name, album.name))
    except FileNotFoundError:
        pass
    return cur


def choose(albums, plays, current, budget, top_share, sticky):
    def score(k):
        s = plays.get(k, 0) / max(albums[k]["tracks"], 1)
        return s * sticky if k in current else s

    top = sorted((k for k in albums if plays.get(k, 0) > 0), key=score, reverse=True)
    recent = sorted(albums, key=lambda k: albums[k]["added"], reverse=True)
    chosen, used, why = set(), 0, {}

    def fill(order, limit, label):
        nonlocal used
        for k in order:
            if k in chosen or used + albums[k]["size"] > limit:
                continue
            chosen.add(k)
            used += albums[k]["size"]
            why[k] = label

    fill(top, budget * top_share, "top")
    fill(recent, budget, "new")        # takes the rest, including any unused top share
    return chosen, used, why


def mirror(albums, artist_files, chosen, src_root, out_root, dry):
    wanted = set()
    for k in chosen:
        wanted.update(albums[k]["files"])
    for artist in {k[0] for k in chosen}:
        wanted.update(rel for rel, _ in artist_files.get(artist, []))

    linked = copied = removed = 0
    for rel in sorted(wanted):
        src, dst = os.path.join(src_root, rel), os.path.join(out_root, rel)
        try:
            ss = os.stat(src)
        except FileNotFoundError:
            continue
        try:
            ds = os.stat(dst)
        except FileNotFoundError:
            ds = None
        if ds and (ds.st_dev, ds.st_ino) == (ss.st_dev, ss.st_ino):
            continue
        if ds and ds.st_size == ss.st_size and int(ds.st_mtime) == int(ss.st_mtime):
            continue                                  # an earlier fallback copy, unchanged
        if dry:
            linked += 1
            continue
        os.makedirs(os.path.dirname(dst), exist_ok=True)
        if ds:
            os.remove(dst)
        try:
            os.link(src, dst)
            linked += 1
        except OSError:
            shutil.copy2(src, dst)
            copied += 1

    if os.path.isdir(out_root):
        for dirpath, _dirs, files in os.walk(out_root, topdown=False):
            reldir = os.path.relpath(dirpath, out_root)
            if reldir != "." and reldir.split(os.sep)[0].startswith("."):
                continue                              # .stfolder, .stversions, .stignore...
            for f in files:
                rel = os.path.normpath(os.path.join(reldir, f))
                if reldir == "." and f.startswith("."):
                    continue
                if rel not in wanted:
                    removed += 1
                    if not dry:
                        os.remove(os.path.join(dirpath, f))
            if reldir != "." and not dry:
                try:
                    os.rmdir(dirpath)                 # only succeeds when empty
                except OSError:
                    pass
    return linked, copied, removed


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--dry-run", action="store_true", help="show what would change, change nothing")
    args = ap.parse_args()
    load_env()

    music = os.environ["PHONE_SYNC_MUSIC"].rstrip("/")
    out_root = os.environ["PHONE_SYNC_OUT"].rstrip("/")
    budget = float(os.environ.get("PHONE_SYNC_BUDGET_GB", "100")) * GIB
    top_share = float(os.environ.get("PHONE_SYNC_TOP_SHARE", "0.6"))
    sticky = float(os.environ.get("PHONE_SYNC_STICKY", "1.25"))

    albums, artist_files = scan_library(music)
    if not albums:
        log("No albums found in the library (drive not mounted?). Leaving the phone folder alone.")
        return 1
    try:
        plays, unmatched = fetch_plays(albums)
    except Exception as e:                            # never prune on a failed lookup
        log(f"Could not read play counts from Last.fm ({e!r}). Leaving the phone folder alone.")
        return 1
    if not plays:
        log("Last.fm returned no albums that match the library. Leaving the phone folder alone.")
        return 1

    current = current_set(out_root)
    chosen, used, why = choose(albums, plays, current, budget, top_share, sticky)
    if not chosen:
        log("Nothing selected. Leaving the phone folder alone.")
        return 1

    n_top = sum(1 for k in chosen if why[k] == "top")
    log(f"{len(chosen)} albums, {used / GIB:.1f} GiB of {budget / GIB:.0f} GiB "
        f"({n_top} picked for plays, {len(chosen) - n_top} for being new). "
        f"Library: {len(albums)} albums, {sum(a['size'] for a in albums.values()) / GIB:.0f} GiB.")
    if unmatched:
        log(f"  {len(unmatched)} Last.fm albums have no folder in the library; the most played:")
        for artist, name, n in unmatched[:10]:
            log(f"    {n:>5} plays  {artist} / {name}")
    for sign, keys in (("+", sorted(chosen - current)), ("-", sorted(current - chosen))):
        for k in keys[:40]:
            size = albums[k]["size"] / GIB if k in albums else 0
            log(f"  {sign} {k[0]} / {k[1]}  ({size:.2f} GiB{', ' + why[k] if k in why else ''})")
        if len(keys) > 40:
            log(f"  {sign} ... and {len(keys) - 40} more")

    linked, copied, removed = mirror(albums, artist_files, chosen, music, out_root, args.dry_run)
    verb = "would be" if args.dry_run else "were"
    log(f"Files {verb}: {linked} linked, {copied} copied, {removed} removed.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
