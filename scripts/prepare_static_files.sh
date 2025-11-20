#!/usr/bin/env bash
set -euo pipefail

# Prepare static files for GitHub Pages deployment:
# - Generate sitemap.xml with lastmod based on git history
# - Copy robots.txt, icon files from public/ to pwa/dist/
# Avoids updating lastmod when the current HEAD commit does not touch site content.

mkdir -p ./pwa/dist

# Default fallback: current UTC date
DEFAULT_DATE=$(date -u +%Y-%m-%d)
TODAY="$DEFAULT_DATE"

# Paths considered part of the site content. Adjust as needed.
WATCH_GLOB='^(pwa/|app/|public/|config/locales/)'

should_generate=1

if git rev-parse --git-dir >/dev/null 2>&1; then
  # Determine if the current HEAD commit touched any of the watched paths.
  # If there is a parent commit, compare HEAD^..HEAD; otherwise, list files in HEAD.
  if git rev-parse HEAD^ >/dev/null 2>&1; then
    CHANGED=$(git diff --name-only HEAD^ HEAD -- pwa/ app/ public/ config/locales || true)
  else
    CHANGED=$(git ls-tree -r --name-only HEAD | grep -E "$WATCH_GLOB" || true)
  fi

  if [ -z "$CHANGED" ]; then
    # No content changes in this HEAD commit. Prefer to reuse existing public/sitemap.xml
    # so lastmod does not get bumped by unrelated commits (eg. Dependabot).
    if [ -f public/sitemap.xml ]; then
      cp public/sitemap.xml ./pwa/dist/sitemap.xml
      if [ -f public/robots.txt ]; then
        cp public/robots.txt ./pwa/dist/robots.txt
      fi
      exit 0
    fi
    # If no public sitemap exists, we will fall back to computing lastmod from git history.
  fi

  # Compute most recent commit that touched any watched path (for lastmod)
  LAST_COMMIT_ISO=$(git log -1 --format=%cI -- pwa/ app/ public/ config/locales || true)
  if [ -n "${LAST_COMMIT_ISO:-}" ]; then
    # On Ubuntu (CI) we can use GNU date -d; on macOS fallback to python3 parsing if available.
    if date -u -d "$LAST_COMMIT_ISO" +%Y-%m-%d >/dev/null 2>&1; then
      TODAY=$(date -u -d "$LAST_COMMIT_ISO" +%Y-%m-%d)
    else
      if command -v python3 >/dev/null 2>&1; then
        TODAY=$(python3 - <<PY
from datetime import datetime
import sys
iso = sys.argv[1]
dt = datetime.fromisoformat(iso)
print(dt.date().isoformat())
PY
 "$LAST_COMMIT_ISO" 2>/dev/null || echo "$DEFAULT_DATE")
      else
        TODAY="$DEFAULT_DATE"
      fi
    fi
  fi
fi

# Write minimal sitemap with the computed date
cat > ./pwa/dist/sitemap.xml <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
  <url>
    <loc>https://aim2bpg.github.io/rubree/</loc>
    <lastmod>${TODAY}</lastmod>
  </url>
</urlset>
EOF

# Copy robots if present
if [ -f public/robots.txt ]; then
  cp public/robots.txt ./pwa/dist/robots.txt
fi

# Generate and copy icons
# If ImageMagick `convert` is available and `public/icon.png` exists, generate multiple sizes.
if [ -f public/icon.png ]; then
  mkdir -p public/icons
  if command -v convert >/dev/null 2>&1; then
    echo "[prepare_static_files] Generating favicon PNGs from public/icon.png"
    sizes=(16 32 96 192 512 180)
    for s in "${sizes[@]}"; do
      out=public/icons/favicon-${s}x${s}.png
      convert public/icon.png -resize ${s}x${s} "$out" || true
    done
    # Create multi-resolution ICO (best-effort)
    if [ -f public/icons/favicon-16x16.png ] || [ -f public/icons/favicon-32x32.png ]; then
      echo "[prepare_static_files] Creating favicon.ico"
      convert public/icons/favicon-16x16.png public/icons/favicon-32x32.png public/icons/favicon-96x96.png public/icons/favicon.ico || true
    fi
  else
    echo "[prepare_static_files] ImageMagick 'convert' not found; skipping PNG generation"
  fi
fi

# Copy any icons from public/ (including icon.svg, icon.png, and generated icons)
if [ -f public/icon.svg ]; then
  cp public/icon.svg ./pwa/dist/icon.svg
fi
if [ -f public/icon.png ]; then
  cp public/icon.png ./pwa/dist/icon.png
fi

if [ -d public/icons ]; then
  mkdir -p ./pwa/dist/icons
  cp public/icons/* ./pwa/dist/icons/ || true
fi

# Copy web app manifest from pwa/ if present so it is deployed
if [ -f pwa/manifest.json ]; then
  cp pwa/manifest.json ./pwa/dist/manifest.json
fi

exit 0
