#!/usr/bin/env python3
"""
lidarr_images.py - the non-interactive version of image_fixer.py, for the
Lidarr hook.

image_fixer.py asks you to pick images from Last.fm in a matplotlib window,
which is no use when Lidarr fires the hook at 3am. This module applies the
same end result and the same quality bar with no prompts:

  * every FLAC ends up with exactly [front cover (type 3), artist image (type 8)]
  * cover >= 600x600 and <= 2 MB, JPEG or PNG
  * the artist image is identical across every track by that artist

Sources, in order:

  album cover   1. what's already embedded / sitting in the album folder, if it
                   passes the quality bar
                2. Cover Art Archive (by the MusicBrainz release-group id Lidarr
                   gives the hook) - full size, no key needed
                3. the cover image Lidarr itself holds for the album

  artist image  1. the type-8 picture other tracks by this artist already have,
                   so new albums match the rest of your library
                2. Deezer's artist picture, but only on an exact (case-
                   insensitive) name match - a wrong artist is worse than none
                3. the poster/fanart image Lidarr holds for the artist

Needs: mutagen, Pillow, requests.
"""

import re
import time
from io import BytesIO
from pathlib import Path

import requests
from mutagen.flac import FLAC, Picture
from PIL import Image

MIN_RESOLUTION = 600
MAX_SIZE_BYTES = 2 * 1024 * 1024
TIMEOUT = 20
HEADERS = {"User-Agent": "music-pipeline/1.0 (lidarr hook)"}

COVER_NAMES = ("cover", "folder", "front", "album")
COVER_EXTS = (".jpg", ".jpeg", ".png")


# --------------------------------------------------------------------------
# image helpers
# --------------------------------------------------------------------------

def _mime(data):
    try:
        return "image/png" if (Image.open(BytesIO(data)).format or "").upper() == "PNG" else "image/jpeg"
    except Exception:
        return "image/jpeg"


def normalise(data):
    """Return JPEG/PNG bytes (WEBP/GIF/BMP/etc get converted), or None if it
    isn't a decodable image."""
    try:
        img = Image.open(BytesIO(data))
        fmt = (img.format or "").upper()
        img.load()
    except Exception:
        return None
    if fmt in ("JPEG", "PNG"):
        return data
    has_alpha = img.mode in ("RGBA", "LA", "PA") or (img.mode == "P" and "transparency" in img.info)
    buf = BytesIO()
    if has_alpha:
        img.convert("RGBA").save(buf, format="PNG", optimize=True)
    else:
        img.convert("RGB").save(buf, format="JPEG", quality=95)
    return buf.getvalue()


def size_of(data):
    try:
        return Image.open(BytesIO(data)).size
    except Exception:
        return (0, 0)


def meets_bar(data):
    w, h = size_of(data)
    return w >= MIN_RESOLUTION and h >= MIN_RESOLUTION and len(data) <= MAX_SIZE_BYTES


def shrink(data, limit=MAX_SIZE_BYTES):
    """Re-encode as JPEG until it fits under `limit`, keeping >= 600px if at
    all possible. Returns bytes, or None if it can't be done."""
    try:
        img = Image.open(BytesIO(data)).convert("RGB")
    except Exception:
        return None
    for max_side in (None, 1800, 1400, 1200, 1000, 800, 600):
        work = img
        if max_side and max(img.size) > max_side:
            scale = max_side / max(img.size)
            work = img.resize((round(img.width * scale), round(img.height * scale)), Image.LANCZOS)
        for quality in (92, 85, 78, 70):
            buf = BytesIO()
            work.save(buf, format="JPEG", quality=quality, optimize=True)
            if buf.tell() <= limit:
                return buf.getvalue()
    return None


def fit(data):
    """normalise + shrink if oversized. Returns bytes or None."""
    data = normalise(data)
    if data is None:
        return None
    if len(data) > MAX_SIZE_BYTES:
        data = shrink(data)
    return data


def download(url):
    if not url:
        return None
    try:
        r = requests.get(url, headers=HEADERS, timeout=TIMEOUT, allow_redirects=True)
        if r.status_code == 200 and r.content:
            return fit(r.content)
    except requests.RequestException:
        pass
    return None


# --------------------------------------------------------------------------
# existing images
# --------------------------------------------------------------------------

def embedded(paths, pic_type):
    """Best (largest) embedded picture of this type across the files."""
    best, best_px = None, -1
    for p in paths:
        try:
            for pic in FLAC(p).pictures:
                if pic.type == pic_type and pic.width * pic.height > best_px:
                    best, best_px = pic.data, pic.width * pic.height
        except Exception:
            continue
    return normalise(best) if best else None


def folder_cover(album_dir):
    for f in sorted(Path(album_dir).iterdir()):
        if f.is_file() and f.suffix.lower() in COVER_EXTS and f.stem.lower() in COVER_NAMES:
            try:
                return normalise(f.read_bytes())
            except OSError:
                pass
    return None


def library_artist_image(artist_dir, exclude=()):
    """The artist picture other tracks by this artist already carry."""
    exclude = {str(Path(p)) for p in exclude}
    for p in sorted(Path(artist_dir).rglob("*.flac")):
        if str(p) in exclude:
            continue
        found = embedded([p], 8)
        if found:
            return found
    return None


