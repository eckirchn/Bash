# Bash scripts

Private collection of scripts checked out at `$HOME/bin`.

```bash
git -C "$HOME/bin" fetch origin && git -C "$HOME/bin" reset --hard origin/main
chmod +x "$HOME/bin"/h264BlackFrameExtract "$HOME/bin"/h264BlackFrameExtract-batch
```

GitHub stores these as mode `100644`. After a hard reset, run `chmod +x` once if the scripts are not executable.

Every commit on `main` is a kept version. To get an older copy:

```bash
git -C "$HOME/bin" log --oneline
git -C "$HOME/bin" show <sha>:h264BlackFrameExtract
```

## h264BlackFrameExtract

Finds black frames used as cut points (movie joins, commercial breaks) and writes low-quality preview clips plus a high-quality encode script that reuses the same timestamps.

**Dependencies:** `ffmpeg`, `ffprobe`, `bc` (`sudo apt install ffmpeg bc`).

**Run:**

```bash
h264BlackFrameExtract /path/to/video.mp4
```

Creates `<name>_work/` next to the current directory:

| Path | What it is |
|---|---|
| `lq_previews/` | 180p ultrafast CRF 28 previews, one clip per segment |
| `<name>_hq.sh` | HQ encode (`libx264` medium, CRF 18, `-threads 0`) |
| `<name>_black.log` | `start end duration` of each black run |
| `<name>_clips.log` | clip id and `tStart` / `tStop` |

The source file is copied into the work directory, not moved.

Review the LQ clips and delete the ones you do not want. The HQ script still encodes every detected segment; edit `<name>_hq.sh` (or delete lines) before running it if you dropped some previews.

```bash
bash <name>_work/<name>_hq.sh /path/to/original.mp4 ./hq_clips
```

**How cuts are chosen.** `blackdetect` reports black runs. The midpoint of each run is the cut. Clips run from the previous midpoint (or 0) to the next midpoint, then a final clip to the end of the file.

**Thresholds** (top of `fnDetectBlackSegments`):

| Variable | Default | Meaning |
|---|---|---|
| `d` | `0.15` | minimum black duration, seconds |
| `pic_th` | `0.98` | fraction of the frame that must be black |
| `pix_th` | `0.12` | how dark a pixel must be (0–1) |

**Threading.** FFmpeg is allowed to use every core (`-threads 0`). Encodes run one at a time so the E5-2680 (8 cores / 16 threads) is not oversubscribed. There is no `xterm` and no CPU-sleep throttle.

**Seek.** Each clip fast-seeks 10 seconds early, then does an accurate `-ss` for the remainder, so the cut is not stuck on a keyframe.

## h264BlackFrameExtract-batch

Runs `h264BlackFrameExtract` on every `*.mp4` in the current directory.

```bash
h264BlackFrameExtract-batch
```
