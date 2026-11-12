#!/usr/bin/env python3
"""
lidarr_hook.py - run the non-interactive half of the music pipeline from
Lidarr, so a finished download comes out the other side with lyrics,
ReplayGain, cover + artist images and sane folder names, with no prompts.

Register it once in Lidarr: Settings > Connect > + > Custom Script
    Path:      the path to this script (on NixOS: /run/current-system/sw/bin/lidarr-hook)
    Triggers:  On Import, On Upgrade, On Artist Add      (nothing else is needed)

What it does per event
----------------------
ArtistAdd      Lidarr has just picked a folder name for the artist from
               MusicBrainz ("twenty one pilots"). If a folder that differs only
               in capitalisation already exists ("Twenty One Pilots"), point the
               artist at that one instead, before Lidarr creates anything.
               This is synchronous and takes milliseconds.

AlbumDownload  Queue a job and return straight away, so Lidarr's import queue
               is never held up by network lookups. A detached worker then:
                 1. safety net: if a capitalisation-variant folder exists after
                    all (artist or album level) merge into the established one
                    and tell Lidarr to rescan
                 2. adopt the library's spelling of ARTIST/ALBUMARTIST tags, so
                    Lidarr's "twenty one pilots" tag doesn't split the artist
                 3. lyrics: LRCLIB then NetEase (lyrics_fetcher.py)
                 4. ReplayGain track + album (replaygain.py), whole album at once
                 5. front cover + artist image (lidarr_images.py)

Run by hand
-----------
    lidarr_hook.py --fix-case ROOT [--apply]   find/merge existing case-split folders
    lidarr_hook.py --sweep ROOT [--dry-run]    fill lyrics/ReplayGain/images gaps in
                                               a library that already exists

Tracks that still need a human (lyrics only unsynced, or not found) are listed
in  <state dir>/needs_attention.tsv  for lyrics_checker.py to chew through.

Environment (all optional)
    MUSIC_PIPELINE_STATE   state/log/queue dir          (default ~/.music_pipeline/lidarr)
    LIDARR_CONFIG_XML      Lidarr's config.xml          (default: found next to its data dir)
    LIDARR_URL / LIDARR_API_KEY   override what config.xml says
    LIDARR_HOOK_SKIP       comma list of: lyrics,replaygain,images,tags
"""

import fcntl
import json
import os
import re
import shutil
import subprocess
import sys
import time
import unicodedata
import xml.etree.ElementTree as ET
from collections import Counter, defaultdict
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))

import requests  # noqa: E402

STATE = Path(os.environ.get("MUSIC_PIPELINE_STATE", Path.home() / ".music_pipeline" / "lidarr"))
QUEUE = STATE / "queue"
FAILED = STATE / "failed"
LOCK = STATE / "worker.lock"
LOGFILE = STATE / "hook.log"
ATTENTION = STATE / "needs_attention.tsv"
NOT_FOUND = STATE / "lyrics_not_found.json"
NOT_FOUND_RETRY_DAYS = 30

SKIP = {s.strip() for s in os.environ.get("LIDARR_HOOK_SKIP", "").split(",") if s.strip()}
AUDIO_EXT = {".flac", ".mp3", ".m4a", ".ogg", ".opus", ".wav"}
DISC_DIR = re.compile(r"^(disc|disk|cd)\s*\d+", re.I)


def log(msg=""):
    print(f"{time.strftime('%Y-%m-%d %H:%M:%S')}  {msg}", flush=True)


def env(name, default=""):
    return os.environ.get(name) or os.environ.get(name.upper()) or default


def fold(s):
    return unicodedata.normalize("NFC", s).casefold()


# ==========================================================================
# Lidarr API
# ==========================================================================

