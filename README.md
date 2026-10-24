# Bash scripts

Updated: 24 October 2026, 4:22 AM MDT

Scripts for the Xeon. The repository is [eckirchn/Bash](https://github.com/eckirchn/Bash). It is public. Checked out at `$HOME/bin`. History is in [CHANGELOG.md](CHANGELOG.md).

## Latest usage

### Put the repo in `$HOME/bin`

`$HOME/bin` is often just a directory of scripts. It is not a git checkout until this is run, and `git fetch` there fails.

First time, from a temp clone:

```bash
git clone https://github.com/eckirchn/Bash.git /tmp/Bash
/tmp/Bash/gitBinCreate
```

No login is required. It does not change `~/.ssh`. After `$HOME/bin` is a checkout, `gitBinUpdate` keeps the origin URL already there. An SSH origin stays on SSH.

```bash
gitBinUpdate
```

Repo files are replaced. A script that exists only in that `bin` directory is left alone. Details: [docs/gitBinCreate.md](docs/gitBinCreate.md), [docs/gitBinUpdate.md](docs/gitBinUpdate.md).

### SSH key for one server

`sshkeygen` is in this repository. The same script is also at `https://github.com/eckirchn/sshkeygen`.

```bash
git clone https://github.com/eckirchn/sshkeygen.git
sshkeygen myserver
```

From Windows PowerShell, in that clone: `.\sshkeygen.ps1 myserver`. Details: [docs/sshkeygen.md](docs/sshkeygen.md).

### Black frames

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
| `gitBinCreate` | [docs/gitBinCreate.md](docs/gitBinCreate.md) | First checkout in `$HOME/bin` |
| `gitBinUpdate` | [docs/gitBinUpdate.md](docs/gitBinUpdate.md) | Replace repo files, keep local ones |
| `sshkeygen` | [docs/sshkeygen.md](docs/sshkeygen.md) | `~/.ssh/id_ed25519.myserver` and a Host block |
| `sshkeygen.ps1` | [docs/sshkeygen.md](docs/sshkeygen.md) | Same result from Windows PowerShell |
| `h264BlackFrameExtract` | [docs/h264BlackFrameExtract.md](docs/h264BlackFrameExtract.md) | `MyClip_work/` with previews |
| `h264BlackFrameExtract-batch` | [docs/h264BlackFrameExtract-batch.md](docs/h264BlackFrameExtract-batch.md) | one work folder per `.mp4` |
| `h264BlackFrameCompile` | [docs/h264BlackFrameCompile.md](docs/h264BlackFrameCompile.md) | `MyClip.h264.mp4` |
| `h265BlackFrameCompile` | [docs/h265BlackFrameCompile.md](docs/h265BlackFrameCompile.md) | `MyClip.h265.mp4` |

Machine the video settings were chosen for: Intel Xeon E5-2680, 8 cores / 16 threads, Debian, no hardware video encoder.