# --------------------------------------------------------------------------
# remote sources
# --------------------------------------------------------------------------

def coverartarchive(release_group_mbid):
    if not release_group_mbid:
        return None
    return download(f"https://coverartarchive.org/release-group/{release_group_mbid}/front")


def deezer_artist(name):
    if not name:
        return None
    try:
        r = requests.get("https://api.deezer.com/search/artist", params={"q": name, "limit": 5},
                         headers=HEADERS, timeout=TIMEOUT)
        for hit in (r.json() or {}).get("data", []) if r.status_code == 200 else []:
            if (hit.get("name") or "").casefold() == name.casefold():
                img = download(hit.get("picture_xl") or hit.get("picture_big"))
                # Deezer's "no photo" placeholder is a small flat image
                if img and meets_bar(img):
                    return img
    except (requests.RequestException, ValueError):
        pass
    return None


def lidarr_image(images, base_url, api_key, cover_types):
    """Download the first image Lidarr holds of one of `cover_types`."""
    for want in cover_types:
        for im in images or []:
            if (im.get("coverType") or "").lower() != want:
                continue
            for url in (im.get("remoteUrl"), im.get("url")):
                if not url:
                    continue
                if url.startswith("/"):
                    url = base_url.rstrip("/") + url + ("&" if "?" in url else "?") + f"apikey={api_key}"
                data = download(url)
                if data:
                    return data
    return None


# --------------------------------------------------------------------------
# writing
# --------------------------------------------------------------------------

def _picture(data, pic_type):
    pic = Picture()
    pic.type = pic_type
    pic.mime = _mime(data)
    pic.data = data
    try:
        pic.width, pic.height = size_of(data)
        pic.depth = 24
    except Exception:
        pass
    return pic


def pair_matches(path, front, artist):
    try:
        pics = FLAC(path).pictures
    except Exception:
        return False
    want = [(3, front)] * bool(front) + [(8, artist)] * bool(artist)
    return len(pics) == len(want) and all(p.type == t and p.data == d for p, (t, d) in zip(pics, want))


def write_pair(path, front, artist):
    """Overwrite a file's pictures with exactly [front(3), artist(8)], the
    same convention image_fixer.py uses. Returns True if the file changed."""
    if pair_matches(path, front, artist):
        return False
    audio = FLAC(path)
    audio.clear_pictures()
    if front:
        audio.add_picture(_picture(front, 3))
    if artist:
        audio.add_picture(_picture(artist, 8))
    audio.save()
    return True


def _write_file_once(directory, name, data):
    """Drop folder.jpg/png beside the music for Jellyfin, never overwrite."""
    ext = ".png" if _mime(data) == "image/png" else ".jpg"
    for existing in (".jpg", ".jpeg", ".png"):
        if (Path(directory) / f"{name}{existing}").exists():
            return
    try:
        (Path(directory) / f"{name}{ext}").write_bytes(data)
    except OSError:
        pass


# --------------------------------------------------------------------------
# entry point used by the hook
# --------------------------------------------------------------------------

def ensure_images(files, album_dir, artist_dir, artist_name, album_mbid=None,
                  album_images=None, artist_images=None, lidarr=None, log=print):
    """Make sure every file in `files` (one album) carries front + artist
    pictures. `lidarr` is (base_url, api_key) or None. Returns the number of
    files rewritten."""
    base_url, api_key = lidarr or ("", "")

    # --- front cover
    front = embedded(files, 3)
    if front and not meets_bar(front):
        w, h = size_of(front)
        if w >= MIN_RESOLUTION and h >= MIN_RESOLUTION and len(front) > MAX_SIZE_BYTES:
            front = shrink(front) or front
    if not (front and meets_bar(front)):
        candidates = [front, folder_cover(album_dir)]
        candidates = [c for c in candidates if c]
        remote = (coverartarchive(album_mbid)
                  or lidarr_image(album_images, base_url, api_key, ("cover",)))
        if remote:
            candidates.append(remote)
        good = [c for c in candidates if meets_bar(c)]
        # prefer something that meets the bar; otherwise the biggest we have,
        # which is still better than no cover at all
        front = (good[0] if good else
                 max(candidates, key=lambda c: size_of(c)[0] * size_of(c)[1], default=None))
        if front is None:
            log("  no cover found anywhere")
        elif not meets_bar(front):
            log(f"  cover is only {size_of(front)[0]}x{size_of(front)[1]} - using it anyway")

    # --- artist image
    artist = library_artist_image(artist_dir, exclude=files)
    if artist is None:
        artist = embedded(files, 8)
    if artist is None:
        artist = deezer_artist(artist_name)
    if artist is None:
        artist = lidarr_image(artist_images, base_url, api_key, ("poster", "fanart"))
    if artist is None:
        log("  no artist image found")

    changed = 0
    for p in files:
        try:
            if write_pair(p, front, artist):
                changed += 1
        except Exception as e:
            log(f"  could not write pictures to {Path(p).name}: {e}")

    if front:
        _write_file_once(album_dir, "folder", front)
    if artist:
        _write_file_once(artist_dir, "folder", artist)
    return changed
