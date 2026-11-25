# BlackFrameCompileBatch-h265

Updated: 25 November 2026, 12:41 AM MST

Runs [BlackFrameCompile](BlackFrameCompile.md) with `h265` in every subdirectory of the current directory. One folder at a time. The argument is `h265`. `265` is rejected by `BlackFrameCompile`.

```bash
cd /path/to/MyClips
BlackFrameCompileBatch-h265
```

`MyClips/` is a folder of work folders, each one made by [blackframeextract](blackframeextract.md):

```text
MyClips/MyClip/lq_previews/
MyClips/MyOtherClip/lq_previews/
```

The script changes into `MyClip/`, runs `BlackFrameCompile h265`, then does the same for `MyOtherClip/`. It does not search deeper than those folders. A folder that fails is reported, and the next folder still runs. If any folder failed, the script exits non-zero.

`BlackFrameCompile` must be on `PATH`. Output in each folder is `MyClip.h265.mp4`.
