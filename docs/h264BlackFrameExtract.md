# h264BlackFrameExtract

Updated: 23 October 2026, 10:31 PM MDT

Finds black frames used as cut points and writes low-quality previews so a person can decide what to keep.

Companion scripts, used after this one:

- [h264BlackFrameCompile](h264BlackFrameCompile.md) writes `MyClip.h264.mp4`
- [h265BlackFrameCompile](h265BlackFrameCompile.md) writes `MyClip.h265.mp4`

Both read the `lq_previews` folder this script creates. Run either one, or both. They do not replace each other.

## Run

```bash
h264BlackFrameExtract MyClip.mp4
```

Needs `ffmpeg`, `ffprobe`, and `bc`.

## What it writes

A `MyClip_work/` folder next to the current directory:

| Path | What it is |
|---|---|
| `MyClip.mp4` | Copy of the source. The original is not moved. |
| `lq_previews/` | 180p ultrafast CRF 28 previews, one file per segment |
| `MyClip_hq.sh` | Launcher. It runs [h264BlackFrameCompile](h264BlackFrameCompile.md) in this folder. |
| `MyClip_black.log` | `start end duration` of each black run |
| `MyClip_clips.log` | Clip id and `tStart` / `tStop` |

Preview names look like `LQ_Clip003_000120.000000-000185.500000.mp4`. Those numbers are the cut list the compile scripts use.

## How a cut is chosen

`blackdetect` reports each black stretch. The cut is the midpoint. Clips run from the previous midpoint (or 0) to the next, then one last clip to the end of the file.

| Variable | Default | Meaning |
|---|---|---|
| `d` | `0.15` | minimum black duration, seconds |
| `pic_th` | `0.98` | fraction of the frame that must be black |
| `pix_th` | `0.12` | how dark a pixel must be (0–1) |

## Machine

Xeon E5-2680, 8 cores / 16 threads, no hardware encoder. FFmpeg uses every core (`-threads 0`). Encodes run one at a time. Each clip seeks 10 seconds early, then does an accurate seek, so the cut is not stuck on a keyframe. `-nostdin` keeps FFmpeg from reading the clip list as keyboard input.

## Next step

Delete the previews you do not want. Then run a companion compile in `MyClip_work`:

```bash
h264BlackFrameCompile
h265BlackFrameCompile
```