class Lidarr:
    def __init__(self, base, key):
        self.base, self.key = base.rstrip("/"), key

    @classmethod
    def load(cls):
        url, key = os.environ.get("LIDARR_URL"), os.environ.get("LIDARR_API_KEY")
        if not (url and key):
            candidates = [os.environ.get("LIDARR_CONFIG_XML", ""),
                          "/var/lib/lidarr/.config/Lidarr/config.xml",
                          str(Path.home() / ".config/Lidarr/config.xml")]
            for c in candidates:
                if c and Path(c).is_file():
                    try:
                        root = ET.parse(c).getroot()
                        key = key or root.findtext("ApiKey")
                        url = url or f"http://127.0.0.1:{root.findtext('Port') or 8686}{root.findtext('UrlBase') or ''}"
                        break
                    except (ET.ParseError, OSError):
                        continue
        return cls(url, key) if url and key else None

    def _req(self, method, path, **kw):
        r = requests.request(method, f"{self.base}/api/v1{path}", headers={"X-Api-Key": self.key}, timeout=30, **kw)
        r.raise_for_status()
        return r.json() if r.content else None

    def get(self, path, **params):
        return self._req("GET", path, params=params)

    def put(self, path, body, **params):
        return self._req("PUT", path, json=body, params=params)

    def command(self, name, **body):
        return self._req("POST", "/command", json={"name": name, **body})

    def set_artist_path(self, artist, new_path):
        artist = dict(artist)
        artist["path"] = str(new_path)
        self.put(f"/artist/{artist['id']}", artist, moveFiles="false")


def lidarr_or_none():
    try:
        return Lidarr.load()
    except Exception as e:  # never let a missing API stop the file work
        log(f"  (Lidarr API unavailable: {e})")
        return None


# ==========================================================================
# folder-case handling
# ==========================================================================

def music_count(d):
    return sum(1 for f in Path(d).rglob("*") if f.suffix.lower() in AUDIO_EXT)


def variants(path):
    """Directories beside `path` whose name equals it ignoring case (and
    including `path` itself if it exists)."""
    parent = Path(path).parent
    if not parent.is_dir():
        return []
    return [d for d in parent.iterdir() if d.is_dir() and fold(d.name) == fold(Path(path).name)]


def pick_canonical(dirs):
    """The established folder wins: most music in it, then a name that isn't
    all-lowercase/all-caps (those are what metadata providers hand back), then
    alphabetical so the choice is stable."""
    def key(d):
        n = d.name
        return (-music_count(d), n == n.lower() or n == n.upper(), n)
    return sorted(dirs, key=key)[0]


def canonical(path):
    path = Path(path)
    vs = variants(path)
    if not vs:
        return path
    if len(vs) == 1:
        return vs[0]
    return pick_canonical(vs)


def merge_dir(src, dst):
    """Move everything in src into dst, matching sub-folders ignoring case.
    Never overwrites: a name clash leaves the file where it is."""
    src, dst = Path(src), Path(dst)
    existing = {fold(e.name): e for e in dst.iterdir()}
    for child in sorted(src.iterdir()):
        target = existing.get(fold(child.name))
        if target is None:
            shutil.move(str(child), str(dst / child.name))
        elif child.is_dir() and target.is_dir():
            merge_dir(child, target)
        else:
            log(f"  clash, left in place: {child}")
    try:
        src.rmdir()
    except OSError:
        pass


def resolve_ci(base, parts):
    """Follow `parts` under `base`, matching each name ignoring case."""
    cur = Path(base)
    for part in parts:
        if not cur.is_dir():
            return None
        hit = next((e for e in cur.iterdir() if fold(e.name) == fold(part)), None)
        if hit is None:
            return None
        cur = hit
    return cur


def album_root(track):
    """The album folder (steps out of a 'Disc 1' folder)."""
    d = Path(track).parent
    return d.parent if DISC_DIR.match(d.name) else d


# ==========================================================================
# ArtistAdd
# ==========================================================================

