# h265BlackFrameCompile

Updated: 07 November 2026, 2:42 AM MDT

Builds one HEVC file from the low-quality previews that are still in the work folder. A deleted preview is a cut you do not want. Timestamps come from the filename, not from how long the preview plays.

This is a companion to [blackframeextract](blackframeextract.md). That script detects the black frames, moves the source into `MyClip/`, and writes the previews. This script only encodes the previews you left in place. It does not depend on `h264BlackFrameCompile`.

## Run

```bash
h265BlackFrameCompile
h265BlackFrameCompile /path/to/MyClip
```

The default directory is the current one. The source is `MyClip.mp4`, moved there by [blackframeextract](blackframeextract.md). Before the first encode, the script waits until CPU use stays under 80% for 10 seconds and prints the current percent while it waits. Output, beside the source:

```text
MyClip.h265.mp4
```

This does not replace `MyClip.h264.mp4`.

## Encode

Software only. This Xeon E5-2680 has no hardware encoder. One clip at a time, all 16 threads.

| Setting | Value |
|---|---|
| Encoder | `libx265` |
| Preset | `medium` |
| Quality | CRF 20, about the same picture as the H.264 CRF 18 file, in fewer bits |
| Format | 10-bit `main10`, `hvc1` tag |
| Detail | SAO off, `aq-mode=3`, stronger psy, so film grain is not smeared |
| Color | BT.709, limited range |
| Audio | copied |

`medium` is the preset that will finish on this Xeon. `slow` HEVC at 1080p is often only 1–3 frames per second.

## Order

Clips are joined in clip-number order. A partial preview still counts; delete it if that whole segment should be dropped. The H.264 companion writes a separate `MyClip.h264.mp4`.
