# Bash scripts

Updated: 19 November 2026, 10:16 PM MST

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

### Confirm `$HOME/bin` is in your `PATH`

Many systems include `$HOME/bin` in the default `PATH`. Confirm it is present before relying on the short names from the links above:

```bash
case ":$PATH:" in
  *":$HOME/bin:"*) echo "Yes, $HOME/bin is in PATH" ;;
  *) echo "No. Add this line to ~/.bashrc (or ~/.profile), then open a new shell or run source ~/.bashrc:"
     echo 'export PATH="$HOME/bin:$PATH"' ;;
esac
```

If the check reports no, the symbolic links (or a direct checkout in `$HOME/bin`) will not be found by name alone until the directory is on the path.

## Later updates

```bash
cd "$HOME/Bash"
git pull
```

If you keep a checkout directly in `$HOME/bin` (instead of linking from a separate clone), use the `gitBinUpdate` script. It fetches the public HTTPS URL (no login) and replaces only the files that are in the repository. Extra local scripts are left alone. See [docs/gitBinUpdate.md](docs/gitBinUpdate.md).

## Examples

```bash
./sshkeygen myserver
./blackframeextract MyClip.mp4
```

Detailed steps (preview folders, which clips to keep, compile options, etc.) are in the individual files under `docs/`.

## Scripts

| Script | Doc |
|--------|-----|
| `gitBinUpdate` | [docs/gitBinUpdate.md](docs/gitBinUpdate.md) |
| `sshkeygen` | [docs/sshkeygen.md](docs/sshkeygen.md) |
| `sshkeygen.ps1` | [docs/sshkeygen.md](docs/sshkeygen.md) (non-Bash, optional) |
| `blackframeextract` | [docs/blackframeextract.md](docs/blackframeextract.md) |
| `blackframeextract-batch` | [docs/blackframeextract-batch.md](docs/blackframeextract-batch.md) |
| `h264BlackFrameCompile` | [docs/h264BlackFrameCompile.md](docs/h264BlackFrameCompile.md) |
| `h265BlackFrameCompile` | [docs/h265BlackFrameCompile.md](docs/h265BlackFrameCompile.md) |
| `BlackFrameCompile` | [docs/BlackFrameCompile.md](docs/BlackFrameCompile.md) |