def on_artist_add():
    api = lidarr_or_none()
    artist_id = env("lidarr_artist_id")
    if not (api and artist_id):
        return
    artist = api.get(f"/artist/{artist_id}")
    path = Path(artist["path"])
    canon = canonical(path)
    if canon != path:
        log(f"ArtistAdd: '{path.name}' -> existing folder '{canon.name}'")
        api.set_artist_path(artist, canon)
    else:
        log(f"ArtistAdd: '{path.name}' - no case-variant folder, nothing to do")


# ==========================================================================
# AlbumDownload -> queue -> worker
# ==========================================================================

def enqueue():
    tracks = [t for t in env("lidarr_addedtrackpaths").split("|") if t]
    if not tracks:
        return
    job = {k: env(f"lidarr_{k}") for k in (
        "artist_id", "artist_name", "artist_path", "artist_mbid",
        "album_id", "album_title", "album_mbid")}
    job["tracks"] = tracks
    QUEUE.mkdir(parents=True, exist_ok=True)
    tmp = QUEUE / f".{time.time_ns()}.tmp"
    tmp.write_text(json.dumps(job))
    tmp.rename(QUEUE / f"{time.time_ns()}.json")
    spawn_worker()
    log(f"queued: {job['artist_name']} - {job['album_title']} ({len(tracks)} track(s))")


def spawn_worker():
    STATE.mkdir(parents=True, exist_ok=True)
    out = open(LOGFILE, "a")
    subprocess.Popen([sys.executable, str(Path(__file__).resolve()), "--worker"],
                     stdin=subprocess.DEVNULL, stdout=out, stderr=subprocess.STDOUT,
                     start_new_session=True, close_fds=True)


