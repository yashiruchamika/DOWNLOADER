big-files-keep-continue-download
================================

Small, focused Bash script to reliably download large files and media using yt-dlp + aria2. It detects YouTube-style URLs (and other sites supported by yt-dlp), offers convenient format choices, uses aria2 as an external segmented downloader when available, and uses aria2 directly for plain direct-URL downloads with resume, retries and sane defaults.

Prerequisites
- bash (POSIX-compatible shell)
- yt-dlp
- aria2 (optional but recommended for speed/resume)
- coreutils (mkdir, basename, etc.)

Install
- Debian/Ubuntu:
  sudo apt update
  sudo apt install -y aria2 yt-dlp
  or
  pip install -U yt-dlp
- macOS (Homebrew):
  brew install aria2 yt-dlp
- Windows: use WSL or adapt script to PowerShell; install aria2 & yt-dlp separately.

Files
- download.sh — main script (your provided script)

Quick usage
- Make executable:
  chmod +x download.sh
- Run:
  ./download.sh URL [OUTPUT_DIR]

Behavior summary
- If the URL looks like YouTube (youtube.com or youtu.be) the script:
  - Prompts for format: mp4, mp3, best, audio-best, or custom yt-dlp format string.
  - Uses yt-dlp to download and resume (yt-dlp --continue).
  - If aria2c is installed, passes aria2 as --external-downloader with segmented options for faster downloads.
  - Saves output to OUTDIR with template: "%(title)s.%(ext)s".
- For non-YouTube URLs the script:
  - Prompts for output filename (defaults to basename of URL).
  - Uses aria2c directly with resume, many connections/splits, infinite retries and conservative timeouts.

Defaults & important aria2 options used
- --continue=true — resume partial downloads
- --split=32, --max-connection-per-server=16 — segmented parallel downloads (adjust for server politeness)
- --min-split-size=1M — avoid too-small segments
- --max-tries=0 — infinite retries (change if you prefer a limit)
- --retry-wait=5, --timeout=60 — retry/backoff behavior
- --auto-file-renaming=false — keep filenames stable so .aria2 control files match
- --file-allocation=none — faster start (change to prealloc if you worry about disk space)

Examples
- Download a YouTube video to current directory (choose format interactively):
  ./download.sh "https://youtu.be/VIDEO_ID"
- Download a direct large file to /data:
  ./download.sh "https://example.com/large.iso" /data
  (When prompted, accept suggested filename or type a new one.)

Troubleshooting
- aria2 starts a fresh download instead of resuming:
  - Ensure the .aria2 control file (filename.aria2) is in the same directory as the partial file and aria2 is run with the same --out name.
  - Confirm --auto-file-renaming=false so aria2 doesn't create alternate filenames.
- yt-dlp fails to extract:
  - Update yt-dlp: pip install -U yt-dlp
  - Some sites need cookies or authentication: use yt-dlp options like --cookies or --username/--password.
- Very slow or banned by server:
  - Reduce --split and --max-connection-per-server, or add --max-overall-download-limit.
- Low disk space or fragmentation:
  - Use aria2's file-allocation=none for speed, or file-allocation=trunc/prealloc to reserve space.

Suggested improvements (optional)
- Save a small downloads.json index (source URL, output path, aria2 control path, status, checksums).
- Add checksum verification (sha256sum) after completion.
- Add cookie/auth handling for private or rate-limited sites.
- Support batch mode (non-interactive) with flags: --format, --out, --non-interactive.
- Add Windows PowerShell equivalent and systemd/cron wrapper for background runs.
- Detect and preserve partially-downloaded filenames when moving between machines (move .aria2 too).

Security & ethics
- Respect website terms-of-service and copyright. Download only content you are authorized to.

#yt-dlp - https://github.com/yt-dlp/yt-dlp
#aria2 -https://aria2.github.io/