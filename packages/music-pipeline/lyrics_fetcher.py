#!/usr/bin/env python3
"""
lyrics_fetcher.py - fill in time-synced lyrics automatically before you'd
ever need to open Foobar/MusicBee/a browser and do it by hand.

Order of attempts, per track:
  1. LRCLIB (https://lrclib.net) - exact match by artist/title/album/duration,
     falling back to a fuzzy search. LRCLIB also tells us directly when a
     track is instrumental.
  2. NetEase Cloud Music - search by artist/title, pull the LRC lyric for
     the best match. NetEase marks instrumentals with the standard
     "纯音乐，请欣赏" ("instrumental, please enjoy") line instead of a flag,
     so we detect that text.
  3. If neither has a *synced* version: if either had *plain* (unsynced)
     text, that's saved as a stopgap so you only have to add timestamps
     while listening, not type the words out - and the file is reported
     as needing a manual sync pass (see lyrics_checker.py).
  4. If nothing at all was found, the file is reported as needing lyrics
     entirely.

A failure in one source (a network hiccup, or an unofficial API like
NetEase's answering with something other than the JSON shape we expect)
does not cost you the other source: each is tried independently, and only
shows up as "error" in the summary if BOTH failed AND nothing was found
either way - at which point the message says which source(s) failed and
why, rather than a bare Python exception with no context.

Writes into the vorbis-comment fields foo_openlyrics reads:
  - lyrics: the LRC text (or blank, for instrumentals)
  - instrumental: "1" for tracks with no vocals

Existing lyrics are left untouched by default (pass overwrite=True to
re-fetch anyway), except that a plain/unsynced lyrics tag will still be
upgraded automatically if a synced version turns up, since replacing an
unsynced tag with a synced one is always a strict improvement.
"""

import re
import sys
import time

import requests
from mutagen.flac import FLAC

LRCLIB_BASE = "https://lrclib.net/api"
NETEASE_BASE = "https://music.163.com/api"
REQUEST_TIMEOUT = 10
USER_AGENT = "music-pipeline/1.0 (+https://github.com/)"

INSTRUMENTAL_MARKERS = (
    "纯音乐，请欣赏",
    "纯音乐,请欣赏",
    "instrumental",  # last-resort literal check on very short "lyrics"
)

_SYNC_LINE_RE = re.compile(r"\[\d{1,2}:\d{2}(?:\.\d{1,3})?\]")


def is_synced(text):
    """True if the text contains real [mm:ss.xx] timestamp lines (not just
    metadata tags like [ar:...]/[ti:...])."""
    if not text:
        return False
    return len(_SYNC_LINE_RE.findall(text)) >= 3


def looks_instrumental(text):
    if not text:
        return False
    return any(marker in text for marker in INSTRUMENTAL_MARKERS[:2])


# --------------------------------------------------------------------------
# LRCLIB
# --------------------------------------------------------------------------

def lrclib_get(title, artist, album, duration):
    params = {"track_name": title, "artist_name": artist}
    if album:
        params["album_name"] = album
    if duration:
        params["duration"] = int(round(duration))
    try:
        r = requests.get(f"{LRCLIB_BASE}/get", params=params,
                          headers={"User-Agent": USER_AGENT}, timeout=REQUEST_TIMEOUT)
        if r.status_code == 200:
            data = r.json()
            return data if isinstance(data, dict) else None
    except (requests.RequestException, ValueError):
        pass
    return None


def lrclib_search(title, artist, duration):
    params = {"track_name": title, "artist_name": artist}
    try:
        r = requests.get(f"{LRCLIB_BASE}/search", params=params,
                          headers={"User-Agent": USER_AGENT}, timeout=REQUEST_TIMEOUT)
        if r.status_code != 200:
            return None
        results = r.json()
    except (requests.RequestException, ValueError):
        return None
    if not isinstance(results, list) or not results:
        return None
    results = [x for x in results if isinstance(x, dict)]
    if not results:
        return None
    if duration:
        results = sorted(results, key=lambda x: abs((x.get("duration") or 0) - duration))
    return results[0]


