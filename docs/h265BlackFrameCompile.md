# h265BlackFrameCompile

Updated: 24 November 2026, 11:40 PM MST

Builds one HEVC file from the low-quality previews that are still in the work folder. A deleted preview is a cut you do not want. Timestamps come from the filename, not from how long the preview plays.

This is a companion to [blackframeextract](blackframeextract.md). That script detects the black frames, moves the source into `MyClip/`, and writes the previews. This script only encodes the previews you left in place. It does not depend on `h264BlackFrameCompile`. The continuous-range companion is [BlackFrameCompile](BlackFrameCompile.md).

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

## Encoder choice

Checked once, before the CPU wait. Nothing is assumed about the machine.

1. `ffmpeg -encoders` must list `hevc_nvenc`.
2. If `nvidia-smi` is installed, `nvidia-smi -L` must list a GPU. If it is not installed, a one-frame probe is the only GPU test. FFmpeg lists NVENC on builds that have no card, including the Xeon E5-2680, so the list alone is not enough.
3. A one-frame probe must open the encoder with the flags below, including 10-bit Main10. Preset `p7` is tried first. If that is rejected, preset `hq` is tried. If both fail, or no GPU answers, the software path below is used and the encode flags are the ones this script has used since 7 November 2026.

One clip at a time either way. Low-quality previews from `blackframeextract` stay on ultrafast `libx264`.

## NVIDIA (Quadro P2000 and other NVENC GPUs)

The Quadro P2000 encodes HEVC Main10. Sessions are not limited on that card.

| Setting | Value |
|---|---|
| Encoder | `hevc_nvenc` |
| Preset | `p7`, or `hq` if `p7` is rejected |
| Quality | `-tune hq -rc vbr -cq 20 -b:v 0` (the CQ stand-in for CRF 20) |
| Format | 10-bit Main10, `p010le` (NVENC's 10-bit 4:2:0), `hvc1` tag |
| Detail | spatial AQ and temporal AQ stand in for x265 `aq-mode=3`. Lookahead is 32, the NVENC cap, instead of x265's 40. 3 B-frames, which Pascal accepts, instead of x265's 6. |
| Not mapped | SAO off, psy-rd, psy-rdoq, deblock, and `ref=4` have no NVENC switch. Those stay on the software path only. |
| Decode | `-hwaccel cuda -hwaccel_output_format cuda` when the source codec is H.264, HEVC, MPEG-2, MPEG-4, VC-1, VP8, or VP9. If CUDA decode fails, that clip is retried with software decode and NVENC. If NVENC itself fails, that clip and the rest use `libx265`. |
| Color | BT.709, limited range |
| Audio | copied |

## Software (no NVENC)

Unchanged. This is the path on the Xeon E5-2680. One clip at a time, all 16 threads.

| Setting | Value |
|---|---|
| Encoder | `libx265` |
| Preset | `medium` |
| Quality | CRF 20, about the same picture as the H.264 CRF 18 file, in fewer bits |
| Format | 10-bit `main10`, `yuv420p10le`, `hvc1` tag |
| Detail | SAO off, `aq-mode=3`, stronger psy, so film grain is not smeared |
| Color | BT.709, limited range |
| Audio | copied |

`medium` is the preset that will finish on this Xeon. `slow` HEVC at 1080p is often only 1–3 frames per second.

## Order

Clips are joined in clip-number order. A partial preview still counts; delete it if that whole segment should be dropped. The H.264 companion writes a separate `MyClip.h264.mp4`.
