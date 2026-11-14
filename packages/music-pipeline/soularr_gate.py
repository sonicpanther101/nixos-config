#!/usr/bin/env python3
"""
soularr_gate.py - run Soularr with a quality gate, MP3 fallback and gentle bans.

Soularr downloads an album from a Soulseek user and then tells Lidarr to import it.
This wraps three of its steps (no patching of Soularr's source), everything else
(arguments, config.ini, scheduling) is Soularr's own:

1. Every finished FLAC download is checked by flac_check.py before Lidarr sees it.
   If it is transcoded lossy audio the folder is deleted and the album stays wanted.
   Uploaders are then skipped for a while, not forever:
     * clearly fake (cliff below 19 kHz, or 50+ dB deep): skipped for 3 days, then
       14, then 60 for repeat offenders
     * borderline (cliff 19.0-19.5 kHz): skipped for 1 day only, and if a second
       uploader's copy shows the same borderline cliff the album itself is band-limited,
       so that copy is accepted and the first uploader is let off
   Two uploaders caught with clearly fake FLACs for one album: FLAC is given up on for
   that album for a week and the MP3 fallback is used instead.

2. Which file types are tried depends on the album (allowed_filetypes order = preference):
     * nothing in the library yet:  everything in the list, so FLAC first, MP3 as fallback
     * files already in the library (Lidarr wants a better quality): FLAC only. Without
       this a later run would download the same MP3 again and Lidarr would refuse it.
   Lidarr's quality profile (cutoff FLAC, upgrades allowed) does the actual upgrade.

3. A failed Lidarr import no longer blocks an album for good: it is retried after a week.

State (next to Soularr's own files, in the --var-dir):
    fake_users.json   who was caught, how often, and until when they are skipped
    fake_albums.json  recent rejected downloads per album (forgotten after a week)
Set SOULARR_GATE_ACTION=report to only log what would have been rejected.
"""

import json
import os
import shutil
import statistics
import sys
from datetime import datetime, timedelta
from pathlib import Path

import soularr

import flac_check

STRONG_BAN_DAYS = (3, 14, 60)   # 1st, 2nd, 3rd+ time an uploader is caught with a clearly fake FLAC
WEAK_BAN_DAYS = 1               # borderline cutoff: a day, and no escalation
SAME_CUTOFF_KHZ = 0.5           # two borderline cutoffs this close = the same source
HISTORY_DAYS = 7                # how long an album remembers rejected downloads
FLAC_GIVE_UP = 2                # this many uploaders with clearly fake FLACs -> MP3 fallback
DENYLIST_DAYS = 7               # a failed Lidarr import is retried after this long

_find_download = soularr.find_download
_process_completed_album = soularr.process_completed_album
_is_skipped_user = soularr.is_skipped_user
_load_failed_import_denylist = soularr.load_failed_import_denylist
_configured_filetypes = None


# ---- small state files -------------------------------------------------------------

def _now():
    return datetime.now()


def _stamp(dt):
    return dt.isoformat(timespec="seconds")


def _parse(text):
    try:
        return datetime.fromisoformat(text)
    except (TypeError, ValueError):
        return None


def _file(name):
    return Path(soularr.failed_users_file_path).with_name(name)


def _read(name):
    try:
        return json.loads(_file(name).read_text())
    except (OSError, ValueError):
        return {}


def _write(name, data):
    _file(name).write_text(json.dumps(data, indent=2))


def _history(album_id):
    """Recent rejected downloads for this album (older ones are forgotten)."""
    cutoff = _now() - timedelta(days=HISTORY_DAYS)
    return [h for h in _read("fake_albums.json").get(str(album_id), [])
            if (_parse(h.get("at")) or cutoff) > cutoff]


def _set_history(album_id, entries):
    data = _read("fake_albums.json")
    if entries:
        data[str(album_id)] = entries
    else:
        data.pop(str(album_id), None)
    _write("fake_albums.json", data)


def _ban(username, label, reason, strength):
    users = _read("fake_users.json")
    entry = users.setdefault(username, {"strikes": 0})
    if strength == "strong":
        entry["strikes"] = entry.get("strikes", 0) + 1
        days = STRONG_BAN_DAYS[min(entry["strikes"], len(STRONG_BAN_DAYS)) - 1]
    else:
        days = WEAK_BAN_DAYS
    entry["until"] = _stamp(_now() + timedelta(days=days))
    entry.update(last_album=label, last_reason=reason, last_strength=strength)
    _write("fake_users.json", users)
    return days


def _unban(usernames):
    users = _read("fake_users.json")
    for name in usernames:
        if name in users:
            users[name]["until"] = _stamp(_now())
    _write("fake_users.json", users)


# ---- 1. users ----------------------------------------------------------------------

