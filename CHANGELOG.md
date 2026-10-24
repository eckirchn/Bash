# Changelog

Times are Mountain Time. Each entry is one revision on `main`.

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
