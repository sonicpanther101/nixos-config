#!/usr/bin/env python3
"""
soularr_gate.py - run Soularr, but check every finished download before Lidarr gets it.

Soularr downloads an album from a Soulseek user and then tells Lidarr to import it.
This wraps its `process_completed_album` step (no patching of Soularr's source): the
downloaded FLACs go through flac_check.py first. If they are transcoded lossy audio:

  * the downloaded folder is deleted, so nothing fake ever enters the library
  * the uploader goes on a permanent skip list (<state dir>/fake_users.json; delete the
    entry by hand if you think it was a false alarm)
  * the album is reported to Soularr as failed, so it stays wanted and the next run
    picks a different uploader

Everything else (arguments, config.ini, scheduling) is Soularr's own.
Set SOULARR_GATE_ACTION=report to only log instead of deleting.
"""

import json
import os
import shutil
import sys
from pathlib import Path

import soularr

import flac_check

_process_completed_album = soularr.process_completed_album
_is_skipped_user = soularr.is_skipped_user


def _fake_users_file():
    return Path(soularr.failed_users_file_path).with_name("fake_users.json")


def _load_fake_users():
    try:
        return json.loads(_fake_users_file().read_text())
    except (OSError, ValueError):
        return {}


def _remember_fake_user(username, album, reason):
    users = _load_fake_users()
    entry = users.setdefault(username, {"count": 0})
    entry["count"] += 1
    entry["last_album"], entry["last_reason"] = album, reason
    _fake_users_file().write_text(json.dumps(users, indent=2))


def is_skipped_user(username):
    return username in _load_fake_users() or _is_skipped_user(username)


def process_completed_album(album_data, failed_grab):
    label = f"{album_data['artist']} - {album_data['title']}"
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
        if verdict == "fake":
            reason = next(r["reason"] for _, r in results if r["verdict"] == "fake")
            soularr.logger.warning(f"FAKE FLAC from {sorted(set(owner.values()))} for {label}: {reason}")
            if os.environ.get("SOULARR_GATE_ACTION", "reject") == "reject":
                for path, r in results:
                    if r["verdict"] == "fake":
                        _remember_fake_user(owner[str(path)], label, r["reason"])
                for f in album_data["files"]:
                    folder = os.path.join(soularr.slskd_download_dir, f["file_dir"].split("\\")[-1])
                    shutil.rmtree(folder, ignore_errors=True)
                failed_grab.append(soularr.lidarr.get_album(album_data["album_id"]))
                return
    _process_completed_album(album_data, failed_grab)


def main():
    soularr.process_completed_album = process_completed_album
    soularr.is_skipped_user = is_skipped_user
    soularr.main()


if __name__ == "__main__":
    main()
