# BlackFrameCompile

Updated: 07 November 2026, 3:09 AM MDT

Encodes one continuous video from the earliest start timestamp to the latest stop timestamp found in the `lq_previews` folder. It does not process individual clips and does not respect gaps between clips.

This is a companion to [blackframeextract](blackframeextract.md). That script detects the black frames, moves the source into `MyClip/`, and writes the previews. This script only encodes the overall range covered by the previews that remain.

## Run

```bash
BlackFrameCompile h264
BlackFrameCompile h265 /path/to/MyClip
```

The first argument must be exactly `h264` or `h265`. Anything else errors out. The optional second argument is the work directory (default: current directory). The source is `MyClip.mp4`, moved there by [blackframeextract](blackframeextract.md). Before the encode it waits until CPU use stays under 80% for 10 seconds and prints the current percent while it waits.

Output, beside the source:

```text
MyClip.h264.mp4
MyClip.h265.mp4
```

## Encode

Software only. This Xeon E5-2680 has no hardware encoder. One continuous encode, all 16 threads.

| Codec | Setting |
|---|---|
| h264 | `libx264`, preset `slow`, `tune film`, CRF 18, high profile, 8-bit |
| h265 | `libx265`, preset `medium`, CRF 20, 10-bit `main10`, SAO off, `aq-mode=3`, `hvc1` |
| Color | BT.709, limited range |
| Audio | copied |

The range is the minimum start and maximum stop parsed from every `LQ_Clip*.mp4` filename in `lq_previews/`.
