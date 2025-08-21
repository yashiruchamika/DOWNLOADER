#!/usr/bin/env bash
set -euo pipefail

# Usage: ./download.sh URL [OUTPUT_DIR]
URL="${1:-}"
OUTDIR="${2:-.}"

if [[ -z "$URL" ]]; then
  echo "Usage: $0 URL [OUTPUT_DIR]"
  exit 2
fi

mkdir -p "$OUTDIR"

# Simple YouTube detection (yt-dlp supports many sites; adjust as needed)
is_youtube=false
if [[ "$URL" =~ (^https?://)?(www\.)?(youtube\.com|youtu\.be)/ ]]; then
  is_youtube=true
fi

if $is_youtube; then
  # Ask user for format
  echo "Detected YouTube URL."
  echo "Choose format:"
  echo "  1) mp4 (video + audio)"
  echo "  2) mp3 (audio only)"
  echo "  3) best (best available video+audio)"
  echo "  4) audio-best (best audio in original format)"
  echo "  5) custom (enter yt-dlp format string)"
  read -rp "Enter choice [1-5]: " choice

  case "$choice" in
    1)
      fmt="mp4"
      ytdlp_opts=( -f "bestvideo[ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]/best" --merge-output-format mp4 )
      ;;
    2)
      fmt="mp3"
      ytdlp_opts=( -x --audio-format mp3 --audio-quality 0 )
      ;;
    3)
      fmt="best"
      ytdlp_opts=( -f "best" )
      ;;
    4)
      fmt="audio-best"
      ytdlp_opts=( -f "bestaudio" )
      ;;
    5)
      read -rp "Enter yt-dlp format string (example: bestvideo[height<=1080]+bestaudio): " fmtstr
      ytdlp_opts=( -f "$fmtstr" )
      ;;
    *)
      echo "Invalid choice"; exit 3
      ;;
  esac

  # Common yt-dlp options for large downloads and resume
  ytdlp_common=(
    --no-mtime                  # don't set file mtime from metadata
    -o "$OUTDIR/%(title)s.%(ext)s"
    --progress                  # console progress
    --continue                  # resume
    --newline                   # keep progress lines clean
    --no-overwrites
  )

  # Use aria2c as external downloader for HTTP(S) fragments
  if command -v aria2c >/dev/null 2>&1; then
    ytdlp_common+=( --external-downloader aria2c --external-downloader-args "-x16 -s16 -k1M --allow-overwrite=false --continue=true" )
  fi

  echo "Starting yt-dlp ($fmt)..."
  yt-dlp "${ytdlp_common[@]}" "${ytdlp_opts[@]}" "$URL"

  echo "Done."

else
  # Non-YouTube: use aria2c with resume and retries
  OUTFILE="$(basename "${URL%%\?*}")"
  if [[ -z "$OUTFILE" || "$OUTFILE" == "/" ]]; then
    OUTFILE="download.file"
  fi

  read -rp "Output filename [$OUTFILE]: " user_out
  OUTFILE="${user_out:-$OUTFILE}"

  echo "Starting aria2c download..."
  aria2c \
    --dir="$OUTDIR" \
    --out="$OUTFILE" \
    --continue=true \
    --max-connection-per-server=16 \
    --split=32 \
    --min-split-size=1M \
    --max-tries=0 \
    --retry-wait=5 \
    --timeout=60 \
    --enable-http-keep-alive=true \
    --auto-file-renaming=false \
    --file-allocation=none \
    --summary-interval=10 \
    --log-level=notice \
    "$URL"

  echo "Done."
fi
