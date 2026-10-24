# h264BlackFrameCompile

Updated: 23 October 2026, 10:31 PM MDT

Builds one H.264 file from the low-quality previews that are still in the work folder. A deleted preview is a cut you do not want. Timestamps come from the filename, not from how long the preview plays.

This is a companion to [h264BlackFrameExtract](h264BlackFrameExtract.md). That script detects the black frames and writes the previews. This script does not detect anything. The HEVC companion is [h265BlackFrameCompile](h265BlackFrameCompile.md).

## Run

```bash
h264BlackFrameCompile
h264BlackFrameCompile /path/to/MyClip_work
```

The default directory is the current one. The source is `MyClip.mp4`, copied there by the extractor. Output, beside the source:

```text
MyClip.h264.mp4
```

## Encode

Software only. This Xeon E5-2680 has no hardware encoder. One clip at a time, all 16 threads.

| Setting | Value |
|---|---|
| Encoder | `libx264` |
| Preset | `slow`, `tune film` |
| Quality | CRF 18, high profile, 8-bit 4:2:0 |
| Color | BT.709, limited range |
| Audio | copied |

`slow` is the useful quality step on this CPU. `veryslow` is not worth the time.

## Order

Clips are joined in clip-number order. A partial preview still counts; delete it if that whole segment should be dropped. The H.265 companion writes a separate `MyClip.h265.mp4`.
