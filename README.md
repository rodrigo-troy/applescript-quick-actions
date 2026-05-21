# AppleScripts

A collection of macOS AppleScript utilities that automate Finder file tasks — video processing,
image batch operations, and quick file creation. Each script runs as an Automator Quick Action
(right-click menu);

## Scripts

### Merge MP4 Videos with Audio

Concatenates 2 or more MP4 files into a single video with motion-interpolated frame blending.

**What it does:**

- Sorts selected MP4 files by creation date
- Merges them using FFmpeg's concat demuxer
- Applies frame interpolation to 60 fps (`minterpolate` with bidirectional motion estimation)
- Encodes with Apple's hardware encoder (`h264_videotoolbox`) at 10 Mbps
- Re-encodes audio as AAC at 192 kbps
- Saves output as
  `<first-selected>-merged_YYYYMMDD_HHMMSS.mp4` in the same folder as the first file (the first-selected file's basename anchors both the output folder and the merged filename, so the result sorts next to it in Finder)

**Requirements:** FFmpeg (`brew install ffmpeg`)

**Usage:**

1. Select 2+ MP4 files in Finder
2. Run the script

---

### Enhance MP4 Video

Applies frame interpolation and hardware-accelerated re-encoding to a single MP4 file.

**What it does:**

- Takes a single selected MP4 file
- Applies frame interpolation to 60 fps (`minterpolate` with bidirectional motion estimation)
- Encodes with Apple's hardware encoder (`h264_videotoolbox`) at 10 Mbps
- Re-encodes audio as AAC at 192 kbps
- Saves output as `<original>-enhanced_YYYYMMDD_HHMMSS.mp4` in the same folder

**Requirements:** FFmpeg (`brew install ffmpeg`)

**Usage:**

1. Select exactly 1 MP4 file in Finder
2. Run the script

---

### Upscale MP4 Video

Doubles the resolution of a single MP4 file (2x width, 2x height) using FFmpeg with the lanczos
resampler and hardware-accelerated H.264 encoding.

**What it does:**

- Takes a single selected MP4 file
- Applies a spatial upscale to 2x width and 2x height with FFmpeg's `lanczos` resampler — sharper
  than the default bicubic, the standard pick for video enlargement
- Encodes with Apple's hardware encoder (`h264_videotoolbox`) at 20 Mbps (twice the Enhance/Merge
  bitrate to accommodate the quadrupled pixel count)
- Copies the audio stream losslessly (no re-encoding)
- Saves output as `<original>-upscaled_YYYYMMDD_HHMMSS.mp4` in the same folder

**Requirements:** FFmpeg (`brew install ffmpeg`)

**Usage:**

1. Select exactly 1 MP4 file in Finder
2. Run the script

---

### Convert WMV to MP4

Converts a single WMV file to MP4 with hardware-accelerated H.264 encoding.

**What it does:**

- Takes a single selected WMV file
- Prompts for compression level: **High Quality**, **Balanced**, or **Small File**
- Encodes video with Apple's hardware encoder (`h264_videotoolbox`) using quality-based VBR (q=75 / 55 / 35)
- Re-encodes audio as AAC at 192 kbps / 160 kbps / 128 kbps (matching the chosen tier)
- Saves output as `<original>-converted_YYYYMMDD_HHMMSS.mp4` in the same folder

**Requirements:** FFmpeg (`brew install ffmpeg`)

**Usage:**

1. Select exactly 1 WMV file in Finder
2. Run the script
3. Pick a compression level when prompted

---

### Remove MP4 Audio

Removes the audio stream from a single MP4 file using FFmpeg stream copy (lossless, no re-encoding).

**What it does:**

- Takes a single selected MP4 file
- Runs FFmpeg with `-c copy -an`: copies every stream as-is and drops audio
- Finishes in seconds — no transcoding, no quality loss; video (and any subtitle/data streams) preserved unchanged
- Saves output as `<original>-muted_YYYYMMDD_HHMMSS.mp4` in the same folder

