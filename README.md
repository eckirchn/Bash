# Bash scripts

Updated: 23 October 2026, 10:31 PM MDT

Private scripts for finding black-frame cut points, reviewing the pieces, and compiling one high-quality file from what you keep.

Checked out at `$HOME/bin`. Sync with:

```bash
git -C "$HOME/bin" fetch origin && git -C "$HOME/bin" reset --hard origin/main
```

Scripts are stored executable. History is in [CHANGELOG.md](CHANGELOG.md).

## Latest usage

```bash
h264BlackFrameExtract MyClip.mp4
cd MyClip_work
# delete the lq_previews you do not want, then:
h264BlackFrameCompile
h265BlackFrameCompile
```

`h264BlackFrameExtract` writes `MyClip_work/`. The two compile scripts are companions of that extractor. They read the previews you left behind and write `MyClip.h264.mp4` or `MyClip.h265.mp4` next to the copied source. Either compile can be used. They do not overwrite each other.

To detect every `.mp4` in a directory, one after another:

```bash
h264BlackFrameExtract-batch
```

The batch script does not compile.

## Scripts

| Script | Doc | Result |
|---|---|---|
| `h264BlackFrameExtract` | [docs/h264BlackFrameExtract.md](docs/h264BlackFrameExtract.md) | `MyClip_work/` with previews |
| `h264BlackFrameExtract-batch` | [docs/h264BlackFrameExtract-batch.md](docs/h264BlackFrameExtract-batch.md) | one work folder per `.mp4` |
| `h264BlackFrameCompile` | [docs/h264BlackFrameCompile.md](docs/h264BlackFrameCompile.md) | `MyClip.h264.mp4` |
| `h265BlackFrameCompile` | [docs/h265BlackFrameCompile.md](docs/h265BlackFrameCompile.md) | `MyClip.h265.mp4` |

Overview: [GROK/PDF/20261023_2223-Executive-Summary-Black-Frame-Workflow.pdf](GROK/PDF/20261023_2223-Executive-Summary-Black-Frame-Workflow.pdf)

Machine these settings were chosen for: Intel Xeon E5-2680, 8 cores / 16 threads, Debian, no hardware video encoder.
