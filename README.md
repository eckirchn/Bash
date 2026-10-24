# Bash scripts

Updated: 24 October 2026, 3:14 AM MDT

Private scripts. Checked out at `$HOME/bin`. History is in [CHANGELOG.md](CHANGELOG.md).

## Latest usage

### Put the repo in `$HOME/bin`

`$HOME/bin` is often just a directory of scripts. It is not a git checkout until this is run, and `git fetch` there fails.

First time, from a temp clone:

```bash
git clone git@github.com:eckirchn/Bash.git /tmp/Bash
/tmp/Bash/gitBinCreate
```

After that:

```bash
gitBinUpdate
```

Repo files are replaced. A script that exists only in that `bin` directory is left alone. Details: [docs/gitBinCreate.md](docs/gitBinCreate.md), [docs/gitBinUpdate.md](docs/gitBinUpdate.md).

### SSH key for one server

```bash
sshkeygen myserver
ssh myserver
```

From Windows PowerShell, same job:

```powershell
.\sshkeygen.ps1 myserver
ssh myserver
```

That writes `~/.ssh/id_ed25519.myserver` and a `Host myserver` block. Fedora, Ubuntu, Raspberry Pi OS, Git Bash, and Windows PowerShell can run it. The server is Fedora, Ubuntu, or Raspberry Pi OS. Details: [docs/sshkeygen.md](docs/sshkeygen.md).

### Black frames

```bash
blackframeextract MyClip.mp4
cd MyClip
# delete the lq_previews you do not want, then:
h264BlackFrameCompile
h265BlackFrameCompile
```

`blackframeextract` moves `MyClip.mp4` into `MyClip/MyClip.mp4`. The two compile scripts are companions of that extractor. They read the previews you left behind and write `MyClip.h264.mp4` or `MyClip.h265.mp4` next to the source. Either compile can be used. They do not overwrite each other. Older `MyClip_work` folders still compile. Both compiles wait until CPU use stays under 80% for 10 seconds before the first encode, and they print the current percent while they wait.

To detect every source `.mp4` in a directory, one after another:

```bash
blackframeextract-batch
```

The batch script does not compile. It skips files already named `.h264.mp4` or `.h265.mp4`.

## Scripts

| Script | Doc | Result |
|---|---|---|
| `gitBinCreate` | [docs/gitBinCreate.md](docs/gitBinCreate.md) | First checkout in `$HOME/bin` |
| `gitBinUpdate` | [docs/gitBinUpdate.md](docs/gitBinUpdate.md) | Replace repo files, keep local ones |
| `sshkeygen` | [docs/sshkeygen.md](docs/sshkeygen.md) | `~/.ssh/id_ed25519.myserver` and a Host block |
| `sshkeygen.ps1` | [docs/sshkeygen.md](docs/sshkeygen.md) | Same result from Windows PowerShell |
| `blackframeextract` | [docs/blackframeextract.md](docs/blackframeextract.md) | `MyClip/` with the source moved in, plus previews |
| `blackframeextract-batch` | [docs/blackframeextract-batch.md](docs/blackframeextract-batch.md) | one folder per source `.mp4` |
| `h264BlackFrameCompile` | [docs/h264BlackFrameCompile.md](docs/h264BlackFrameCompile.md) | `MyClip.h264.mp4` |
| `h265BlackFrameCompile` | [docs/h265BlackFrameCompile.md](docs/h265BlackFrameCompile.md) | `MyClip.h265.mp4` |

Black-frame overview: [GROK/PDF/20261023_2223-Executive-Summary-Black-Frame-Workflow.pdf](GROK/PDF/20261023_2223-Executive-Summary-Black-Frame-Workflow.pdf)

Machine the video settings were chosen for: Intel Xeon E5-2680, 8 cores / 16 threads, Debian, no hardware video encoder.
