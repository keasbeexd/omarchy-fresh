#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

## --- System Prep ---
echo "Removing preinstalls..."
omarchy remove preinstalls
echo "Updating Omarchy..."
omarchy update


## --- Hyprland Configuration ---
echo "Configuring Hyprland source file..."
# Ensure directory exists on a fresh install
mkdir -p ~/.config/hypr
# Safely append configuration
printf "\nsource = /mnt/data/dotfiles/hypr/hyprland-gui.conf\n" >> ~/.config/hypr/hyprland.conf
omarchy restart hyprctl


## --- Gaming Package Installs ---
echo "Installing gaming utilities..."
omarchy pkg add gamescope mangohud gamemode fuse2 nvidia-utils nvidia-settings lact


## --- Steam Install & Setup ---
echo "Installing Steam"
omarchy install gaming steam


echo "------------------------------------------------"
read -p "Please log in to Steam, then press [Enter] here to continue..."
echo "------------------------------------------------"


## --- AUR & Dependency Installs ---
yay -S --noconfirm --needed easyeffects deepfilternet-plugin-pipewire-bin vesktop cryptomator nvibrant-bin faugus-launcher


## --- omarchyREPO Application Installs ---
omarchy pkg add lsp-plugins bitwarden nextcloud-client adw-gtk-theme
nvibrant 1000 1000 1000 1000 1000 1000 1000


## --- Spotify Install & Spicetify Setup ---
echo "Installing Spotify..."
omarchy pkg add spotify

# Launch Spotify in background
set +e # Disable exit-on-error
spotify &
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
echo 'export PATH=$PATH:~/.spicetify' >> ~/.bashrc

# Apply spicetify
echo "Applying Spotify permissions and themes..."
sudo chmod a+wr /opt/spotify
sudo chmod a+wr /opt/spotify/Apps -R
spicetify backup apply
set -e # Re-enable exit-on-error


## --- Cleanup Walker ---
# Define directories (User takes priority over System)
USER_DIR="$HOME/.local/share/applications"
SYSTEM_DIR="/usr/share/applications"

# Ensure user directory exists
mkdir -p "$USER_DIR"

# List of .desktop files to modify
FILES=(
    "electron37.desktop"
    "lstopo.desktop"
    "typora.desktop"
    "lsp-plugins.desktop"
    "org.rncbc.qtractor.desktop"
    "java-java-openjdk.deskop"
    "jshell-java-openjdk.desktop"
    "jconsole-java-openjdk.desktop"
    "com.steamgriddb.SGDBoop.desktop"
    "cmake-gui.desktop"
)

hide_key_in_file() {
    local file=$1
    local key=$2

    if grep -q "^${key}=" "$file"; then
        # If key exists (true or false), force it to true
        sed -i "s/^${key}=.*/${key}=true/" "$file"
    else
        # If key doesn't exist, append it
        echo "${key}=true" >> "$file"
    fi
}

for file in "${FILES[@]}"; do
    TARGET="$USER_DIR/$file"
    SYS_SOURCE="$SYSTEM_DIR/$file"

    # Scenario 1: File already exists in user directory
    if [ -f "$TARGET" ]; then
        echo "🔄 Updating existing user file: $file"
        hide_key_in_file "$TARGET" "NoDisplay"
        hide_key_in_file "$TARGET" "Hidden"
        echo "🙈 Hid user app: $file"

    # Scenario 2: File only exists in system directory
    elif [ -f "$SYS_SOURCE" ]; then
        echo "📦 Copying system file to user directory: $file"
        cp "$SYS_SOURCE" "$TARGET"
        
        hide_key_in_file "$TARGET" "NoDisplay"
        hide_key_in_file "$TARGET" "Hidden"
        echo "🙈 Hid system app (copied to user space): $file"

    # Scenario 3: File not found anywhere
    else
        echo "⚠️  Not found in user or system dirs: $file (skipping)"
    fi
done

echo "Done! You may need to restart Walker or clear its cache to see changes."


## --- Omarchy Update to delete Orphan Packages ---
echo "Updating Omarchy..."
omarchy update


## --- Omarchy Theme Setup ---
omarchy theme set gruvbox
omarchy plymouth set by theme gruvbox
set +e # Disable exit-on-error
curl -fsSL https://imbypass.github.io/omarchy-theme-hook/install.sh | bash

thctl disable spotify
spicetify config current_theme marketplace
spicetify apply
thctl disable steam
set -e # Re-enable exit-on-error


## --- Remove redundent securities/settings ---
omarchy remove security fido2
omarchy remove security fingerprint
omarchy install chromium google account
ln -s /mnt/data/dotfiles/MangoHud /home/marc/.config/MangoHud 


## --- Prompt the user to reboot ---
echo "⚠️ System Setup Complete | Are you ready to restart?"
read -p "Press [ENTER] to restart or [Ctrl+C] to cancel..."

echo "🔄 Restarting system now..."
# Standard systemd reboot command
reboot

