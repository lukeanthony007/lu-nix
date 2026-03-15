#!/bin/sh
# Bootstrap task runner — writes JSON status to a file for the QML UI to poll.
# Downloads wallpapers one at a time via curl so each appears instantly in the picker.

STATUS_FILE="$HOME/.local/state/bootstrap-status.json"
LOG="$HOME/.local/state/bootstrap.log"
mkdir -p "$(dirname "$STATUS_FILE")"
exec > "$LOG" 2>&1
set -ux

REPO="lukeanthony007/Wallpapers"
WP_DIR="$HOME/Pictures/Wallpapers"

write_status() {
    cat > "$STATUS_FILE" << STATUSEOF
{
  "task0state": "$1", "task0desc": "$2",
  "task1state": "$3", "task1desc": "$4",
  "task2state": "$5", "task2desc": "$6",
  "progress": $7,
  "status": "$8",
  "wallpapers": [$9]
}
STATUSEOF
}

# Build wallpaper JSON list from what's on disk
wp_json_list() {
    LIST=""
    find "$WP_DIR" -type f -size +10k \( -name '*.jpg' -o -name '*.png' -o -name '*.jpeg' \) 2>/dev/null | sort -r | head -24 | while IFS= read -r f; do
        [ -n "$LIST" ] && LIST="$LIST,"
        LIST="$LIST\"$f\""
        echo "$LIST"
    done | tail -1
}

write_status "running" "Checking network..." \
             "pending" "Editor configuration" \
             "pending" "Cloud storage" \
             "0.0" "Checking network..." ""

# Quick network check
HAS_NET=false
for i in 1 2 3 4 5; do
    if ping -c1 -W1 github.com >/dev/null 2>&1; then
        HAS_NET=true
        break
    fi
    sleep 1
done
echo "[net] HAS_NET=$HAS_NET"

mkdir -p "$WP_DIR"

if [ "$HAS_NET" = true ] && [ ! -d "$WP_DIR/.git" ]; then
    rm -rf "$WP_DIR"

    write_status "running" "Fetching wallpaper index..." \
                 "pending" "Editor configuration" \
                 "pending" "Cloud storage" \
                 "0.02" "Fetching wallpaper index..." ""

    # Step 1: Tree-only clone (no file content — just directory structure)
    git clone --filter=blob:none --sparse --no-checkout --depth 1 \
        "https://github.com/$REPO.git" "$WP_DIR" 2>&1 || true
    echo "[wp] Tree cloned"

    if [ -d "$WP_DIR/.git" ]; then
        # List all folders sorted newest-first (by name convention)
        ALL_FOLDERS=$(git -C "$WP_DIR" ls-tree -d --name-only HEAD 2>/dev/null | grep -v '^\.' | sort -r) || true
        LATEST=$(echo "$ALL_FOLDERS" | head -1)
        echo "[wp] Latest folder: $LATEST"
        echo "[wp] All folders: $(echo "$ALL_FOLDERS" | wc -l)"

        if [ -n "$LATEST" ]; then
            write_status "running" "Downloading: $LATEST" \
                         "pending" "Editor configuration" \
                         "pending" "Cloud storage" \
                         "0.05" "Downloading latest wallpapers..." ""

            # Show download progress
            (while true; do
                sleep 2
                SIZE=$(du -sh "$WP_DIR" 2>/dev/null | cut -f1) || SIZE="0"
                write_status "running" "Downloading... $SIZE" \
                             "pending" "Editor configuration" \
                             "pending" "Cloud storage" \
                             "0.10" "Downloading... $SIZE" "$(wp_json_list)"
            done) &
            TICK=$!

            # Step 2: Fetch only the latest folder's files
            git -C "$WP_DIR" sparse-checkout set "$LATEST" 2>&1 || true
            git -C "$WP_DIR" checkout 2>&1 || true

            kill "$TICK" 2>/dev/null; wait "$TICK" 2>/dev/null || true
            echo "[wp] Latest folder downloaded"
        fi
    fi
fi

WP_JSON=$(wp_json_list)
SELECTED=$(find "$WP_DIR" -type f -size +10k \( -name '*.jpg' -o -name '*.png' -o -name '*.jpeg' \) 2>/dev/null | shuf -n 1) || true
echo "[wp] Found $(find "$WP_DIR" -type f -size +10k 2>/dev/null | wc -l) wallpapers, selected: $SELECTED"

# Write selected wallpaper to DMS session.json
if [ -n "$SELECTED" ]; then
    SESSION_DIR="$HOME/.local/state/DankMaterialShell"
    mkdir -p "$SESSION_DIR"
    SESSION_FILE="$SESSION_DIR/session.json"
    if [ -f "$SESSION_FILE" ]; then
        jq --arg wp "$SELECTED" '.wallpaperPath = $wp | .wallpaperPathDark = $wp | .wallpaperPathLight = $wp' \
            "$SESSION_FILE" > "$SESSION_FILE.tmp" && mv "$SESSION_FILE.tmp" "$SESSION_FILE"
    else
        jq -n --arg wp "$SELECTED" '{wallpaperPath: $wp, wallpaperPathDark: $wp, wallpaperPathLight: $wp}' > "$SESSION_FILE"
    fi
    echo "[wp] Pre-selected wallpaper: $SELECTED"
fi

DESC1="No wallpapers found"
[ -n "$SELECTED" ] && DESC1="Wallpapers ready"
[ "$HAS_NET" = false ] && [ -z "$SELECTED" ] && DESC1="No network"

write_status "done" "$DESC1" \
             "running" "Checking editor..." \
             "pending" "Cloud storage" \
             "0.33" "Checking editor..." "$WP_JSON"

sleep 1

# Step 2: NvChad
NVIM_DIR="$HOME/.config/nvim"
if [ "$HAS_NET" = true ] && [ ! -d "$NVIM_DIR/.git" ]; then
    rm -rf "$NVIM_DIR"
    git clone --depth 1 https://github.com/NvChad/starter "$NVIM_DIR" 2>&1 || true
fi

DESC2="NvChad ready"
[ ! -d "$NVIM_DIR/.git" ] && DESC2="Will install later"

write_status "done" "$DESC1" \
             "done" "$DESC2" \
             "running" "Cloud storage..." \
             "0.66" "Cloud storage..." "$WP_JSON"

sleep 1

# Step 3: Cloud provider selection
if [ -f "$HOME/.config/rclone/rclone.conf" ]; then
    write_status "done" "$DESC1" \
                 "done" "$DESC2" \
                 "done" "Cloud storage configured" \
                 "1.0" "done" "$WP_JSON"
else
    write_status "done" "$DESC1" \
                 "done" "$DESC2" \
                 "cloud" "Choose a provider" \
                 "0.66" "cloud" "$WP_JSON"
fi

echo "[done] bootstrap.sh finished"
