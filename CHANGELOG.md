# Changelog

Times are Mountain Time. Each entry is one revision on `main`.

## 24 October 2026, 4:16 AM MDT

`sshkeygen`, `sshkeygen.ps1`, `docs/sshkeygen.md`, and `archive/sshkeygen-20190126` were removed from this private repository and published at `https://github.com/eckirchn/sshkeygen`. No account is required to clone that repository. A later `git reset --hard` on the Xeon removes the old copies from `$HOME/bin` because they were tracked here. `eckirchn/bin` was not changed.

## 24 October 2026, 4:14 AM MDT

The working repository is `eckirchn/Bash`. Further changes are committed there. `eckirchn/bin` is left as the public snapshot from 3:32 AM and is not updated unless that is requested. The Xeon checkout command is unchanged: `git -C "$HOME/bin" fetch origin && git -C "$HOME/bin" reset --hard origin/main`.

## 24 October 2026, 3:32 AM MDT

The whole bin directory is public at `https://github.com/eckirchn/bin`. No account is required to clone it. That copy includes the scripts and the docs. It does not include the PDF folder, and it does not name that folder. `gitBinCreate` and `gitBinUpdate` in the public copy fetch `https://github.com/eckirchn/bin.git`. This private checkout is unchanged and still uses its existing origin.

## 24 October 2026, 3:24 AM MDT

Only one machine needs the private beta. `sshkeygen` and `sshkeygen.ps1` are published at `https://github.com/eckirchn/sshkeygen`, which is public. Another machine clones that URL over HTTPS with no account and no SSH key. The black-frame scripts and `gitBinCreate` / `gitBinUpdate` stay in this private repo.

## 24 October 2026, 3:19 AM MDT

The Xeon checkout fetched `8efec67` over SSH with `git fetch` and `reset --hard`. That machine already had a GitHub key. `gitBinUpdate` can keep using that origin.

The BirdNet failure `Permission denied (publickey)` happens before GitHub looks at the repo. No offered key was accepted. A missing key, or a key that was never added to the GitHub account, is enough. A private repo does not by itself produce that message: a key GitHub accepts, but which cannot see the repo, usually gets `Repository not found` instead. Nothing has to be changed on the Pi unless that machine should fetch this repo. `~/.ssh` is still not written by these scripts.

## 24 October 2026, 3:17 AM MDT

`gitBinUpdate` on the Xeon failed after `adf6a34`. That checkout's origin was still `git@github.com:eckirchn/Bash.git`, and a plain `git fetch` over SSH succeeded. The script then set `GIT_SSH_COMMAND` to refuse SSH because its default URL is HTTPS, so the fetch died with `Refusing SSH` and `Could not fetch`.

The script no longer does that. An origin that is already this repo is fetched as it is. SSH stays SSH. HTTPS stays HTTPS, still pinned so a global rewrite cannot turn it into SSH. A brand-new checkout still uses HTTPS, so a machine whose GitHub key is for something else is not offered that key. `~/.ssh` is still not read or written.

## 24 October 2026, 3:14 AM MDT

`gitBinCreate` and `gitBinUpdate` no longer default to `git@github.com`. On BirdNet, an SSH clone was refused with `Permission denied (publickey)`. That Pi may already have a GitHub key from the BirdNET-Pi install. These scripts do not call `ssh-keygen`, do not write `~/.ssh`, and do not add a `Host github.com` block. The default URL is `https://github.com/eckirchn/Bash.git`. An https URL is pinned so a global rewrite to SSH does not catch it, and an https fetch will not run `ssh`. A private fetch asks for the GitHub login and a personal access token. Local-only files in `bin` are still left in place. A directory that already tracks a different remote is still refused.

## 24 October 2026, 2:55 AM MDT

`gitBinCreate` and `gitBinUpdate`. On the BirdNet Pi, `git -C "$HOME/bin" fetch` failed because `$HOME/bin` is a directory of scripts, not a checkout (`fatal: not a git repository`).

`gitBinCreate` is the first run. Clone the repo to a temp directory, then run `/tmp/Bash/gitBinCreate`. It turns `$HOME/bin` into a checkout of `git@github.com:eckirchn/Bash.git`. `gitBinUpdate` does that same create when `.git` is missing, and on later runs it only refreshes files. Both refuse a directory that already tracks a different remote.

Neither script deletes files. A name that is in the repo is overwritten, including a local edit to that name. A script that exists only in `bin` is left alone, not added, and not pushed. `git clean` and `git reset --hard` are not used. A file dropped from the repo on GitHub stays on disk and becomes untracked. Docs: `docs/gitBinCreate.md`, `docs/gitBinUpdate.md`. The README no longer tells you to `reset --hard`.

## 24 October 2026, 2:36 AM MDT

`sshkeygen` for current Fedora, Ubuntu, Raspberry Pi OS, Git Bash, and Windows PowerShell. The live scripts are `sshkeygen` and `sshkeygen.ps1`. Documented in `docs/sshkeygen.md`.