**Requirements:** FFmpeg (`brew install ffmpeg`)

**Usage:**

1. Select exactly 1 MP4 file in Finder
2. Run the script

---

### Convert M4A to MP3

Batch-converts one or more M4A audio files to MP3 using FFmpeg + LAME.

**What it does:**

- Processes one or more selected `.m4a` files
- Prompts once for a compression tier: **High Quality**, **Balanced**, or **Small File**
- Encodes audio with LAME (`libmp3lame`) at `320k` / `192k` /
  `128k` (the chosen tier applies to every file in the batch)
- Drops any embedded cover-art stream (`-vn`) so the output is audio-only
- Per-file errors don't abort the batch; a summary alert reports processed/error counts when it finishes
- Saves output as `<original>-converted_YYYYMMDD_HHMMSS.mp3` in the same folder as each source
- Shares the `-converted_` verb with the WMV→MP4 script; no collision because the extensions differ

**Requirements:** FFmpeg (`brew install ffmpeg`)

**Usage:**

1. Select one or more `.m4a` files in Finder
2. Run the script
3. Pick a compression tier when prompted

---

### Increase Image Resolution

Upscales images by 3x using Pixelmator Pro's ML Super Resolution algorithm.

**What it does:**

- Processes one or more selected image files
- Prompts only for output format (PNG / JPEG / HEIC)
- Drives Pixelmator Pro directly via its AppleScript dictionary — opens each image, applies the
  upscale, exports in the chosen format, and closes without saving
- Always calls Pixelmator Pro's dedicated `super resolution` command (which upscales by 300%)
- JPEG and HEIC export use `compression factor: 90`; PNG is lossless
- Saves output with a `-3x.<ext>` suffix (e.g., `photo.jpg` → `photo-3x.jpg`) alongside the original
- Pre-flight check aborts cleanly if Pixelmator Pro isn't installed
- Shows a summary with processed/error counts

**Supported formats:** PXD, HEIC, JPEG, JPEG 2000, PDF (single page), PNG, TIFF, WebP, GIF