def worker():
    STATE.mkdir(parents=True, exist_ok=True)
    if LOGFILE.exists() and LOGFILE.stat().st_size > 5_000_000:
        LOGFILE.write_text("")
    while True:
        fh = open(LOCK, "w")
        try:
            fcntl.flock(fh, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            return  # another worker is already draining the queue
        try:
            for jf in sorted(QUEUE.glob("*.json")):
                try:
                    job = json.loads(jf.read_text())
                    process_job(job)
                    jf.unlink()
                except Exception as e:
                    log(f"JOB FAILED ({jf.name}): {e}")
                    FAILED.mkdir(parents=True, exist_ok=True)
                    shutil.move(str(jf), str(FAILED / jf.name))
        finally:
            fcntl.flock(fh, fcntl.LOCK_UN)
            fh.close()
        if not any(QUEUE.glob("*.json")):
            return  # nothing slipped in while we were letting go of the lock


# ==========================================================================
# the actual work for one album
# ==========================================================================

def adopt_spelling(tracks, artist_root):
    """Make new files spell ARTIST / ALBUMARTIST the way the rest of the
    library already does, when the only difference is capitalisation."""
    from mutagen.flac import FLAC
    new = {str(t) for t in tracks}
    others = [p for p in Path(artist_root).rglob("*.flac") if str(p) not in new][:60]
    if not others:
        return
    changed = 0
    for tag in ("albumartist", "artist"):
        counts = Counter()
        for p in others:
            try:
                counts.update(FLAC(p).get(tag, []))
            except Exception:
                continue
        spelling = {}
        for value, _ in counts.most_common():
            spelling.setdefault(fold(value), value)
        for t in tracks:
            try:
                audio = FLAC(t)
                vals = audio.get(tag)
                if not vals:
                    continue
                fixed = [spelling.get(fold(v), v) for v in vals]
                if fixed != list(vals):
                    audio[tag] = fixed
                    audio.save()
                    changed += 1
            except Exception as e:
                log(f"  tag adopt failed for {Path(t).name}: {e}")
    if changed:
        log(f"  adopted the library's capitalisation of artist tags on {changed} tag(s)")


def do_lyrics(tracks, state_for_sweep=None):
    from lyrics_fetcher import apply_lyrics_to_file
    counts = Counter()
    for t in tracks:
        try:
            status, msg = apply_lyrics_to_file(t, overwrite=False, sleep=0.3)
        except Exception as e:
            status, msg = "error", str(e)
        counts[status] += 1
        if status in ("unsynced_plain", "not_found", "error"):
            ATTENTION.parent.mkdir(parents=True, exist_ok=True)
            with open(ATTENTION, "a") as f:
                f.write(f"{status}\t{t}\t{msg}\n")
        if status == "not_found" and state_for_sweep is not None:
            state_for_sweep[str(t)] = time.time()
    log("  lyrics: " + ", ".join(f"{k} {v}" for k, v in sorted(counts.items())))


def do_replaygain(album_files):
    import replaygain as rg
    from mutagen.flac import FLAC
    if not rg.ffmpeg_available():
        log("  replaygain: ffmpeg not on PATH, skipped")
        return
    album_gain, album_peak = rg.scan_album(album_files)
    for p in album_files:
        track_gain, track_peak = rg.scan_track(p)
        audio = FLAC(p)
        audio["replaygain_track_gain"] = [f"{track_gain:.2f} dB"]
        audio["replaygain_track_peak"] = [f"{track_peak:.6f}"]
        audio["replaygain_album_gain"] = [f"{album_gain:.2f} dB"]
        audio["replaygain_album_peak"] = [f"{album_peak:.6f}"]
        audio.save()
    log(f"  replaygain: {len(album_files)} track(s), album {album_gain:+.2f} dB")


def first_tag(path, tag):
    from mutagen.flac import FLAC
    try:
        return (FLAC(path).get(tag) or [""])[0]
    except Exception:
        return ""


def process_job(job, reconcile=True, api=None, not_found_cache=None, steps=None):
    """Everything for one album. `job` is what enqueue() stored (or what
    --sweep builds)."""
    api = api if api is not None else lidarr_or_none()
    tracks = [Path(t) for t in job["tracks"] if t.lower().endswith(".flac") and Path(t).exists()]
    label = f"{job.get('artist_name') or '?'} - {job.get('album_title') or '?'}"
    if not tracks:
        log(f"{label}: no FLAC files to work on (non-FLAC imports aren't handled)")
        return
    log(f"{label}: {len(tracks)} track(s)")

    first = tracks[0]
    album_dir = album_root(first)
    artist_dir = Path(job.get("artist_path") or album_dir.parent)
    if not artist_dir.is_dir() or artist_dir not in album_dir.parents:
        artist_dir = album_dir.parent

    # ---- 1. folder case safety net
    moved = False
    if reconcile:
        rel = [t.relative_to(artist_dir).parts for t in tracks]
        canon_artist = canonical(artist_dir)
        if canon_artist != artist_dir:
            log(f"  merging '{artist_dir.name}' into existing '{canon_artist.name}'")
            merge_dir(artist_dir, canon_artist)
            moved = True
            artist_dir = canon_artist
        # album level (case-variant album folders inside the artist folder)
        for rel_parts in {parts[:-1] for parts in rel}:
            sub = resolve_ci(artist_dir, rel_parts[:1])
            if sub and canonical(sub) != sub:
                log(f"  merging album folder '{sub.name}' into '{canonical(sub).name}'")
                merge_dir(sub, canonical(sub))
                moved = True
        tracks = [p for p in (resolve_ci(artist_dir, r) for r in rel) if p]
        if not tracks:
            log("  could not re-find the files after merging - stopping here")
            return
        album_dir = album_root(tracks[0])
        if moved and api and job.get("artist_id"):
            try:
                artist = api.get(f"/artist/{job['artist_id']}")
                if Path(artist["path"]) != artist_dir:
                    api.set_artist_path(artist, artist_dir)
                api.command("RescanArtist", artistId=int(job["artist_id"]))
                log("  told Lidarr the artist's folder and asked it to rescan")
            except Exception as e:
                log(f"  couldn't update Lidarr: {e}")

    skip = SKIP | (steps or set())

    # ---- 2. tags
    if "tags" not in skip:
        try:
            adopt_spelling(tracks, artist_dir)
        except Exception as e:
            log(f"  tag adoption failed: {e}")

    # ---- 3. lyrics
    if "lyrics" not in skip:
        try:
            do_lyrics(tracks, not_found_cache)
        except Exception as e:
            log(f"  lyrics failed: {e}")

    # ---- 4. ReplayGain, for the whole album folder, not just the new files
    if "replaygain" not in skip:
        try:
            album_files = sorted(album_dir.rglob("*.flac"))
            do_replaygain(album_files)
        except Exception as e:
            log(f"  replaygain failed: {e}")

    # ---- 5. images
    if "images" not in skip:
        try:
            import lidarr_images
            album_images = artist_images = None
            if api:
                try:
                    if job.get("album_id"):
                        album_images = api.get(f"/album/{job['album_id']}").get("images")
                    if job.get("artist_id"):
                        artist_images = api.get(f"/artist/{job['artist_id']}").get("images")
                except Exception:
                    pass
            artist_name = job.get("artist_name") or first_tag(tracks[0], "albumartist") or first_tag(tracks[0], "artist")
            album_mbid = job.get("album_mbid") or first_tag(tracks[0], "musicbrainz_releasegroupid")
            n = lidarr_images.ensure_images(
                files=sorted(album_dir.rglob("*.flac")), album_dir=album_dir, artist_dir=artist_dir,
                artist_name=artist_name, album_mbid=album_mbid,
                album_images=album_images, artist_images=artist_images,
                lidarr=(api.base, api.key) if api else None, log=log)
            log(f"  images: {n} file(s) updated")
        except Exception as e:
            log(f"  images failed: {e}")


# ==========================================================================
# --fix-case : tidy folders that were already split
# ==========================================================================

def fix_case(root, apply):
    root = Path(root)
    api = lidarr_or_none() if apply else None
    artists = api.get("/artist") if api else []
    merged_artist_paths = {}

    def groups_in(parent):
        g = defaultdict(list)
        for d in sorted(parent.iterdir()):
            if d.is_dir():
                g[fold(d.name)].append(d)
        return [v for v in g.values() if len(v) > 1]

    found = 0
    for group in groups_in(root):
        canon = pick_canonical(group)
        for other in group:
            if other == canon:
                continue
            found += 1
            print(f"ARTIST  keep '{canon.name}' ({music_count(canon)} files)  <-  '{other.name}' ({music_count(other)} files)")
            if apply:
                merge_dir(other, canon)
                merged_artist_paths[str(other)] = canon

    for artist_dir in sorted(d for d in root.iterdir() if d.is_dir()):
        for group in groups_in(artist_dir):
            canon = pick_canonical(group)
            for other in group:
                if other == canon:
                    continue
                found += 1
                print(f"ALBUM   {artist_dir.name}/ keep '{canon.name}'  <-  '{other.name}'")
                if apply:
                    merge_dir(other, canon)

    if not found:
        print("No case-split folders found.")
        return
    if not apply:
        print(f"\n{found} split folder(s). Nothing changed - re-run with --apply to merge them.")
        return
    if api and merged_artist_paths:
        for a in artists:
            new = merged_artist_paths.get(a.get("path"))
            if new:
                try:
                    api.set_artist_path(a, new)
                    api.command("RescanArtist", artistId=a["id"])
                    print(f"Lidarr: '{a['artistName']}' now points at {new.name}")
                except Exception as e:
                    print(f"Lidarr: couldn't update '{a.get('artistName')}': {e}")
    print(f"\nMerged {found} folder(s).")


# ==========================================================================
# --sweep : fill the gaps in a library that already exists
# ==========================================================================

def needs_work(path, nf_cache):
    from mutagen.flac import FLAC
    try:
        a = FLAC(path)
    except Exception:
        return set()
    need = set()
    if not a.get("lyrics") and (a.get("instrumental") or [""])[0] != "1":
        seen = nf_cache.get(str(path), 0)
        if time.time() - seen > NOT_FOUND_RETRY_DAYS * 86400:
            need.add("lyrics")
    if any(not a.get(t) for t in ("replaygain_track_gain", "replaygain_album_gain")):
        need.add("replaygain")
    types = [p.type for p in a.pictures]
    if types != [3, 8]:
        need.add("images")
    return need


def sweep(root, dry):
    root = Path(root)
    nf_cache = {}
    if NOT_FOUND.exists():
        try:
            nf_cache = json.loads(NOT_FOUND.read_text())
        except ValueError:
            pass

    albums = defaultdict(list)
    for p in sorted(root.rglob("*.flac")):
        albums[album_root(p)].append(p)

    todo = []
    totals = Counter()
    for album_dir, files in albums.items():
        needs = set()
        lacking = []
        for f in files:
            n = needs_work(f, nf_cache)
            if n:
                needs |= n
                lacking.append(f)
        if needs:
            todo.append((album_dir, files, lacking, needs))
            totals.update(needs)

    print(f"{sum(len(f) for f in albums.values())} FLAC files in {len(albums)} albums; "
          f"{len(todo)} album(s) have gaps  ({', '.join(f'{k}: {v} file-sets' for k, v in sorted(totals.items())) or 'none'})")
    if dry or not todo:
        return

    api = lidarr_or_none()
    by_path = {}
    if api:
        try:
            by_path = {a["path"]: a for a in api.get("/artist")}
        except Exception as e:
            log(f"couldn't list Lidarr artists: {e}")

    STATE.mkdir(parents=True, exist_ok=True)
    with open(LOCK, "w") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)  # wait for any import worker to finish, then hold off new ones
        for i, (album_dir, files, lacking, needs) in enumerate(todo, 1):
            artist_dir = album_dir.parent
            lid = by_path.get(str(artist_dir), {})
            job = {
                "artist_name": lid.get("artistName") or first_tag(files[0], "albumartist") or first_tag(files[0], "artist"),
                "album_title": first_tag(files[0], "album") or album_dir.name,
                "artist_id": lid.get("id", ""), "artist_path": str(artist_dir),
                "album_id": "", "album_mbid": first_tag(files[0], "musicbrainz_releasegroupid"),
                # lyrics only for files that lack them, but ReplayGain/images look at the whole album
                "tracks": [str(f) for f in (lacking if needs == {"lyrics"} else files)],
            }
            log(f"[{i}/{len(todo)}] {artist_dir.name} / {album_dir.name}  needs: {', '.join(sorted(needs))}")
            skip_steps = {"lyrics", "replaygain", "images", "tags"} - needs
            try:
                process_job(job, reconcile=False, api=api, not_found_cache=nf_cache, steps=skip_steps)
            except Exception as e:
                log(f"  FAILED: {e}")
            NOT_FOUND.write_text(json.dumps(nf_cache))
    print("Sweep finished. Anything that still needs a person is in", ATTENTION)


# ==========================================================================
# entry point
# ==========================================================================

def main():
    argv = sys.argv[1:]
    if "--worker" in argv:
        return worker()
    if "--fix-case" in argv:
        return fix_case(argv[argv.index("--fix-case") + 1], "--apply" in argv)
    if "--sweep" in argv:
        return sweep(argv[argv.index("--sweep") + 1], "--dry-run" in argv)

    event = env("lidarr_eventtype")
    if event in ("", "Test"):
        print("lidarr_hook: test OK" if event else __doc__)
        return
    try:
        if event == "ArtistAdd":
            on_artist_add()
        elif event == "AlbumDownload":
            enqueue()
    except Exception as e:
        # Never fail the import because a hook step broke.
        log(f"hook error on {event}: {e}")


if __name__ == "__main__":
    main()
