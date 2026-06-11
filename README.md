# AppleScripts

A collection of macOS AppleScript utilities that automate Finder file tasks — video processing, image batch operations, and quick file creation. Each script runs as an Automator Quick Action (right-click menu).

## Scripts

### Merge MP4 Videos

Concatenates 2 or more MP4 files into a single video with motion-interpolated frame blending.

**What it does:**

- Sorts selected MP4 files by creation date
- Merges them using FFmpeg's concat demuxer
- Applies frame interpolation to 60 fps (`minterpolate` with bidirectional motion estimation)
- Encodes with Apple's hardware encoder (`h264_videotoolbox`) at 10 Mbps
- Re-encodes audio as AAC at 192 kbps.
- Saves output as `<first-selected>-merged_YYYYMMDD_HHMMSS.mp4` in the same folder as the first file (the first-selected file's basename anchors both the output folder and the merged filename, so the result sorts next to it in Finder).

**Requirements:** FFmpeg (`brew install ffmpeg`)

**Usage:**

1. Select 2+ MP4 files in Finder
2. Run the script

---

### Crossfade MP4 Videos

Blends two MP4 clips into a single video with a smooth crossfade — the first clip dissolves into the
second over a duration you choose — using FFmpeg's `xfade` (video) and `acrossfade` (audio) filters.

**What it does:**

- Takes exactly 2 selected MP4 files and orders them by creation date (the older clip plays first)
- Probes each clip's duration with `ffprobe` to place the transition correctly
- Prompts for a crossfade duration in seconds (default `1`); accepts a comma or period decimal and
  rejects values that don't fit inside both clips
- Crossfades the video with `xfade=transition=fade` — the transition starts `clip1 duration − fade`
  seconds in, so it ends exactly at the first clip's end — and the audio with `acrossfade`
  (triangular fade curves)
- Encodes with software `libx264 -crf 18` (near-lossless, quality-first — a short crossfade isn't
  speed-bound, and software encoding avoids the banding hardware encoders add to a fade), plus
  `-pix_fmt yuv420p` so the result plays everywhere, including QuickTime, Safari, and Photos
- Re-encodes audio as AAC at 128 kbps
- Saves output as `<older-clip>-crossfaded_YYYYMMDD_HHMMSS.mp4` in the same folder as the first clip

**Requirements:** FFmpeg (`brew install ffmpeg`) — `ffprobe` is bundled with FFmpeg, so no separate
install needed

> **Note:** Both clips should share the same resolution, frame rate, and pixel format (the `xfade`
> filter requires it), and each must contain an audio stream. A mismatch surfaces as an FFmpeg error
> dialog rather than a broken file.

**Usage:**

1. Select exactly 2 MP4 files in Finder
2. Run the script
3. Enter a crossfade duration when prompted (or accept the default of 1 second)

---

### Add Image Dimensions

Batch-renames image files to include their pixel dimensions. Accepts folders, individual image
files, or any mix of the two.

**What it does:**

- Per item in the selection, branches on type: folders are expanded to their image children,
  files are processed directly
- Appends `-WIDTHw-HEIGHTh` before the file extension (e.g., `photo.jpg` becomes `photo-1920w-1080h.jpg`)
- Skips files that already have the dimension tag
- Summary header adapts to the selection: folders only, files only, or mixed (`Processed N folders, M files`)

**Supported formats:** jpg, jpeg, png, gif, heic, heif, webp, bmp, tiff, tif.

**Requirements:** None (uses macOS built-in `sips`)

**Usage:**

1. Install as a Quick Action (see [Quick Actions Tutorial](#adding-scripts-to-finder-quick-actions-tutorial) below)
2. Select one or more folders containing images, individual image files, or both in Finder
3. Right-click → **Quick Actions** → your action name

---

### Interpolate MP4 Video

Applies frame interpolation and hardware-accelerated re-encoding to one or more MP4 files,
with user-chosen encoder and target FPS.

**What it does:**

- Processes one or more selected `.mp4` files
- Prompts once per batch for an **encoder**: **H.264** (default, universal compatibility) or
  **HEVC** (smaller files, Apple / modern-web playback)
- Prompts once per batch for a **target FPS**: **30** or **60** (default)
- Per-file pre-flight via `ffprobe`: if a source is already ≥ `targetFps − 0.5` (covers the exact
  target and NTSC variants like 59.94), silently skips that file — interpolation would have
  nothing to add
- Applies frame interpolation to the chosen target FPS (`minterpolate` with bidirectional motion estimation)
- **H.264**: encodes with Apple's hardware encoder (`h264_videotoolbox`) at 10 Mbps CBR and
  re-encodes audio as AAC at 192 kbps
- **HEVC**: encodes with Apple's hardware encoder (`hevc_videotoolbox`) in 10-bit `main10` profile
  (CQ 80), tags as `hvc1` for Apple-platform compatibility, and copies the audio stream losslessly
  (no re-encode)
- Per-file errors don't abort the batch; a summary alert reports processed / skipped / error counts
  (and the codec + FPS labels used) when it finishes
- Saves output as `<original>-interpolated_YYYYMMDD_HHMMSS.mp4` in the same folder as each source

**Requirements:** FFmpeg (`brew install ffmpeg`) — `ffprobe` is bundled with FFmpeg, so no
separate install needed

**Usage:**

1. Select one or more `.mp4` files in Finder
2. Run the script
3. Pick an encoder, then a target FPS when prompted

---

### Upscale MP4 Video

Doubles the resolution of one or more MP4 files (2x width, 2x height) using FFmpeg with the lanczos
resampler and hardware-accelerated H.264 encoding.

**What it does:**

- Processes one or more selected `.mp4` files
- Applies a spatial upscale to 2x width and 2x height with FFmpeg's `lanczos` resampler — sharper than the default bicubic, the standard pick for video enlargement
- Encodes with Apple's hardware encoder (`h264_videotoolbox`) at 20 Mbps (twice the Interpolate/Merge bitrate to accommodate the quadrupled pixel count)
- Copies the audio stream losslessly (no re-encoding)
- Per-file errors don't abort the batch; a summary alert reports processed/error counts when it finishes
- Saves output as `<original>-upscaled_YYYYMMDD_HHMMSS.mp4` in the same folder as each source

**Requirements:** FFmpeg (`brew install ffmpeg`)

**Usage:**

1. Select one or more MP4 files in Finder
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
- Runs FFmpeg with `-c copy -an`: drops the audio and stream-copies the rest (no re-encoding)
- Finishes in seconds — no transcoding, no quality loss; the video is preserved unchanged. A
  timecode/data track (as in iPhone clips) rides along, but subtitle tracks are not carried
- Saves output as `<original>-muted_YYYYMMDD_HHMMSS.mp4` in the same folder

**Requirements:** FFmpeg (`brew install ffmpeg`)

**Usage:**

1. Select exactly 1 MP4 file in Finder
2. Run the script

---

### Extract Last MP4 Frame

Saves the final frame of one or more MP4 videos as a JPEG using FFmpeg.

**What it does:**

- Processes one or more selected `.mp4` files
- Seeks to 1 second before the end (`-sseof -1`) and writes every remaining frame to the same
  output file (`-update 1`), so the clip's true last frame is the one that survives — a single
  tail-only decode pass, with no frame-counting arithmetic (and none of the off-by-one risk of
  selecting by frame index, which is 0-based while the frame count is not)
- Encodes the still as a near-lossless JPEG (`-q:v 2`)
- Per-file errors don't abort the batch; a summary alert reports processed/error counts when it finishes
- Saves output as `<original>-lastframe_YYYYMMDD_HHMMSS.jpg` in the same folder as each source

**Requirements:** FFmpeg (`brew install ffmpeg`)

**Usage:**

1. Select one or more MP4 files in Finder
2. Run the script

---

### Convert M4A to MP3

Batch-converts one or more M4A audio files to MP3 using FFmpeg + LAME.

**What it does:**

- Processes one or more selected `.m4a` files
- Prompts once for a compression tier: **High Quality**, **Balanced**, **Small File**, or **Tiny File**
- Encodes audio with LAME (`libmp3lame`) at `320k` / `192k` / `128k` / `64k` (the chosen tier
  applies to every file in the batch)
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

### Change MP3 bitrate

Re-encodes one or more existing MP3 files at a user-chosen bitrate using FFmpeg + LAME.

**What it does:**

- Processes one or more selected `.mp3` files
- Prompts once for a bitrate tier: **320k - High Quality**, **192k - Balanced**, **128k - Small
  File**, or **64k mono - Tiny (voice only)** (the chosen tier applies to every file in the batch)
- Encodes with LAME (`libmp3lame`); the 64k tier also downmixes to mono at 22.05 kHz so output stays voice-sized rather than music-sized
- Drops any embedded cover-art stream (`-vn`) so the output is audio-only
- Per-file errors don't abort the batch; a summary alert reports processed/error counts when it finishes
- Saves output as `<original>-<bitrate>_YYYYMMDD_HHMMSS.mp3` in the same folder as each source
  (bitrate label = `320k` / `192k` / `128k` / `64k-mono`), so re-runs at different tiers don't collide

**Requirements:** FFmpeg (`brew install ffmpeg`)

**Usage:**

1. Select one or more `.mp3` files in Finder
2. Run the script
3. Pick a bitrate tier when prompted

---

### Upscale Image

Upscales images by 3x using Pixelmator Pro's ML Super Resolution algorithm.

**What it does:**

- Processes one or more selected image files
- Prompts only for output format — 4 options: **PNG (lossless)**, **JPEG (quality 90)**,
  **JPEG (quality 80)**, **HEIC (quality 90)**
- Drives Pixelmator Pro directly via its AppleScript dictionary — opens each image, applies the
  upscale, exports in the chosen format, and closes without saving
- Always calls Pixelmator Pro's dedicated `super resolution` command (which upscales by 300%)
- PNG is lossless; JPEG exports at the chosen quality (90 or 80); HEIC uses `compression factor: 90`
- Saves output with a `-3x.<ext>` suffix (e.g., `photo.jpg` → `photo-3x.jpg`) alongside the original
- Pre-flight check aborts cleanly if Pixelmator Pro isn't installed
- Auto-quits Pixelmator Pro at the end if it wasn't already running when the script started
- Shows a summary with processed/error counts

**Supported formats:** PXD, HEIC, JPEG, JPEG 2000, PDF (single page), PNG, TIFF, WebP, GIF

**Requirements:** [Pixelmator Pro](https://www.pixelmator.com/pro/) (macOS app). No Shortcuts setup or other intermediary needed — the script talks to Pixelmator Pro directly.

**Usage:**

1. Select one or more image files in Finder
2. Run the script
3. Pick an output format when prompted

---

### Clarify Media

Applies Pixelmator Pro's clarity adjustment to one or more images or MP4 videos at a user-chosen intensity (-100 to 100, default 20).

**What it does:**

- Processes one or more selected images or MP4 videos
- Prompts once for clarity intensity (-100 to 100, default 20); aborts on Cancel or out-of-range input
- Drives Pixelmator Pro directly via its AppleScript dictionary — opens each file, sets
  `clarity` to the chosen intensity on the first layer's color adjustments, exports in the
  source format, and closes without saving
- Output format matches input (no format prompt); JPEG/HEIC/WebP/JPEG 2000 export at
  `compression factor: 90`, PNG/TIFF/GIF are lossless; MP4 video is re-encoded to MP4
- Saves output as `<original>-clarified.<same-ext>` alongside each source. No timestamp in the
  suffix — re-running on the same file overwrites the previous output
- Pre-flight check aborts cleanly if Pixelmator Pro isn't installed
- Auto-quits Pixelmator Pro at the end if it wasn't already running when the script started
- Shows a summary with processed/error counts

**Supported formats:** HEIC, JPEG, JPEG 2000, PNG, TIFF, WebP, GIF, MP4

**Requirements:** [Pixelmator Pro](https://www.pixelmator.com/pro/)

**Usage:**

1. Select one or more images or MP4 videos in Finder
2. Run the script
3. Enter clarity intensity when prompted (or accept the default of 20)

---

### Texturize Media

Adds texture to one or more images or MP4 videos using Pixelmator Pro's texture adjustment at a user-chosen intensity (-100 to 100, default 20).

**What it does:**

- Processes one or more selected images or MP4 videos
- Prompts once for texture intensity (-100 to 100, default 20); aborts on Cancel or out-of-range input
- Drives Pixelmator Pro directly via its AppleScript dictionary — opens each file, sets
  `texture` to the chosen intensity on the first layer's color adjustments, exports in the source format, and
  closes without saving
- Output format matches input (no format prompt); JPEG/HEIC/WebP/JPEG 2000 export at
  `compression factor: 90`, PNG/TIFF/GIF are lossless; MP4 video is re-encoded to MP4
- Saves output as `<original>-textured.<same-ext>` alongside each source. No timestamp in the
  suffix — re-running on the same file overwrites the previous output
- Pre-flight check aborts cleanly if Pixelmator Pro isn't installed
- Auto-quits Pixelmator Pro at the end if it wasn't already running when the script started
- Shows a summary with processed/error counts

**Supported formats:** HEIC, JPEG, JPEG 2000, PNG, TIFF, WebP, GIF, MP4

**Requirements:** [Pixelmator Pro](https://www.pixelmator.com/pro/)

**Usage:**

1. Select one or more images or MP4 videos in Finder
2. Run the script

---

### Remove Metadata

Strips identifying metadata from selected video and image files.

**What it does:**

- Accepts a mixed Finder selection of videos (`.mp4`, `.mov`) and images
- For **videos**: runs FFmpeg with `-map_metadata -1 -map_chapters -1 -c copy` — lossless
  stream copy that drops the container's metadata atoms and chapter markers without re-encoding
- For **images**: runs ExifTool with `-all= --icc_profile:all -tagsfromfile @ -orientation` —
  deletes every metadata group (EXIF, IPTC, XMP, GPS, MakerNotes, Photoshop IRBs, …) while
  preserving the ICC color profile (excluded from the wipe) and copying the EXIF Orientation tag
  back from the source, so the stripped output renders identically to the source (no color shift,
  no unintended rotation on phone-camera photos)
- Per-file errors don't abort the batch; a summary alert reports processed / error / skipped
  counts when it finishes
- If exactly one of the two tools is missing, the other file class is still processed and the
  missing-tool count appears in the summary (with the install hint). If both are missing,
  aborts up-front before touching any file
- Saves output as `<original>-nometa_YYYYMMDD_HHMMSS.<ext>` in the same folder as each source.
  All outputs in a single batch share the same timestamp so they sort together in Finder

**Supported formats:**

- Videos: `.mp4`, `.mov`
- Images: `.jpg`, `.jpeg`, `.png`, `.gif`, `.heic`, `.heif`, `.webp`, `.bmp`, `.tiff`, `.tif`

**Requirements:** FFmpeg (`brew install ffmpeg`) AND ExifTool (`brew install exiftool`)

**Usage:**

1. Select one or more supported files in Finder (mixing videos and images is fine)
2. Run the script

---

### View Metadata

Writes a human-readable metadata dump as a `.txt` sidecar next to each selected video or image
file. Conceptual pair to Remove Metadata — anything that script strips, this one shows you first.

**What it does:**

- Accepts a mixed Finder selection of videos (`.mp4`, `.mov`) and images
- Runs a single ExifTool call per file with `-G1 -a -s` (group-prefixed, dedupe-disabled, short
  tag names) for all classes — no per-tool dispatch
- Each sidecar starts with a 3-line header (`# Metadata for`, `# Source`, `# Generated`), a blank line, then the full ExifTool dump
- Per-file errors don't abort the batch; a summary alert reports processed / error / skipped
  counts when it finishes
- Aborts up-front if ExifTool is missing (no fallback)
- Saves output as `<original>-metadata_YYYYMMDD_HHMMSS.txt` in the same folder as each source —
  always `.txt`, regardless of source extension. All sidecars in a single batch share the same
  timestamp so they sort together in Finder

**Supported formats:**

- Videos: `.mp4`, `.mov`
- Images: `.jpg`, `.jpeg`, `.png`, `.gif`, `.heic`, `.heif`, `.webp`, `.bmp`, `.tiff`, `.tif`

**Requirements:** ExifTool (`brew install exiftool`)

**Usage:**

1. Select one or more supported files in Finder (mixing videos and images is fine)
2. Run the script

---

### New file

Creates a new file in the active Finder window's folder with a user-chosen name and type.

**What it does:**

- Reads the front Finder window's target folder (falls back to `~/Downloads` if no Finder window is open)
- Prompts for a file name (defaults to `untitled` — empty input also falls back to the default)
- Prompts for a file type via a select widget with 10 options: **Text (.txt)**, **Markdown (.md)**,
  **Rich Text (.rtf)**, **HTML (.html)**, **CSS (.css)**, **JSON (.json)**, **XML (.xml)**,
  **CSV (.csv)**, **YAML (.yml)**, **Shell script (.sh)**
- If the typed name already includes one of those 10 extensions, it's stripped before the picker's extension is appended — the picker always wins.
- On name collision, appends ` 2`, ` 3`, … until unique (e.g., `notes.md`, `notes 2.md`, …)
- Selects the new file in Finder so it's ready to rename or edit

**Requirements:** None (built-in Finder scripting)

**Usage:**

1. Bring the destination folder forward in Finder (optional — falls back to Downloads)
2. Run the script
3. Enter a name (or accept `untitled`), then pick a file type

---

## Adding Scripts to Finder (Quick Actions Tutorial)

The recommended way to use these scripts is as **Automator Quick Actions** ⚙️, which adds them to Finder's right-click menu. This tutorial walks through the full setup.

### Prerequisites

- macOS 12 Monterey or later (tested on macOS 15 Sequoia)
- **FFmpeg** (video and audio scripts):
  ```bash
  brew install ffmpeg
  ```
  Used by the MP4/WMV/M4A/MP3 scripts and the video half of Remove Metadata. Auto-detected at
  `/opt/homebrew/bin/ffmpeg`, `/usr/local/bin/ffmpeg`, or `/usr/bin/ffmpeg`.
- **ExifTool** (metadata scripts):
  ```bash
  brew install exiftool
  ```
  Used by View Metadata (all supported files) and the image half of Remove Metadata. Auto-detected at `/opt/homebrew/bin/exiftool`, `/usr/local/bin/exiftool`, or `/usr/bin/exiftool`.
- **Pixelmator Pro** (Upscale Image, Clarify Media, Texturize Media): Install from
  [pixelmator.com/pro](https://www.pixelmator.com/pro/) (Mac App Store and direct download links are on that page). Driven directly via its AppleScript dictionary — no Shortcuts setup needed.
- **sips** is bundled with macOS — no install needed (used by Add Image Dimensions).

### Step 1 — Create the Quick Action in Automator

1. Open **Automator.app** (Spotlight: `⌘ Space` → type "Automator")
2. Click **New Document** (or `⌘ N`)
3. Select **Quick Action ⚙️** as the document type and click **Choose**

### Step 2 — Configure the Workflow Input

At the top of the workflow editor, configure the input bar. The same settings apply to every script **except `New file`** (see note below):

| Setting                       | Value                       |
|-------------------------------|-----------------------------|
| **Workflow receives current** | `files or folders`          |
| **in**                        | `Finder`                    |
| **Image** *(optional)*        | Choose an icon you like     |
| **Color** *(optional)*        | Pick a color for the action |

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

Delete the workflow file from `~/Library/Services/`.

## Development

### Syntax-check all scripts: `compile.sh`

`compile.sh` runs `osacompile -o /dev/null` against every `scripts/*.applescript` and reports pass/fail per file. It exits non-zero if any script fails to compile, with the offending error printed inline.

```bash
./compile.sh
```

### Check external tool requirements: `check-requirements.sh`

`check-requirements.sh` is a read-only environment doctor. It probes the four external tools any
script in this repo can depend on (FFmpeg, ExifTool, sips, Pixelmator Pro), then iterates
`scripts/*.applescript` and reports which scripts are ready to run on this machine. Missing deps
surface as `✗ (needs: <tool>)` rows, followed by an `Install missing:` block with the exact
`brew install` line (or app-install instructions for Pixelmator Pro).

```bash
./check-requirements.sh
```

Exits `0` when every script is ready (or has no deps), `1` if any is blocked. `NO_COLOR=1` strips ANSI escapes while preserving the symbols. Not wired into CI — runners lack Pixelmator Pro, so the doctor is intentionally local-only.


## Security

To report a vulnerability, see [SECURITY.md](SECURITY.md). The scripts shell out to local tools
(FFmpeg, ExifTool, sips, Pixelmator Pro), make no network requests, read no credentials, and
operate only on user-selected files in Finder.

## License

[MIT](LICENSE) © 2026 Rodrigo Troy. Personal utility scripts — use at your own risk.
