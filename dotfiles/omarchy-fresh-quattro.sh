#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

## --- System Prep ---
echo "Removing preinstalls..."
omarchy remove preinstalls
echo "Updating Omarchy..."
omarchy update -y

## --- udev for Vial Keyboards ---
# GROUP takes a group NAME, not a numeric GID (id -g). Fixed to id -gn.
export USER_GROUP=$(id -gn)
sudo --preserve-env=USER_GROUP sh -c 'echo "KERNEL==\"hidraw*\", SUBSYSTEM==\"hidraw\", ATTRS{serial}==\"*vial:f64c2b3c*\", MODE=\"0660\", GROUP=\"$USER_GROUP\", TAG+=\"uaccess\", TAG+=\"udev-acl\"" > /etc/udev/rules.d/59-vial.rules && udevadm control --reload && udevadm trigger'

## --- Hyprland Configuration (Quattro: Lua, not hyprlang) ---
echo "Configuring Hyprland entrypoint..."
HYPR_LUA="$HOME/.config/hypr/hyprland.lua"
GUI_LUA="/mnt/data/dotfiles/hypr/hyprland-gui.lua"

mkdir -p "$HOME/.config/hypr"

# On a fresh Quattro install this already exists; restore it if it doesn't.
[[ -f $HYPR_LUA ]] || omarchy-refresh-config hypr/hyprland.lua

# /mnt/data is outside Lua's package.path (~/.local/state, ~/.config,
# /usr/share/omarchy), so require() can't reach it -- dofile() by absolute path.
# Appended at the end so it lands after require("default.hypr.omarchy"),
# which is what defines the global `o` helper and loads Omarchy's defaults.
if ! grep -qF "$GUI_LUA" "$HYPR_LUA"; then
  printf '\ndofile("%s")\n' "$GUI_LUA" >>"$HYPR_LUA"
fi

omarchy restart hyprctl

## --- Gaming Package Installs ---
# nvidia-utils removed: Quattro's installer already picked the correct driver
# branch for this machine (nvidia-open-dkms+nvidia-utils on GSP-capable cards,
# nvidia-580xx-dkms+nvidia-580xx-utils on older ones). Forcing nvidia-utils can
# conflict with the 580xx branch. omarchy install gaming steam pulls the
# matching lib32 drivers via omarchy-install-gaming-gpu-lib32.
echo "Installing gaming utilities..."
omarchy pkg add gamescope mangohud gamemode fuse2 nvidia-settings bleachbit

## --- Steam Install & Setup ---
echo "Installing Steam"
omarchy install gaming steam

echo "------------------------------------------------"
read -p "Please log in to Steam, then press [Enter] here to continue..."
echo "------------------------------------------------"

## --- AUR & Dependency Installs ---
yay -S --noconfirm --needed easyeffects deepfilternet-plugin-pipewire-bin vesktop cryptomator nvibrant-bin iloader-bin faugus-launcher penguin-burner

## --- omarchy repo Application Installs ---
# lsp-plugins -> lsp-plugins-lv2 (the name Omarchy's own package list uses).
# claude-code is no longer a pacman package in Quattro; it ships as a
# mise-backed wrapper (and "omarchy remove preinstalls" deletes that wrapper).
omarchy pkg add lsp-plugins-lv2 nextcloud-client adw-gtk-theme usbmuxd keepassxc
omarchy mise install claude

nvibrant 1000 1000 1000 1000 1000 1000 1000

## --- Spotify Install & Spicetify Setup ---
echo "Installing Spotify..."
omarchy pkg add spotify

# Launch Spotify in background
set +e # Disable exit-on-error
uwsm-app -- /usr/bin/spotify &
set -e # Re-enable exit-on-error

echo "------------------------------------------------"
read -p "Please log in to Spotify, then press [Enter] here to continue..."
echo "------------------------------------------------"

# Install Spicetify
echo "Installing Spicetify..."
set +e # Disable exit-on-error
curl -fsSL https://raw.githubusercontent.com/spicetify/cli/main/install.sh | sh

