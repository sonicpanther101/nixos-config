#!/usr/bin/env python3
"""
replaygain.py - ReplayGain 2.0 scanning that matches foobar2000's default
"Calculate ReplayGain (as album)" / "Scan as albums (by tags)" behaviour,
without needing foobar or any other external GUI app.

How foobar's "as albums (by tags)" scan works, and what this replicates:
  - Files are grouped into "albums" by their ALBUM (+ ALBUMARTIST) tags,
    *not* by which folder they happen to sit in.
  - Each track gets its own track gain/peak (measured independently).
  - Each group also gets one album gain/peak: the whole album's audio is
    analysed together as a single continuous stream, so quiet and loud
    tracks on the same release stay at the right volume relative to each
    other when the player applies album gain.

Algorithm (ReplayGain 2.0 / EBU R128, same spec foobar2000 has used by
default since 1.4):
  - Integrated loudness target: -18 LUFS.
  - track_gain = -18 - measured_integrated_loudness(track)
  - album_gain = -18 - measured_integrated_loudness(all tracks concatenated)
  - track_peak / album_peak are true-peak sample values (0-1+ linear).

Requires ffmpeg on PATH (uses ffmpeg's built-in `ebur128` filter - no
extra Python audio-analysis dependencies needed).
"""

import re
import shutil
import subprocess
from collections import defaultdict
from pathlib import Path

from mutagen.flac import FLAC

TARGET_LUFS = -18.0

# ffmpeg's ebur128 summary block looks like:
#   Summary:
#     Integrated loudness:
#       I:         -14.3 LUFS
#       ...
#     True peak:
#       Peak:       -1.2 dBFS
_SUMMARY_RE = re.compile(r"Summary:.*", re.DOTALL)
_I_RE = re.compile(r"I:\s*(-?\d+(?:\.\d+)?)\s*LUFS")
_PEAK_RE = re.compile(r"Peak:\s*(-?\d+(?:\.\d+)?)\s*dB\w*")


def ffmpeg_available():
    return shutil.which("ffmpeg") is not None


def _run_ebur128(filter_complex, map_label, inputs):
    """Run ffmpeg with the given filter graph, return (I_lufs, peak_db)."""
    cmd = ["ffmpeg", "-hide_banner", "-nostats"]
    for f in inputs:
        cmd += ["-i", str(f)]
    cmd += ["-filter_complex", filter_complex, "-map", map_label, "-f", "null", "-"]
    proc = subprocess.run(cmd, capture_output=True, text=True)
    out = proc.stderr
    m = _SUMMARY_RE.search(out)
    block = m.group(0) if m else out
    i_match = _I_RE.search(block)
    peak_match = _PEAK_RE.search(block)
    if not i_match or not peak_match:
        raise RuntimeError(
            f"Could not parse ebur128 output for: {' '.join(str(x) for x in inputs)}\n"
            f"--- ffmpeg stderr tail ---\n{out[-2000:]}"
        )
    return float(i_match.group(1)), float(peak_match.group(1))


def scan_track(path):
    """Return (track_gain_db, track_peak_linear) for one file."""
    filt = "[0:a]ebur128=peak=true[out]"
    i_lufs, peak_db = _run_ebur128(filt, "[out]", [path])
    gain = TARGET_LUFS - i_lufs
    peak = 10 ** (peak_db / 20)
    return gain, peak


def scan_album(paths):
    """Return (album_gain_db, album_peak_linear) for a group of files,
    analysed as one continuous stream the way foobar's album scan does."""
    if len(paths) == 1:
        gain, peak = scan_track(paths[0])
        return gain, peak

    parts = []
    labels = []
    for idx in range(len(paths)):
        parts.append(f"[{idx}:a]aformat=sample_rates=48000:channel_layouts=stereo[a{idx}]")
        labels.append(f"[a{idx}]")
    concat = f"{''.join(labels)}concat=n={len(paths)}:v=0:a=1[cat]"
    ebur = "[cat]ebur128=peak=true[out]"
    filt = ";".join(parts + [concat, ebur])
    i_lufs, peak_db = _run_ebur128(filt, "[out]", paths)
    gain = TARGET_LUFS - i_lufs
    peak = 10 ** (peak_db / 20)
    return gain, peak


def _album_key(audio):
    albumartist = ""
    for tag in ("albumartist", "album artist", "artist"):
        if tag in audio and audio[tag]:
            albumartist = audio[tag][0]
            break
    album = audio["album"][0] if "album" in audio and audio["album"] else ""
    return (albumartist.strip().casefold(), album.strip().casefold())


def group_by_album_tags(folder):
    """Group every FLAC under `folder` by (albumartist, album) tags -
    foobar's 'by tags' grouping, ignoring actual folder structure."""
    groups = defaultdict(list)
    for p in sorted(Path(folder).rglob("*.flac")):
        try:
            audio = FLAC(p)
        except Exception as e:
            print(f"  [skip - couldn't read {p.name}: {e}]")
            continue
        if "album" not in audio or not audio["album"]:
            print(f"  [skip - no ALBUM tag: {p.name}]")
            continue
        groups[_album_key(audio)].append(p)
    return groups


def apply_replaygain(folder, force=False):
    """Scan and tag every FLAC under `folder`, grouped into albums by tag.

    force=False (default) skips files that already have all four
    replaygain tags, so re-running the pipeline doesn't re-scan your
    whole library every time - only new/changed files.
    """
    if not ffmpeg_available():
        print("ffmpeg not found on PATH - skipping ReplayGain scan. Install "
              "ffmpeg and re-run.")
        return

    groups = group_by_album_tags(folder)
    if not groups:
        print("No FLAC files with ALBUM tags found - nothing to scan.")
        return

    tags = ("replaygain_track_gain", "replaygain_track_peak",
             "replaygain_album_gain", "replaygain_album_peak")

    def needs_scan(p):
        try:
            audio = FLAC(p)
        except Exception:
            return True
        return force or any(t not in audio or not audio[t] for t in tags)

    scanned_albums = 0
    scanned_tracks = 0
    for (albumartist, album), paths in groups.items():
        if not force and not any(needs_scan(p) for p in paths):
            continue
        label = album or "(no album)"
        print(f"\nScanning album: {albumartist or '(no albumartist)'} - {label} "
              f"({len(paths)} track(s))")
        try:
            album_gain, album_peak = scan_album(paths)
        except Exception as e:
            print(f"  [album scan failed: {e}]")
            continue
        scanned_albums += 1

        for p in paths:
            try:
                track_gain, track_peak = scan_track(p)
            except Exception as e:
                print(f"  [track scan failed for {p.name}: {e}]")
                continue
            audio = FLAC(p)
            audio["replaygain_track_gain"] = [f"{track_gain:.2f} dB"]
            audio["replaygain_track_peak"] = [f"{track_peak:.6f}"]
            audio["replaygain_album_gain"] = [f"{album_gain:.2f} dB"]
            audio["replaygain_album_peak"] = [f"{album_peak:.6f}"]
            audio.save()
            scanned_tracks += 1
            print(f"  {p.name}: track {track_gain:+.2f} dB, album {album_gain:+.2f} dB")

    print(f"\nReplayGain done: {scanned_tracks} track(s) across {scanned_albums} album(s) scanned.")


if __name__ == "__main__":
    import sys
    folder = sys.argv[1] if len(sys.argv) > 1 else "."
    apply_replaygain(folder, force="--force" in sys.argv)
