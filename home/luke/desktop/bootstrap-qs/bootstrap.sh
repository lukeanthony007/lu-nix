#!/bin/sh
# Bootstrap task runner — writes JSON status to a file for the QML UI to poll.
# Downloads wallpapers one at a time; moves on after first one lands.

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
    find "$WP_DIR" -type f -size +10k \( -iname '*.jpg' -o -iname '*.png' -o -iname '*.jpeg' -o -iname '*.webp' \) 2>/dev/null | sort | head -24 | awk '{
        if (NR > 1) printf ","
        gsub(/"/, "\\\"")
        printf "\"%s\"", $0
    }'
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

    # Tree-only clone (no file content — just directory structure)
    git clone --filter=blob:none --sparse --no-checkout --depth 1 \
        "https://github.com/$REPO.git" "$WP_DIR" 2>&1 || true
    echo "[wp] Tree cloned"

    if [ -d "$WP_DIR/.git" ]; then
        ALL_FOLDERS=$(git -C "$WP_DIR" ls-tree -d --name-only HEAD 2>/dev/null | grep -v '^\.' | sort -r) || true
        LATEST=$(echo "$ALL_FOLDERS" | head -1)
        echo "[wp] Latest folder: $LATEST"

        if [ -n "$LATEST" ]; then
            TOTAL_FILES=$(git -C "$WP_DIR" ls-tree --name-only HEAD "$LATEST/" 2>/dev/null | grep -ciE '\.(jpg|png|jpeg|webp)$') || TOTAL_FILES=1
            echo "[wp] Expected files: $TOTAL_FILES"

            write_status "running" "Downloading wallpapers..." \
                         "pending" "Editor configuration" \
                         "pending" "Cloud storage" \
                         "0.05" "Downloading wallpapers..." ""

            # Download wallpapers one at a time in background (continues after we move on)
            (git -C "$WP_DIR" ls-tree --name-only HEAD "$LATEST/" 2>/dev/null | grep -iE '\.(jpg|png|jpeg|webp)$' | sort | while IFS= read -r f; do
                git -C "$WP_DIR" checkout HEAD -- "$f" 2>&1 || continue
                echo "[wp] Downloaded: $f"
            done
            echo "[wp] All wallpapers downloaded") &
            DL_PID=$!

            # Wait for FIRST wallpaper to land (max 60s), then move on immediately
            echo "[wp] Waiting for first wallpaper..."
            for i in $(seq 1 60); do
                FIRST=$(find "$WP_DIR" -type f -size +10k \( -iname '*.jpg' -o -iname '*.png' -o -iname '*.jpeg' -o -iname '*.webp' \) 2>/dev/null | head -1)
                if [ -n "$FIRST" ]; then
                    echo "[wp] First wallpaper ready: $FIRST"
                    break
                fi
                sleep 1
            done

            # Background ticker keeps updating wallpaper list for the picker screen
            (while kill -0 "$DL_PID" 2>/dev/null; do
                sleep 2
                DL=$(find "$WP_DIR" -type f -size +10k \( -iname '*.jpg' -o -iname '*.png' -o -iname '*.jpeg' -o -iname '*.webp' \) 2>/dev/null | wc -l) || DL=0
                # Update ONLY the wallpapers array in the status file (preserve other fields)
                WP_LIST=$(wp_json_list)
                sed -i "s|\"wallpapers\": \[.*\]|\"wallpapers\": [$WP_LIST]|" "$STATUS_FILE" 2>/dev/null || true
            done
            echo "[wp] Ticker stopped") &
        fi
    fi
fi

# Select random wallpaper from what's available now
SELECTED=$(find "$WP_DIR" -type f -size +10k \( -iname '*.jpg' -o -iname '*.png' -o -iname '*.jpeg' -o -iname '*.webp' \) 2>/dev/null | shuf -n 1) || true
echo "[wp] Selected: $SELECTED"

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
fi

WP_JSON=$(wp_json_list)
DESC1="Wallpapers ready"
[ -z "$SELECTED" ] && DESC1="No wallpapers found"
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
             "0.66" "Cloud storage..." "$(wp_json_list)"

sleep 1

# Step 3: Cloud provider selection
if [ -f "$HOME/.config/rclone/rclone.conf" ]; then
    write_status "done" "$DESC1" \
                 "done" "$DESC2" \
                 "done" "Cloud storage configured" \
                 "1.0" "done" "$(wp_json_list)"
else
    write_status "done" "$DESC1" \
                 "done" "$DESC2" \
                 "cloud" "Choose a provider" \
                 "0.66" "cloud" "$(wp_json_list)"
fi

# Mark DMS first-launch as complete so its greeter doesn't show
mkdir -p "$HOME/.config/DankMaterialShell"
touch "$HOME/.config/DankMaterialShell/.firstlaunch"

echo "[done] bootstrap.sh finished"
