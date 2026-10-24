# Bash scripts

Updated: 23 October 2026, 10:25 PM MDT

Private scripts for finding black-frame cut points in a recording, reviewing the pieces, and compiling one high-quality file from what you keep.

Checked out at `$HOME/bin`. Sync with:

```bash
git -C "$HOME/bin" fetch origin && git -C "$HOME/bin" reset --hard origin/main
```

Scripts are stored executable. Every commit on `main` is a kept version.

## How it fits together

1. `h264BlackFrameExtract` finds the black frames and writes 180p previews.
2. Delete the previews you do not want.
3. `h264BlackFrameCompile` or `h265BlackFrameCompile` encodes what remains into one file.

`h264BlackFrameExtract-batch` only repeats step 1 for every `.mp4` in the current directory.

A two-page overview is in [docs/Executive-Summary-Black-Frame-Workflow-2026-10-23.pdf](docs/Executive-Summary-Black-Frame-Workflow-2026-10-23.pdf).

## Scripts

| Script | Doc | Result |
|---|---|---|
| `h264BlackFrameExtract` | [docs/h264BlackFrameExtract.md](docs/h264BlackFrameExtract.md) | `<name>_work/` with previews |
| `h264BlackFrameExtract-batch` | [docs/h264BlackFrameExtract-batch.md](docs/h264BlackFrameExtract-batch.md) | one work folder per `.mp4` |
| `h264BlackFrameCompile` | [docs/h264BlackFrameCompile.md](docs/h264BlackFrameCompile.md) | `<name>.h264.mp4` |
| `h265BlackFrameCompile` | [docs/h265BlackFrameCompile.md](docs/h265BlackFrameCompile.md) | `<name>.h265.mp4` |

Machine these settings were chosen for: Intel Xeon E5-2680, 8 cores / 16 threads, Debian, no hardware video encoder.
