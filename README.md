# Bash scripts

Updated: 24 October 2026, 7:12 AM MDT

Personal Linux Bash scripts. This repository is public. History is in [CHANGELOG.md](CHANGELOG.md).

## Get the scripts

```bash
git clone https://github.com/eckirchn/Bash.git
cd Bash
```

Clone to any directory you like (for example `$HOME/Bash`).

## Run a script from anywhere

You do not have to copy scripts or change your `PATH`. Examples:

```bash
# Full path — works from any directory
$HOME/Bash/h264BlackFrameCompile

# Or change into the clone and run with ./
cd $HOME/Bash
./h264BlackFrameCompile
./sshkeygen myserver
```

If you prefer the scripts on your `PATH`, copy the ones you want into a directory that is already on it (commonly `$HOME/bin`) and `chmod +x` them. That step is optional.

## Later updates

If you keep a checkout in `$HOME/bin` you can refresh it with `gitBinUpdate`. Otherwise just `git pull` inside your clone.

## Examples

```bash
# SSH key (run on the client)
./sshkeygen myserver

# Black frames
./h264BlackFrameExtract MyClip.mp4
cd MyClip_work
# remove the previews you do not want, then:
./h264BlackFrameCompile
./h265BlackFrameCompile
```

See the individual files under `docs/` for more detail on each script.

## Scripts

| Script | Doc |
|--------|-----|
| `gitBinUpdate` | [docs/gitBinUpdate.md](docs/gitBinUpdate.md) |
| `sshkeygen` | [docs/sshkeygen.md](docs/sshkeygen.md) |
| `sshkeygen.ps1` | [docs/sshkeygen.md](docs/sshkeygen.md) (non-Bash, optional) |
| `h264BlackFrameExtract` | [docs/h264BlackFrameExtract.md](docs/h264BlackFrameExtract.md) |
| `h264BlackFrameExtract-batch` | [docs/h264BlackFrameExtract-batch.md](docs/h264BlackFrameExtract-batch.md) |
| `h264BlackFrameCompile` | [docs/h264BlackFrameCompile.md](docs/h264BlackFrameCompile.md) |
| `h265BlackFrameCompile` | [docs/h265BlackFrameCompile.md](docs/h265BlackFrameCompile.md) |
