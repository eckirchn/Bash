# h264BlackFrameExtract-batch

Updated: 23 October 2026, 10:25 PM MDT

Runs `h264BlackFrameExtract` on every `*.mp4` in the current directory, one file after another.

```bash
cd /path/to/recordings
h264BlackFrameExtract-batch
```

It does not search subfolders and it ignores anything that is not `*.mp4`. Each recording still gets its own `<name>_work` folder. A long movie blocks the rest of the list until it finishes.
