# gitBinUpdate

Updated: 24 October 2026, 2:55 AM MDT

Writes the current repo files into `$HOME/bin`. Files that are not in the repo are left in place.

If `$HOME/bin` is not a checkout yet, this does the same job as [gitBinCreate](gitBinCreate.md).

## Run

```bash
gitBinUpdate
```

Another directory:

```bash
gitBinUpdate "$HOME/bin"
```

HTTPS instead of SSH:

```bash
GIT_BIN_REMOTE=https://github.com/eckirchn/Bash.git gitBinUpdate
```

## What it will and will not do

| | |
|---|---|
| Replace `sshkeygen` with the repo copy | Yes |
| Leave a local script such as `myLocalScript` alone | Yes |
| Delete a file that is not in the repo | No |
| Keep a local edit to a file that is in the repo | No. The repo copy wins. |
| Commit or push what is only on this machine | No |

A file removed from the repo on GitHub is also left on disk. It is no longer tracked. Delete it yourself if you do not want it.

The script refuses to run if the directory already tracks a different remote.

## After a failed fetch

The repo is private. This machine needs a GitHub login.

```bash
ssh -T git@github.com
```

Or set `GIT_BIN_REMOTE` to `https://github.com/eckirchn/Bash.git` and use a personal access token when git asks.