def is_skipped_user(username):
    """Entries from the old permanent-ban version have no "until" and are ignored."""
    until = _parse(_read("fake_users.json").get(username, {}).get("until"))
    return bool(until and until > _now()) or _is_skipped_user(username)


# ---- 2. which file types to try for an album ---------------------------------------

def _is_flac(filetype):
    return filetype.split(" ")[0].lower() == "flac"


def _has_files(album):
    stats = album.get("statistics")
    if stats is None:
        try:
            stats = soularr.lidarr.get_album(album["id"]).get("statistics")
        except Exception:
            stats = None
    # can't tell: assume it has files, which only ever means "FLAC only", the safe side
    return True if stats is None else stats.get("trackFileCount", 0) > 0


def find_download(album, grab_list):
    global _configured_filetypes
    if _configured_filetypes is None:
        _configured_filetypes = list(soularr.allowed_filetypes)
    label = f"{album['artist']['artistName']} - {album['title']}"
    types = list(_configured_filetypes)
    if _has_files(album):
        types = [t for t in types if _is_flac(t)]
    strong_users = {h["user"] for h in _history(album["id"]) if h.get("strength") == "strong"}
    if len(strong_users) >= FLAC_GIVE_UP:
        types = [t for t in types if not _is_flac(t)]
        soularr.logger.info(f"{label}: {len(strong_users)} uploaders had fake FLACs, "
                            f"trying {', '.join(types) or 'nothing'} instead")
    if not types:
        return False
    soularr.allowed_filetypes = types
    try:
        return _find_download(album, grab_list)
    finally:
        soularr.allowed_filetypes = _configured_filetypes


# ---- 3. denylist of failed imports -------------------------------------------------

def load_failed_import_denylist(file_path):
    cutoff = _now() - timedelta(days=DENYLIST_DAYS)
    return {k: v for k, v in _load_failed_import_denylist(file_path).items()
            if (_parse(v.get("failed_at")) or _now()) > cutoff}


# ---- the check itself --------------------------------------------------------------

def process_completed_album(album_data, failed_grab):
    label = f"{album_data['artist']} - {album_data['title']}"
    album_id = album_data["album_id"]
    owner = {}   # downloaded file -> uploader
    for f in album_data["files"]:
        if f["filename"].lower().endswith(".flac"):
            path = soularr.downloaded_file_path(f)
            if os.path.exists(path):
                owner[path] = f["username"]
    if owner:
        try:
            verdict, results = flac_check.check_album(list(owner))
        except Exception:
            soularr.logger.exception("fake-lossless check crashed; importing without it")
            verdict, results = "unknown", []
        if verdict == "ok":
            _set_history(album_id, [])
        elif verdict == "fake":
            fakes = [(p, r) for p, r in results if r["verdict"] == "fake"]
            strength = "strong" if any(r["strength"] == "strong" for _, r in fakes) else "weak"
            cutoff = statistics.median(r["cutoff_hz"] for _, r in fakes) / 1000
            users = sorted({owner[str(p)] for p, _ in fakes})
            reason = fakes[0][1]["reason"]
            soularr.logger.warning(f"FAKE FLAC from {users} for {label}: {reason}")
            earlier = _history(album_id)
            agree = [h for h in earlier if strength == "weak" and h.get("strength") == "weak"
                     and h["user"] not in users and abs(h["cutoff_khz"] - cutoff) <= SAME_CUTOFF_KHZ]
            if os.environ.get("SOULARR_GATE_ACTION", "reject") != "reject":
                soularr.logger.info("SOULARR_GATE_ACTION is not 'reject': importing anyway")
            elif agree:
                soularr.logger.info(f"{label}: a second uploader shows the same borderline cutoff, so the "
                                    f"album itself is band-limited. Importing this copy.")
                _unban({h["user"] for h in earlier})
                _set_history(album_id, [])
            else:
                for u in users:
                    days = _ban(u, label, reason, strength)
                    soularr.logger.info(f"Skipping {u} for {days} day(s)")
                _set_history(album_id, earlier + [
                    {"user": u, "cutoff_khz": round(cutoff, 2), "strength": strength, "at": _stamp(_now())}
                    for u in users])
                for f in album_data["files"]:
                    folder = os.path.join(soularr.slskd_download_dir, f["file_dir"].split("\\")[-1])
                    shutil.rmtree(folder, ignore_errors=True)
                failed_grab.append(soularr.lidarr.get_album(album_id))
                return
    _process_completed_album(album_data, failed_grab)


def main():
    soularr.find_download = find_download
    soularr.process_completed_album = process_completed_album
    soularr.is_skipped_user = is_skipped_user
    soularr.load_failed_import_denylist = load_failed_import_denylist
    soularr.main()


if __name__ == "__main__":
    main()
