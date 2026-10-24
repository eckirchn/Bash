# blackframeextract-batch

Updated: 24 October 2026, 3:07 AM MDT

Runs [blackframeextract](blackframeextract.md) on every source `*.mp4` in the current directory, one file after another.

```bash
cd /path/to/recordings
blackframeextract-batch
```

It does not search subfolders. It skips `*.h264.mp4`, `*.h265.mp4`, and `LQ_Clip*.mp4`. Each file is moved into its own folder: `MyClip.mp4` becomes `MyClip/MyClip.mp4`. A long file blocks the rest of the list until it finishes.

This batch script does not compile. After reviewing a folder, use [h264BlackFrameCompile](h264BlackFrameCompile.md) or [h265BlackFrameCompile](h265BlackFrameCompile.md).
