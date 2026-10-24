# h264BlackFrameExtract-batch

Updated: 23 October 2026, 10:31 PM MDT

Runs [h264BlackFrameExtract](h264BlackFrameExtract.md) on every `*.mp4` in the current directory, one file after another.

```bash
cd /path/to/recordings
h264BlackFrameExtract-batch
```

It does not search subfolders and it ignores anything that is not `*.mp4`. `MyClip.mp4` still gets its own `MyClip_work` folder. A long file blocks the rest of the list until it finishes.

After each folder is reviewed, compile with [h264BlackFrameCompile](h264BlackFrameCompile.md) or [h265BlackFrameCompile](h265BlackFrameCompile.md). This batch script does not compile.
