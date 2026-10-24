# h265BlackFrameCompile

Updated: 23 October 2026, 10:31 PM MDT

Same job as [h264BlackFrameCompile](h264BlackFrameCompile.md), with HEVC. It calls that script with `--hevc`.

This is a companion to [h264BlackFrameExtract](h264BlackFrameExtract.md). That script detects the black frames and writes the previews. This script only encodes the previews you left in place.

## Run

```bash
h265BlackFrameCompile
h265BlackFrameCompile /path/to/MyClip_work
```

Output, beside the source:

```text
MyClip.h265.mp4
```

This does not replace `MyClip.h264.mp4`.

## Encode

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