**Requirements:** [Pixelmator Pro](https://www.pixelmator.com/pro/) (macOS app). No Shortcuts setup
or other intermediary needed — the script talks to Pixelmator Pro directly.

**Usage:**

1. Select one or more image files in Finder
2. Run the script
3. Pick an output format when prompted

---

## Adding Scripts to Finder (Quick Actions Tutorial)

The recommended way to use these scripts is as **Automator Quick Actions** ⚙️, which adds them to Finder's right-click
menu. This tutorial walks through the full setup.

### Prerequisites

- macOS 12 Monterey or later (tested on macOS 15 Sequoia)
- **FFmpeg** (video scripts only):
  ```bash
  brew install ffmpeg
  ```
  The scripts auto-detect FFmpeg at `/opt/homebrew/bin/ffmpeg`, `/usr/local/bin/ffmpeg`, or `/usr/bin/ffmpeg`.
- **Pixelmator Pro** (image resolution script only): Install from
  [pixelmator.com/pro](https://www.pixelmator.com/pro/) (Mac App Store and direct download links are
  on that page). Driven directly via its AppleScript dictionary — no Shortcuts setup needed.

### Step 1 — Create the Quick Action in Automator

1. Open **Automator.app** (Spotlight: `⌘ Space` → type "Automator")
2. Click **New Document** (or `⌘ N`)
3. Select **Quick Action ⚙️** as the document type and click **Choose**

### Step 2 — Configure the Workflow Input

At the top of the workflow editor, configure the input bar:

| Setting                       | Merge MP4 Videos            | Enhance MP4 Video           | Upscale MP4 Video           | Convert WMV to MP4          | Remove MP4 Audio            | Convert M4A to MP3          | Add Image Dimensions        | Increase Image Resolution   | Remove Metadata             |
|-------------------------------|-----------------------------|-----------------------------|-----------------------------|-----------------------------|-----------------------------|-----------------------------|-----------------------------|-----------------------------|-----------------------------|
| **Workflow receives current** | `files or folders`          | `files or folders`          | `files or folders`          | `files or folders`          | `files or folders`          | `files or folders`          | `files or folders`          | `files or folders`          | `files or folders`          |
| **in**                        | `Finder`                    | `Finder`                    | `Finder`                    | `Finder`                    | `Finder`                    | `Finder`                    | `Finder`                    | `Finder`                    | `Finder`                    |
| **Image** *(optional)*        | Choose an icon you like     | Choose an icon you like     | Choose an icon you like     | Choose an icon you like     | Choose an icon you like     | Choose an icon you like     | Choose an icon you like     | Choose an icon you like     | Choose an icon you like     |
| **Color** *(optional)*        | Pick a color for the action | Pick a color for the action | Pick a color for the action | Pick a color for the action | Pick a color for the action | Pick a color for the action | Pick a color for the action | Pick a color for the action | Pick a color for the action |

> **Why "files or folders" everywhere?** Only `Add image dimensions` actually consumes the Automator `input`
> parameter (it receives folders); the video scripts and the image resolution script read the Finder selection
> directly and ignore `input`. Setting all of them to `files or folders` keeps the workflow configuration
> consistent without affecting behavior.
>
> The **New text file** script isn't shown above — it uses the front Finder window's folder and doesn't read
> input or selection, so the Quick Action receives no input (set **Workflow receives** to `no input`).

### Step 3 — Add the AppleScript Action

1. In the left sidebar, search for **Run AppleScript**
2. Drag the **Run AppleScript** action into the workflow area
3. Delete the placeholder code in the script box
4. Open the `.applescript` file from this repo in a text editor and **copy the entire contents**
5. Paste into the Automator script box

### Step 4 — Save the Quick Action

1. Press `⌘ S` (or **File → Save**)
2. Enter a descriptive name:
    - `Merge MP4 Videos` for the video merge script
    - `Add Image Dimensions` for the rename script
3. Automator saves Quick Actions to `~/Library/Services/` automatically — no need to pick a location

### Step 5 — Use from Finder

The Quick Action is now available:

1. **Right-click method:**
    - Select your files or folders in Finder
    - Right-click → **Quick Actions** → your action name

2. **Finder menu method:**
    - Select your files or folders
    - **Finder** menu bar → **Services** → your action name

### Uninstalling a Quick Action

Delete the workflow file from `~/Library/Services/` (replace each filename below with the names you chose when saving in Automator).

Or open Automator, **File → Open Recent**, select the workflow, then **File → Move to Trash**.

## Development

### Syntax-check all scripts: `compile.sh`

`compile.sh` runs `osacompile -o /dev/null` against every `scripts/*.applescript` and reports pass/fail per file. It
exits non-zero if any script fails to compile, with the offending error printed inline.

```bash
./compile.sh
```

### Check external tool requirements: `check-requirements.sh`

`check-requirements.sh` is a read-only environment doctor. It probes the four external tools any script in this repo can depend on (FFmpeg, ExifTool, sips, Pixelmator Pro), then iterates
`scripts/*.applescript` and reports which scripts are ready to run on this machine. Missing deps surface as `✗ (needs: <tool>)` rows, followed by an `Install missing:` block with the exact `brew install` line (or app-install instructions for Pixelmator Pro).

```bash
./check-requirements.sh
```

Exits `0` when every script is ready (or has no deps), `1` if any is blocked. `NO_COLOR=1` strips ANSI escapes while preserving the symbols. Not wired into CI — runners lack Pixelmator Pro, so the doctor is intentionally local-only.

## Project Structure

```
compile.sh                                    Syntax-check all AppleScripts (used by CI)
check-requirements.sh                         Local env doctor: per-script readiness against installed tools
scripts/                                                                                      
```

## License

Personal utility scripts. Use at your own risk.
