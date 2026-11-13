# music-pipeline (Lidarr hook)

Copies of the files from the standalone `music_pipeline` folder that
`lidarr-hook` needs. `packages/lidarr-hook.nix` wraps `lidarr_hook.py` with a
Python that has mutagen, requests and Pillow, and ffmpeg on PATH.

| file | what it is |
|---|---|
| `lidarr_hook.py` | Lidarr custom-script entry point (and `--sweep` / `--fix-case`) |
| `lidarr_images.py` | non-interactive cover + artist image step |
| `lyrics_fetcher.py` | unchanged copy from music_pipeline |
| `replaygain.py` | unchanged copy from music_pipeline |
| `flac_check.py` | spots FLACs that are really transcoded MP3/AAC (spectral cutoff check) |
| `soularr_gate.py` | runs Soularr, but checks each finished download with `flac_check.py` first (used by `packages/soularr.nix`) |

Keep `lyrics_fetcher.py` and `replaygain.py` in step with the originals if you
change them there.