Imported the 26 January 2019 script unchanged as `archive/sshkeygen-20190126`. Its own stamp was `20190126_1116`. Time zone was not recorded. That copy is not the one to run. It required `fpaste` before it would do anything, so it stops on Ubuntu and Raspberry Pi OS, where that package is not installed. It built an empty-passphrase RSA 4096 key, forced the comment to a fixed name at `$HOSTNAME`, and stored the key under `/home/$USER` instead of `$HOME`. It appended a `Host` block on every new key, so a second `Host` for the same name sat below the first one and SSH ignored it. There was no `IdentitiesOnly`, no port, and no remote user other than the local account. If `ssh-copy-id` failed it printed the public key and uploaded it with `fpaste`. The success text said the local `authorized_keys` file was updated; the key actually goes to the server. It then told the operator to set `PasswordAuthentication no`, `ChallengeResponseAuthentication no`, and `UsePAM no`. On current OpenSSH the keyboard setting is `KbdInteractiveAuthentication`. `UsePAM no` is the wrong advice on Fedora, Ubuntu, and Raspberry Pi OS.

The new script keeps a separate key per host, `id_ed25519.<alias>` unless `-t rsa` is set. A passphrase is prompted for unless `--empty-passphrase` or `-N` is passed. The managed block is marked `# BEGIN sshkeygen <alias>` / `# END sshkeygen <alias>` and written at the top of `~/.ssh/config`, with `IdentitiesOnly yes` and `IdentityFile ~/.ssh/...`. A second run reuses the key and replaces that block instead of duplicating it. `ssh-copy-id` is used when it is installed. Windows OpenSSH has no `ssh-copy-id`, so `sshkeygen.ps1` (and the bash script, if the helper is missing) appends the public key with `ssh`. Nothing is sent to a paste site. The script does not edit `sshd`. After a successful copy it prints the reload command for Fedora (`sshd`), Ubuntu (`ssh`), and Raspberry Pi OS (`ssh`), and it says to test in a second terminal first.

## 23 October 2026, 10:31 PM MDT

Documentation cross-links. The extractor doc names both compile scripts as companions. Each compile doc links back to `h264BlackFrameExtract`. Examples use `MyClip` instead of a real recording name. The executive summary moved to `GROK/PDF/20261023_2223-Executive-Summary-Black-Frame-Workflow.pdf`.

## 23 October 2026, 10:26 PM MDT

`23c9d90` — First full documentation pass. One markdown file per script, a shorter README, and the executive summary PDF. Each script header stamped 10:25 PM MDT. No change to encode behavior.

## 23 October 2026, 10:05 PM MDT

`83e2ad4` — Compile output names changed from `.clean.mp4` and `.clean.h265.mp4` to `MyClip.h264.mp4` and `MyClip.h265.mp4`. Those finished files are skipped when the compile script looks for the source video, so a second run does not encode its own output.

## 23 October 2026, 9:26 PM MDT

`b058fc5` — H.264 compile retuned for this Xeon: `libx264`, preset `slow`, `tune film`, CRF 18, high profile, 8-bit. Added `h265BlackFrameCompile`: `libx265`, preset `medium`, CRF 20, 10-bit `main10`, SAO off, `aq-mode=3`, `hvc1`. `medium` is the usable HEVC preset here. `slow` HEVC at 1080p is often 1–3 frames per second. Audio stayed a copy. One encode at a time.

## 23 October 2026, 7:16 PM MDT

`acbbdd7` — The `.hq.sh` file written into the work folder stopped being an encoder. Running that older file with `sh` and no arguments died on line 5 (`INFILE="$1"`) with `parameter not set`. It is now a launcher that runs `h264BlackFrameCompile` in the work folder.

## 22 October 2026, 8:03 AM MDT

`9f361d5` — Added `h264BlackFrameCompile`. It keeps whatever previews are still in `lq_previews`, reads start and stop from the filename, encodes those ranges from the copied source, and joins them into one file. A missing preview is treated as deleted. A partial preview still counts. First version used x264 `medium` CRF 18 and wrote a `.clean.mp4`.

## 22 October 2026, 7:54 AM MDT

`6afa135` — FFmpeg, inside the preview loop, was reading the clip log as keyboard input. The `C` in `Clip:` is its "send command" key, so later clips were never encoded and the log lines showed up as parse errors (`lip:005 ...`). Every FFmpeg call now passes `-nostdin`. Encodes also print `-stats`, so a long clip shows progress.

## 22 October 2026, 7:36 AM MDT

`447b4b3` — Fixed the generated high-quality command so the source path is quoted correctly, and marked the scripts executable (`100755`) so a hard reset keeps the `+x` bit.

## 22 October 2026, 1:34 AM MDT

`77d032b` — First modernization of the 2018–2020 extractor, pushed to `main`. Replaced the `blackframe` log scrape with `blackdetect`. Removed `xterm`, the one-thread cap, and the CPU-sleep throttle. FFmpeg uses every core (`-threads 0`) and previews run one at a time. Wrote a per-clip high-quality script. That script's quoting was wrong and was fixed in `447b4b3`.

## 22 October 2026, 1:13 AM MDT

`1625d3a` — Imported the original `h264BlackFrameExtract`. It used the `blackframe` filter, parsed a full frame log, opened an `xterm` per clip, forced one FFmpeg thread, and slept when the CPU looked busy. That copy remains in git history.