def lrclib_lookup(title, artist, album, duration):
    result = lrclib_get(title, artist, album, duration)
    if result:
        return result
    return lrclib_search(title, artist, duration)


# --------------------------------------------------------------------------
# NetEase
# --------------------------------------------------------------------------

def _netease_headers():
    return {"User-Agent": USER_AGENT, "Referer": "https://music.163.com/"}


def netease_search(title, artist):
    query = f"{title} {artist}".strip()
    try:
        r = requests.get(
            f"{NETEASE_BASE}/search/get/web",
            params={"s": query, "type": 1, "offset": 0, "limit": 5},
            headers=_netease_headers(), timeout=REQUEST_TIMEOUT,
        )
        data = r.json()
    except (requests.RequestException, ValueError):
        return None

    # NetEase's unofficial endpoints sometimes answer a blocked/rate-limited
    # request with a bare JSON string (e.g. "-460") instead of the usual
    # {"result": {...}} object. That's still valid JSON, so r.json()
    # doesn't raise - but calling .get() on the result then blows up with
    # "'str' object has no attribute 'get'". Treat anything that isn't the
    # shape we expect as "no results" instead of crashing the file.
    if not isinstance(data, dict):
        return None
    result = data.get("result")
    if not isinstance(result, dict):
        return None
    songs = result.get("songs", [])
    if not isinstance(songs, list):
        return None
    songs = [s for s in songs if isinstance(s, dict)]
    if not songs:
        return None

    def score(song):
        artists = song.get("artists", [])
        if not isinstance(artists, list):
            artists = []
        song_artists = " ".join(
            a.get("name", "") for a in artists if isinstance(a, dict)
        ).casefold()
        s = 0
        if artist.casefold() in song_artists or song_artists in artist.casefold():
            s += 2
        if title.casefold() in song.get("name", "").casefold():
            s += 1
        return -s

    songs.sort(key=score)
    return songs[0].get("id")


def netease_lyric(song_id):
    try:
        r = requests.get(
            f"{NETEASE_BASE}/song/lyric",
            params={"id": song_id, "lv": 1, "kv": 1, "tv": -1},
            headers=_netease_headers(), timeout=REQUEST_TIMEOUT,
        )
        data = r.json()
    except (requests.RequestException, ValueError):
        return None
    return data if isinstance(data, dict) else None


def netease_lookup(title, artist):
    song_id = netease_search(title, artist)
    if not song_id:
        return None
    data = netease_lyric(song_id)
    if not data:
        return None
    if data.get("nolyric"):
        return {"instrumental": True, "syncedLyrics": None, "plainLyrics": None}
    lrc = (data.get("lrc") or {}).get("lyric") if isinstance(data.get("lrc"), dict) else None
    if lrc and looks_instrumental(lrc):
        return {"instrumental": True, "syncedLyrics": None, "plainLyrics": None}
    if lrc and is_synced(lrc):
        return {"instrumental": False, "syncedLyrics": lrc, "plainLyrics": None}
    return {"instrumental": False, "syncedLyrics": None, "plainLyrics": lrc}


# --------------------------------------------------------------------------
# per-file logic
# --------------------------------------------------------------------------

