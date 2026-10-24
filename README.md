# Bash scripts

Updated: 24 October 2026, 6:57 AM MDT

Personal Linux Bash scripts. This repository is public. History is in [CHANGELOG.md](CHANGELOG.md).

## Install (clone anywhere, copy what you need)

```bash
# Clone to a location of your choice
git clone https://github.com/eckirchn/Bash.git
cd Bash

# Copy the scripts you want into a directory already on your PATH
mkdir -p "$HOME/bin"
cp sshkeygen "$HOME/bin/"
# repeat for any other scripts you need
chmod +x "$HOME/bin/"*
```

If `$HOME/bin` is not on your `PATH`:

```bash
echo 'export PATH="$HOME/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

Alternatively, leave the clone where it is and add that directory to your `PATH`.

## Later updates (personal checkout in `$HOME/bin`)

If you keep a full checkout in `$HOME/bin`:

```bash
gitBinUpdate
```

Repo files are replaced. A script that exists only in that directory and is not in the repository is left alone. Details: [docs/gitBinUpdate.md](docs/gitBinUpdate.md).

## SSH key for one server

After the script is on your `PATH`:

```bash
sshkeygen myserver
```

Details: [docs/sshkeygen.md](docs/sshkeygen.md).

Windows PowerShell companion (`sshkeygen.ps1`) is non-Bash and optional.

## Black frames

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
| `sshkeygen.ps1` | [docs/sshkeygen.md](docs/sshkeygen.md) | Same result from Windows PowerShell (non-Bash) |
| `h264BlackFrameExtract` | [docs/h264BlackFrameExtract.md](docs/h264BlackFrameExtract.md) | `MyClip_work/` with previews |
| `h264BlackFrameExtract-batch` | [docs/h264BlackFrameExtract-batch.md](docs/h264BlackFrameExtract-batch.md) | one work folder per `.mp4` |
| `h264BlackFrameCompile` | [docs/h264BlackFrameCompile.md](docs/h264BlackFrameCompile.md) | `MyClip.h264.mp4` |
| `h265BlackFrameCompile` | [docs/h265BlackFrameCompile.md](docs/h265BlackFrameCompile.md) | `MyClip.h265.mp4` |
