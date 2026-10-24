# h264BlackFrameCompile

Updated: 23 October 2026, 10:25 PM MDT

Builds one H.264 file from the low-quality previews that are still in the work folder. A deleted preview is a cut you do not want. Timestamps come from the filename, not from how long the preview plays.

## Run

```bash
h264BlackFrameCompile
h264BlackFrameCompile "/path/to/Name_work"
```

The default directory is the current one. The source is the video copied into that folder. Output, beside the source:

```text
Name.h264.mp4
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

Clips are joined in clip-number order. A partial preview still counts; delete it if that whole segment should be dropped. The H.265 file, if you also make one, is a separate `<name>.h265.mp4`.