def apply_lyrics_to_file(path, overwrite=False, sleep=0.0):
    """Try to fill in synced lyrics (or instrumental) for one FLAC file.

    Returns one of:
      "already_synced"  - left alone, already had timestamped lyrics
      "instrumental"     - marked instrumental=1, lyrics cleared
      "synced"           - wrote synced lyrics (source noted in message)
      "unsynced_plain"   - wrote plain-text lyrics as a stopgap; still
                            needs a manual timing pass
      "not_found"        - nothing usable found anywhere
      "error"            - missing artist/title tags, can't look up
    plus a short human-readable message.
    """
    audio = FLAC(path)

    if not overwrite:
        if audio.get("instrumental", [""])[0] == "1":
            return "already_synced", "already marked instrumental"
        existing = audio.get("lyrics", [""])[0]
        if is_synced(existing):
            return "already_synced", "already has synced lyrics"

    title = (audio.get("title") or [None])[0]
    artist = (audio.get("artist") or [None])[0]
    album = (audio.get("album") or [None])[0]
    if not title or not artist:
        return "error", "missing artist/title tag, can't search"

    duration = None
    try:
        duration = audio.info.length
    except Exception:
        pass

    plain_fallback = None
    source_errors = []

    # 1. LRCLIB
    try:
        result = lrclib_lookup(title, artist, album, duration)
    except Exception as e:
        result = None
        source_errors.append(f"LRCLIB: {e}")
    if result:
        if result.get("instrumental"):
            _write_instrumental(audio)
            return "instrumental", "LRCLIB marked instrumental"
        if result.get("syncedLyrics"):
            _write_lyrics(audio, result["syncedLyrics"])
            return "synced", "LRCLIB"
        if result.get("plainLyrics") and not plain_fallback:
            plain_fallback = ("LRCLIB", result["plainLyrics"])

    if sleep:
        time.sleep(sleep)

    # 2. NetEase - a failure here (or above) is reported as part of the
    # eventual "not_found" reason rather than aborting the file outright,
    # so a single flaky API doesn't cost you a source you didn't even need
    # (LRCLIB may already have answered) or silently skip a file with no
    # lyrics written and no clear explanation why.
    try:
        ne = netease_lookup(title, artist)
    except Exception as e:
        ne = None
        source_errors.append(f"NetEase: {e}")
    if ne:
        if ne.get("instrumental"):
            _write_instrumental(audio)
            return "instrumental", "NetEase marked instrumental"
        if ne.get("syncedLyrics"):
            _write_lyrics(audio, ne["syncedLyrics"])
            return "synced", "NetEase"
        if ne.get("plainLyrics") and not plain_fallback:
            plain_fallback = ("NetEase", ne["plainLyrics"])

    # 3. plain-text stopgap, so at least you're timing existing words
    existing = audio.get("lyrics", [""])[0]
    if plain_fallback and not is_synced(existing):
        source, text = plain_fallback
        _write_lyrics(audio, text)
        return "unsynced_plain", f"only unsynced lyrics found ({source}) - needs manual timing"

    if source_errors:
        return "error", "; ".join(source_errors)
    return "not_found", "no lyrics found anywhere"


def _write_lyrics(audio, text):
    text = text.replace("\r\n", "\n").strip("\n")
    audio["lyrics"] = [text]
    if "instrumental" in audio:
        del audio["instrumental"]
    audio.save()


def _write_instrumental(audio):
    audio["lyrics"] = [""]
    audio["instrumental"] = ["1"]
    audio.save()


# --------------------------------------------------------------------------
# folder-level driver
# --------------------------------------------------------------------------

def process_folder(folder, overwrite=False, sleep=0.3):
    from pathlib import Path
    flacs = sorted(Path(folder).rglob("*.flac"))
    stats = {"already_synced": 0, "instrumental": 0, "synced": 0,
              "unsynced_plain": 0, "not_found": 0, "error": 0}
    needs_attention = []  # (path, status, message)

    for i, p in enumerate(flacs, 1):
        # Show more detailed progress 
        percent = (i / len(flacs)) * 100 if len(flacs) > 0 else 0
        print(f"[{i}/{len(flacs)}] ({percent:.1f}%) {p.name} ... ", end="", flush=True)
        try:
            status, msg = apply_lyrics_to_file(p, overwrite=overwrite, sleep=sleep)
        except Exception as e:
            status, msg = "error", str(e)
        stats[status] = stats.get(status, 0) + 1
        print(f"{status} ({msg})")
        if status in ("unsynced_plain", "not_found", "error"):
            needs_attention.append((p, status, msg))

    print("\nLyrics fetch summary:")
    for k, v in stats.items():
        print(f"  {k}: {v}")
    return needs_attention


if __name__ == "__main__":
    folder = sys.argv[1] if len(sys.argv) > 1 else "."
    process_folder(folder, overwrite="--overwrite" in sys.argv)
