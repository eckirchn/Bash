# Bash scripts

Updated: 24 October 2026, 6:40 AM MDT

Scripts for the Xeon. This repository is public. Checked out at `$HOME/bin`. History is in [CHANGELOG.md](CHANGELOG.md).

## Latest usage

### Install into `$HOME/bin`

```bash
git clone https://github.com/eckirchn/Bash.git "$HOME/bin"
```

No login. Does not change `~/.ssh`. If `$HOME/bin` is not already on `PATH`:

```bash
echo 'export PATH="$HOME/bin:$PATH"' >> ~/.bashrc && source ~/.bashrc
```

### Later updates

After `$HOME/bin` is a checkout, `gitBinUpdate` keeps the origin URL already there. An SSH origin stays on SSH. It does not create a checkout.

```bash
gitBinUpdate
```

Repo files are replaced. A script that exists only in that `bin` directory is left alone. Details: [docs/gitBinUpdate.md](docs/gitBinUpdate.md).

### SSH key for one server

`sshkeygen` is in this repository. After the install above:

```bash
sshkeygen myserver
```

From Windows PowerShell, in a checkout of this repository: `.\sshkeygen.ps1 myserver`. Details: [docs/sshkeygen.md](docs/sshkeygen.md).

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
| `gitBinUpdate` | [docs/gitBinUpdate.md](docs/gitBinUpdate.md) | Replace repo files, keep local ones |
| `sshkeygen` | [docs/sshkeygen.md](docs/sshkeygen.md) | `~/.ssh/id_ed25519.myserver` and a Host block |
| `sshkeygen.ps1` | [docs/sshkeygen.md](docs/sshkeygen.md) | Same result from Windows PowerShell |
| `h264BlackFrameExtract` | [docs/h264BlackFrameExtract.md](docs/h264BlackFrameExtract.md) | `MyClip_work/` with previews |
| `h264BlackFrameExtract-batch` | [docs/h264BlackFrameExtract-batch.md](docs/h264BlackFrameExtract-batch.md) | one work folder per `.mp4` |
| `h264BlackFrameCompile` | [docs/h264BlackFrameCompile.md](docs/h264BlackFrameCompile.md) | `MyClip.h264.mp4` |
| `h265BlackFrameCompile` | [docs/h265BlackFrameCompile.md](docs/h265BlackFrameCompile.md) | `MyClip.h265.mp4` |

Machine the video settings were chosen for: Intel Xeon E5-2680, 8 cores / 16 threads, Debian, no hardware video encoder.
