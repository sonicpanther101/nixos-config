#!/usr/bin/env python3
"""
flac_check.py - spot FLAC files that are really transcodes of lossy audio.

Lossy encoders (MP3, AAC, Vorbis, Opus) throw away everything above a cutoff that
depends on the bitrate (128k ~ 16 kHz, 192k ~ 18.5-19 kHz, 256k ~ 19-20 kHz). Decoding
that back into a FLAC leaves a hard cliff in the spectrum which a real lossless master
almost never has. This decodes a slice of the track, averages its spectrum and looks
for that cliff.

What it can and cannot do (be honest about it when you read the log):
  * catches: 128-256 kbps MP3/AAC and low-bitrate Opus/Vorbis dressed up as FLAC
  * misses: 320 kbps / V0 MP3 (cutoff ~20 kHz, same as plenty of real masters), and
            "FLAC" made by upsampling a CD rip, which is still genuine lossless audio
  * a real master that was low-passed on purpose (old tape, some 80s digital) can be
    flagged. Verdicts are "fake", "ok" or "unknown" (too short / silent / unreadable);
    only "fake" should ever trigger an action.

Use it by hand:   flac_check.py FILE_OR_FOLDER ...
Exit status 0 = nothing flagged, 1 = something looks fake.

Environment (all optional)
    FLAC_CHECK_MAX_CUTOFF_KHZ   a cliff below this is suspicious     (default 19.5)
    FLAC_CHECK_MIN_DROP_DB      how deep the cliff must be           (default 30)
    FLAC_CHECK_STRONG_CUTOFF_KHZ  below this a "fake" is rated strong,
                                at or above it weak (borderline)     (default 19.0)

A "weak" verdict (cliff between 19.0 and 19.5 kHz and under 50 dB deep) is the grey zone: a 224-256 kbps
transcode looks like that, but so does a real master that was low-passed on purpose.
Callers use the rating to be gentler with those.
"""

import os
import subprocess
import sys
from pathlib import Path

import numpy as np

MAX_CUTOFF_HZ = float(os.environ.get("FLAC_CHECK_MAX_CUTOFF_KHZ", "19.5")) * 1000
MIN_DROP_DB = float(os.environ.get("FLAC_CHECK_MIN_DROP_DB", "30"))
STRONG_CUTOFF_HZ = float(os.environ.get("FLAC_CHECK_STRONG_CUTOFF_KHZ", "19.0")) * 1000
STRONG_DROP_DB = 50   # a cliff this deep is rated strong whatever the frequency
SLICE_SECONDS = 60
FFT = 4096


def _decode(path, seconds=SLICE_SECONDS):
    """Mono float32 samples from the middle of the file, plus the sample rate."""
    from mutagen.flac import FLAC
    info = FLAC(path).info
    rate, length = info.sample_rate, info.length
    start = max(0.0, length / 2 - seconds / 2) if length > seconds else 0.0
    cmd = ["ffmpeg", "-v", "error", "-ss", f"{start:.2f}", "-t", str(seconds), "-i", str(path),
           "-ac", "1", "-f", "f32le", "-"]
    raw = subprocess.run(cmd, capture_output=True, check=True).stdout
    return np.frombuffer(raw, dtype=np.float32), rate


def spectrum_db(samples):
    """Average power spectrum in dBFS over the non-silent frames, or None."""
    hop = FFT // 2
    if len(samples) < FFT * 8:
        return None
    win = np.hanning(FFT).astype(np.float32)
    frames = np.lib.stride_tricks.sliding_window_view(samples, FFT)[::hop]
    rms = np.sqrt(np.mean(frames ** 2, axis=1))
    frames = frames[rms > 10 ** (-50 / 20)]          # skip near-silence
    if len(frames) < 8:
        return None
    power = np.abs(np.fft.rfft(frames * win, axis=1)) ** 2
    power = power.mean(axis=0) / (win.sum() / 2) ** 2  # a full-scale sine reads 0 dB
    return 10 * np.log10(power + 1e-20)


def find_cliff(db, rate):
    """(cutoff_hz, drop_db) of the steepest fall above 12 kHz, or (None, 0)."""
    bin_hz = rate / FFT
    k = int(round(250 / bin_hz))                      # ~250 Hz smoothing
    smooth = np.convolve(db, np.ones(k) / k, mode="same")
    lo, hi = int(12000 / bin_hz), int((rate / 2 - 800) / bin_hz)
    w_in, w_out, gap = int(700 / bin_hz), int(700 / bin_hz), int(150 / bin_hz)
    best_f, best_drop = None, 0.0
    for i in range(lo, hi - w_out - gap):
        below = smooth[i - w_in - gap:i - gap].mean()
        above = smooth[i + gap:i + gap + w_out].mean()
        if below - above > best_drop:
            best_f, best_drop = i * bin_hz, below - above
    return best_f, best_drop


def check(path):
    """dict(verdict, cutoff_hz, drop_db, reason, strength). verdict: fake | ok | unknown;
    strength (only for "fake"): strong | weak."""
    try:
        samples, rate = _decode(path)
    except Exception as e:
        return {"verdict": "unknown", "cutoff_hz": None, "drop_db": 0, "reason": f"could not decode: {e}"}
    if rate < 44100:
        return {"verdict": "unknown", "cutoff_hz": None, "drop_db": 0, "reason": f"{rate} Hz, not checked"}
    db = spectrum_db(samples)
    if db is None:
        return {"verdict": "unknown", "cutoff_hz": None, "drop_db": 0, "reason": "too short or silent"}
    cutoff, drop = find_cliff(db, rate)
    if cutoff and drop >= MIN_DROP_DB and cutoff < MAX_CUTOFF_HZ:
        strength = "strong" if cutoff < STRONG_CUTOFF_HZ or drop >= STRONG_DROP_DB else "weak"
        return {"verdict": "fake", "cutoff_hz": cutoff, "drop_db": drop, "strength": strength,
                "reason": f"hard cutoff at {cutoff / 1000:.1f} kHz ({drop:.0f} dB drop), typical of lossy audio"
                          + (" (borderline)" if strength == "weak" else "")}
    where = f"{cutoff / 1000:.1f} kHz, {drop:.0f} dB" if cutoff else "none"
    return {"verdict": "ok", "cutoff_hz": cutoff, "drop_db": drop, "reason": f"no lossy cliff (steepest drop: {where})"}


def check_album(paths, min_share=0.5):
    """Judge a whole album: fake when at least `min_share` of its checkable tracks are.
    Returns (verdict, list of (path, result))."""
    results = [(Path(p), check(p)) for p in paths]
    judged = [r for _, r in results if r["verdict"] != "unknown"]
    if not judged:
        return "unknown", results
    fakes = sum(r["verdict"] == "fake" for r in judged)
    return ("fake" if fakes / len(judged) >= min_share else "ok"), results


def main(argv):
    files = []
    for a in argv:
        p = Path(a)
        files += sorted(p.rglob("*.flac")) if p.is_dir() else [p]
    bad = 0
    for f in files:
        r = check(f)
        bad += r["verdict"] == "fake"
        print(f"{r['verdict'].upper():8} {f}  -  {r['reason']}")
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
