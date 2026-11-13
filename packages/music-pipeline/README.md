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

Keep `lyrics_fetcher.py` and `replaygain.py` in step with the originals if you
change them there.
