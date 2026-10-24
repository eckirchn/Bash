# Bash scripts

Updated: 24 October 2026, 7:17 AM MDT

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

## Optional: symbolic links into `$HOME/bin`

If you want the scripts on your `PATH` and also want `git pull` to update them automatically, link instead of copy:

```bash
mkdir -p "$HOME/bin"
cd "$HOME/bin"

# Link every executable script from the clone (adjust the path)
for s in "$HOME/Bash"/*; do
  [ -f "$s" ] && [ -x "$s" ] && ln -sf "$s" .
done
```

Or link only the ones you care about:

```bash
cd "$HOME/bin"
ln -sf "$HOME/Bash/sshkeygen" .
ln -sf "$HOME/Bash/h264BlackFrameCompile" .
```

After a `git pull` inside `$HOME/Bash` the linked names in `$HOME/bin` continue to point at the updated files. No re-copy needed.

## Later updates

```bash
cd "$HOME/Bash"
git pull
```

If you keep a checkout directly in `$HOME/bin` you can also use `gitBinUpdate`.

## Examples

```bash
./sshkeygen myserver
./h264BlackFrameExtract MyClip.mp4
```

Detailed steps (preview folders, which clips to keep, compile options, etc.) are in the individual files under `docs/`.

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
