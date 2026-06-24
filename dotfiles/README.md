# omarchy-fresh.sh

A post-install automation script for [Omarchy](https://omarchy.com) — an opinionated Arch Linux setup built around Hyprland. Run this after a fresh Omarchy install to set up a gaming-ready, themed, and personalized desktop environment in one shot.

> **Note:** This script was built for my personal setup. Before running it yourself, read through it and adapt the hardcoded paths and package choices to match your own system. See [Before You Run](#before-you-run).

---

## What It Does

The script runs through the following stages in order:

### 1. System Prep
Removes Omarchy's default preinstalled packages and pulls the latest Omarchy update.

### 2. Hyprland Configuration
Creates `~/.config/hypr/` if it doesn't exist and appends a custom `source` line pointing to a personal dotfiles config, then restarts Hyprland via `hyprctl`.

### 3. Gaming Utilities
Installs a set of gaming-focused packages via Omarchy's package manager:
- `gamescope` — Valve's micro-compositor for game sessions
- `mangohud` — In-game performance overlay
- `gamemode` — CPU/GPU optimization daemon
- `fuse2` — Required by some legacy AppImages
- `nvidia-utils` + `nvidia-settings` — NVIDIA driver tools
- `lact` — Linux GPU configuration tool

### 4. Steam
Installs Steam through Omarchy's gaming module, then pauses to let you log in before continuing.

### 5. AUR Packages
Installs the following via `yay`:
- `easyeffects` — Audio effects pipeline for PipeWire
- `deepfilternet-plugin-pipewire-bin` — AI-powered noise suppression
- `vesktop` — Feature-rich Discord client
- `cryptomator` — Client-side cloud encryption
- `nvibrant-bin` — NVIDIA digital vibrance control
- `faugus-launcher` — GUI launcher for Windows games (Proton/Wine)

### 6. Omarchy Repo Apps
Installs additional apps from the Omarchy package repo:
- `lsp-plugins` — Professional audio plugin suite
- `bitwarden` — Password manager
- `nextcloud-client` — Cloud sync client
- `adw-gtk-theme` — GTK theme matching GNOME's Adwaita style

Then sets all NVIDIA outputs to max digital vibrance via `nvibrant`.

### 7. Spotify + Spicetify
Installs Spotify, prompts you to log in, then installs [Spicetify](https://spicetify.app/) to enable custom themes. Applies the necessary write permissions to `/opt/spotify` so Spicetify can patch it.

### 8. Walker App Launcher Cleanup
Hides a list of noisy or redundant `.desktop` entries from the [Walker](https://github.com/abenz1267/walker) app launcher by setting `NoDisplay=true` and `Hidden=true`. Works on both user-level and system-level `.desktop` files, copying system files to `~/.local/share/applications/` before modifying them so system files are never touched directly.

### 9. Theme Setup
- Sets the **Gruvbox** theme system-wide via Omarchy
- Sets the Plymouth boot screen to match
- Installs the [omarchy-theme-hook](https://github.com/imbypass/omarchy-theme-hook) for deeper theming integration
- Configures Spicetify to use the Marketplace theme
- Disables `thctl` theme overrides for Spotify and Steam

### 10. Misc Settings
- Removes FIDO2 and fingerprint security modules (not needed on this machine)
- Installs the Chromium Google Account integration
- Symlinks a MangoHud config from a personal dotfiles mount

### 11. Reboot
Prompts for confirmation, then reboots via `systemd`.

---

## Requirements

- **Omarchy** — Fresh install required. This script is not designed for existing setups.
- **NVIDIA GPU** — Several packages (`nvidia-utils`, `nvibrant`, `lact`) are NVIDIA-specific.
- **`yay`** — AUR helper must be installed. Omarchy typically handles this.
- **Dotfiles at `/mnt/data/dotfiles/`** — The script expects a personal dotfiles directory mounted here. See [Before You Run](#before-you-run).

---

## Before You Run

Two paths in this script are hardcoded to my personal setup. **You must update these before running:**

| Line | Hardcoded Value | What to Change It To |
|---|---|---|
| Hyprland source | `/mnt/data/dotfiles/hypr/hyprland-gui.conf` | Path to your own Hyprland config |
| MangoHud symlink | `/home/marc/.config/MangoHud` | Your own username/path |

Also review:
- The **AUR package list** — remove anything you don't need (e.g. `vesktop` if you don't use Discord)
- The **Walker cleanup list** — `.desktop` files to hide are personal preference
- The **`nvibrant` values** — `1000 1000 1000 1000 1000 1000 1000` sets max vibrance on all outputs; tune to taste

---

## Usage

```bash
# Clone or download the script, then make it executable
chmod +x omarchy-fresh.sh

# Run it
./omarchy-fresh.sh
```

The script will pause twice for interactive logins — once for **Steam** and once for **Spotify** — before continuing. Everything else runs unattended.

---

## Interactive Pauses

| Pause | What To Do |
|---|---|
| After Steam installs | Log in to your Steam account, then press `Enter` |
| After Spotify installs | Log in to your Spotify account, then press `Enter` |

---

## License

Do whatever you want with this. It's a personal setup script shared for learning purposes — adapt it freely.
