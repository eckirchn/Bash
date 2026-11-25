# h264BlackFrameCompile

Updated: 25 November 2026, 12:05 AM MST

Builds one H.264 file from the low-quality previews that are still in the work folder. A deleted preview is a cut you do not want. Timestamps come from the filename, not from how long the preview plays.

This is a companion to [blackframeextract](blackframeextract.md). That script detects the black frames, moves the source into `MyClip/`, and writes the previews. This script does not detect anything. The HEVC companion is [h265BlackFrameCompile](h265BlackFrameCompile.md), which is independent. The continuous-range companion is [BlackFrameCompile](BlackFrameCompile.md).

## Run

```bash
h264BlackFrameCompile
h264BlackFrameCompile /path/to/MyClip
```

The default directory is the current one. The source is `MyClip.mp4`, moved there by [blackframeextract](blackframeextract.md). Before the first encode, the script waits until CPU use stays under 80% for 10 seconds and prints the current percent while it waits. Output, beside the source:

```text
MyClip.h264.mp4
```

## Windows

The bash script runs on the Xeon. It does not run in Windows PowerShell. The Dell OptiPlex (i7-4770, Quadro P2000) uses the companion, which applies the same encoder test and the same flags. `BlackFrameEncode.ps1` is loaded by that companion. Do not run it directly.

```powershell
.\h264BlackFrameCompile.ps1
.\h264BlackFrameCompile.ps1 .\MyClip
```

`ffmpeg.exe` and `ffprobe.exe` must be on `PATH` (for example `%USERPROFILE%\bin`). `nvidia-smi` comes with the NVIDIA driver. If Windows blocks the script:

```powershell
powershell -ExecutionPolicy Bypass -File .\h264BlackFrameCompile.ps1 .\MyClip
```

The i7-4770 is 4 cores / 8 threads. The software flags are still `libx264` slow CRF 18, the same as the Xeon, and that path is slow on this CPU. This machine should take the Quadro P2000 path.

## Encoder choice

Checked once, before the CPU wait. Nothing is assumed about the machine.

1. `ffmpeg -encoders` must list `h264_nvenc`.
2. If `nvidia-smi` is installed, `nvidia-smi -L` must list a GPU. If it is not installed, a one-frame probe is the only GPU test. FFmpeg lists NVENC on builds that have no card, including the Xeon E5-2680, so the list alone is not enough.
3. A one-frame probe must open the encoder with the flags below. Preset `p7` is tried first. If that is rejected, preset `hq` is tried. If both fail, or no GPU answers, the software path below is used and the encode flags are the ones this script has used since 7 November 2026.

One clip at a time either way. Low-quality previews from `blackframeextract` stay on ultrafast `libx264`.

## NVIDIA (Quadro P2000 and other NVENC GPUs)

Pascal NVENC, including the Quadro P2000, encodes H.264 high profile. Sessions are not limited on that card.

| Setting | Value |
|---|---|
| Encoder | `h264_nvenc` |
| Preset | `p7`, or `hq` if `p7` is rejected |
| Quality | `-tune hq -rc vbr -cq 18 -b:v 0` (the CQ stand-in for CRF 18) |
| Detail | spatial AQ, temporal AQ, lookahead 32, 3 B-frames |
| Format | high profile, 8-bit 4:2:0 |
| Decode | `-hwaccel cuda -hwaccel_output_format cuda` when the source codec is H.264, HEVC, MPEG-2, MPEG-4, VC-1, VP8, or VP9. Anything else, including AV1, is software decode. If CUDA decode fails, that clip is retried with software decode and NVENC. If NVENC itself fails, that clip and the rest use `libx264`. |
| Color | BT.709, limited range |
| Audio | copied |

## Software (no NVENC)

Unchanged. This is the path on the Xeon E5-2680. One clip at a time, all 16 threads.

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