# Update current script path so it can find the 'spicetify' binary immediately
export PATH="$PATH:$HOME/.spicetify"
grep -qxF 'export PATH=$PATH:~/.spicetify' ~/.bashrc || echo 'export PATH=$PATH:~/.spicetify' >>~/.bashrc

# Apply spicetify
echo "Applying Spotify permissions and themes..."
sudo chmod a+wr /opt/spotify
sudo chmod a+wr /opt/spotify/Apps -R
spicetify backup apply
set -e # Re-enable exit-on-error

## --- Hide launcher entries (Omarchy Shell, not Walker) ---
# Walker/elephant are gone in Quattro. The Quickshell launcher reads
# Hidden= / NoDisplay= / OnlyShowIn= / NotShowIn= from .desktop files
# (see /usr/share/omarchy/shell/services/hidden-entries.sh), so this still
# works -- and it picks changes up live, no cache to clear.
#
# Dropped from the list because Quattro already hides them system-wide in
# /usr/share/omarchy/default/omarchy/launcher.hides:
#   cmake-gui, electron37, lstopo, java-java-openjdk,
#   jshell-java-openjdk, jconsole-java-openjdk
USER_DIR="$HOME/.local/share/applications"
SYSTEM_DIR="/usr/share/applications"

mkdir -p "$USER_DIR"

FILES=(
    "typora.desktop"
    "lsp-plugins.desktop"
    "org.rncbc.qtractor.desktop"
)

hide_key_in_file() {
    local file=$1
    local key=$2

    if grep -q "^${key}=" "$file"; then
        sed -i "s/^${key}=.*/${key}=true/" "$file"
    else
        echo "${key}=true" >>"$file"
    fi
}

for file in "${FILES[@]}"; do
    TARGET="$USER_DIR/$file"
    SYS_SOURCE="$SYSTEM_DIR/$file"

    if [ -f "$TARGET" ]; then
        echo "Updating existing user file: $file"
        hide_key_in_file "$TARGET" "NoDisplay"
        hide_key_in_file "$TARGET" "Hidden"

    elif [ -f "$SYS_SOURCE" ]; then
        echo "Copying system file to user directory: $file"
        cp "$SYS_SOURCE" "$TARGET"
        hide_key_in_file "$TARGET" "NoDisplay"
        hide_key_in_file "$TARGET" "Hidden"

    else
        echo "Not found in user or system dirs: $file (skipping)"
    fi
done

update-desktop-database "$USER_DIR" &>/dev/null || true
echo "Done. Omarchy Shell picks hidden entries up live."

## --- Omarchy Update to delete Orphan Packages ---
echo "Updating Omarchy..."
omarchy update -y

## --- Omarchy Theme Setup ---
omarchy theme set gruvbox
omarchy plymouth set by theme gruvbox
omarchy pkg aur add thpm
thpm install
thpm enable gtk-css-compat
thpm enable discord
thpm enable spotify
thpm enable swaync

## --- Remove redundant security/settings ---
omarchy remove security fido2
omarchy remove security fingerprint
omarchy install chromium google account

## --- Omarchy Plugins ---
omarchy plugin add https://github.com/jesseburlamaque/herald-notification.git --enable
omarchy plugin add https://github.com/nightdevil00/pick.screenshot.git --enable
omarchy plugin add https://github.com/scottjones/omarchy-flush-bar.git --enable
omarchy plugin add https://github.com/stappmus/omarchy-activity-monitor.git --enable
omarchy plugin add https://github.com/keasbeexd/omarchy-hsk.git --enable
omarchy plugin add https://github.com/keasbeexd/omarchy-spanned-background.git --enable
omarchy plugin add https://github.com/austin-karren/omarchy-dpms-guard.git --enable

ln -sfn /mnt/data/dotfiles/MangoHud "$HOME/.config/MangoHud"

## --- Prompt the user to reboot ---
echo "System setup complete | Are you ready to restart?"
read -p "Press [ENTER] to restart or [Ctrl+C] to cancel..."

echo "Restarting system now..."
omarchy system reboot
