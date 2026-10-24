# blackframeextract

Updated: 24 October 2026, 3:07 AM MDT

Finds black frames used as cut points and writes preview clips so a person can decide what to keep. The source file is moved, not copied, into a folder named after the file.

Companion scripts, used after this one:

- [h264BlackFrameCompile](h264BlackFrameCompile.md) writes `MyClip.h264.mp4`
- [h265BlackFrameCompile](h265BlackFrameCompile.md) writes `MyClip.h265.mp4`

Both read the `lq_previews` folder this script creates.

## Run

```bash
blackframeextract MyClip.mp4
```

Needs `ffmpeg`, `ffprobe`, and `bc`.

`MyClip.mp4` is moved to `MyClip/MyClip.mp4`, next to where the file was. There is no `_work` suffix. If the file is already inside that folder, it is left there.

## What it writes

| Path | What it is |
|---|---|
| `MyClip/MyClip.mp4` | The source, moved here |
| `lq_previews/` | 288p ultrafast CRF 26 previews, one file per segment |
| `MyClip_hq.sh` | Launcher. It runs [h264BlackFrameCompile](h264BlackFrameCompile.md) in this folder. |
| `MyClip_black.log` | `start end duration` of each black run |
| `MyClip_clips.log` | Clip id and `tStart` / `tStop` |

Preview names look like `LQ_Clip003_000120.000000-000185.500000.mp4`. Those numbers are the cut list the compile scripts use.

## How a cut is chosen

`blackdetect` reports each black stretch. The cut is the midpoint. Clips run from the previous midpoint (or 0) to the next, then one last clip to the end of the file.

The scan skips B-frames and looks at a 160-pixel-wide picture. A commercial black is long enough to still appear on the frames that remain, and the scan is much faster than reading every full-size frame. A black shorter than a couple of frames can be missed. That is not a commercial break.

| Variable | Default | Meaning |
|---|---|---|
| `d` | `0.15` | minimum black duration, seconds |
| `pic_th` | `0.98` | fraction of the frame that must be black |
| `pix_th` | `0.12` | how dark a pixel must be (0–1) |

Previews are 288p instead of 180p, still ultrafast, CRF 26. They are easier to recognize and stay small next to the source. The final compile is unchanged.

## Machine

Xeon E5-2680, 8 cores / 16 threads, no hardware encoder. FFmpeg uses every core (`-threads 0`). Encodes run one at a time. Each clip seeks 10 seconds early, then does an accurate seek. `-nostdin` keeps FFmpeg from reading the clip list as keyboard input.

## Next step

Delete the previews you do not want. Then, inside `MyClip`:

```bash
h264BlackFrameCompile
h265BlackFrameCompile
```

Older folders named `MyClip_work` still compile. This script will not create new ones.
