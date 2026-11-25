# BlackFrameCompile

Updated: 24 November 2026, 11:40 PM MST

Encodes one continuous video from the earliest start timestamp to the latest stop timestamp found in the `lq_previews` folder. It does not process individual clips and does not respect gaps between clips.

This is a companion to [blackframeextract](blackframeextract.md). That script detects the black frames, moves the source into `MyClip/`, and writes the previews. This script only encodes the overall range covered by the previews that remain. The per-clip companions are [h264BlackFrameCompile](h264BlackFrameCompile.md) and [h265BlackFrameCompile](h265BlackFrameCompile.md).

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

## Encoder choice

Same test as the per-clip scripts, for whichever codec was requested. `ffmpeg -encoders` must list `h264_nvenc` or `hevc_nvenc`. If `nvidia-smi` is installed it must see a GPU. A one-frame probe then has to open preset `p7` (or `hq` if `p7` is rejected) with the flags below. The Xeon E5-2680 has no hardware encoder, so the probe fails and the software flags are unchanged. One continuous encode either way.

Low-quality previews from `blackframeextract` stay on ultrafast `libx264`.

## NVIDIA (Quadro P2000 and other NVENC GPUs)

| Codec | Setting |
|---|---|
| h264 | `h264_nvenc`, preset `p7` or `hq`, `-tune hq -rc vbr -cq 18 -b:v 0`, high profile, 8-bit, spatial AQ, temporal AQ, lookahead 32, 3 B-frames |
| h265 | `hevc_nvenc`, preset `p7` or `hq`, `-tune hq -rc vbr -cq 20 -b:v 0`, 10-bit Main10, `p010le`, `hvc1`, spatial AQ, temporal AQ, lookahead 32, 3 B-frames |
| Decode | `-hwaccel cuda -hwaccel_output_format cuda` for H.264, HEVC, MPEG-2, MPEG-4, VC-1, VP8, and VP9. Other codecs use software decode. A CUDA failure retries once without it. An NVENC failure retries with `libx264` or `libx265`. |
| Color | BT.709, limited range |
| Audio | copied |

x265's SAO, psy, deblock, and `ref=4` settings are software-only. They are not applied on the NVENC path.

## Software (no NVENC)

Unchanged. This is the path on the Xeon E5-2680. One continuous encode, all 16 threads.

| Codec | Setting |
|---|---|
| h264 | `libx264`, preset `slow`, `tune film`, CRF 18, high profile, 8-bit |
| h265 | `libx265`, preset `medium`, CRF 20, 10-bit `main10`, SAO off, `aq-mode=3`, `hvc1` |
| Color | BT.709, limited range |
| Audio | copied |

The range is the minimum start and maximum stop parsed from every `LQ_Clip*.mp4` filename in `lq_previews/`.
