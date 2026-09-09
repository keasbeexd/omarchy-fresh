# omarchy-fresh

> **⚠️ Archived — no longer maintained.** I've moved to a dotfile manager for my setup, so this repo is frozen as-is. Feel free to fork and adapt it, but don't expect fixes or updates here.

Post-install automation scripts for [Omarchy](https://omarchy.com) — an opinionated Arch Linux setup built around Hyprland. Run one of these after a fresh Omarchy install to set up a gaming-ready, themed, and personalized desktop environment in one shot.

Two scripts are provided:

| Script | Target Omarchy Version | Hyprland Config Language |
|---|---|---|
| [`dotfiles/omarchy-fresh-quattro.sh`](dotfiles/omarchy-fresh-quattro.sh) | Quattro 4+ | Lua (`hyprland.lua`) |
| [`dotfiles/omarchy-fresh.sh`](dotfiles/omarchy-fresh.sh) | Pre-Quattro (legacy) | hyprlang (`hyprland.conf`) |

Pick the script that matches the Omarchy release you just installed. They diverge in more than just the Hyprland config format — Quattro replaced Walker with Quickshell, moved `claude-code` to a mise-backed wrapper, renamed packages, added a plugin system, and changed how the NVIDIA driver branch is selected. See [What Changed in Quattro](#what-changed-in-quattro) for the details.

> **Note:** These scripts are built for my personal setup. Before running either one, read through it and adapt the hardcoded paths and package choices to match your own system. See [Before You Run](#before-you-run).

---

## What They Do

Both scripts run through roughly the same stages in order. Differences called out inline.

### 1. System Prep
Removes Omarchy's default preinstalled packages and pulls the latest Omarchy update.

### 2. Vial Keyboard udev Rule *(Quattro only)*
Writes `/etc/udev/rules.d/59-vial.rules` so Vial can talk to a specific keyboard's hidraw device as the current user's group.

### 3. Hyprland Configuration
- **Quattro:** Ensures `~/.config/hypr/hyprland.lua` exists (restoring it via `omarchy-refresh-config` if it doesn't), then appends a `dofile("/mnt/data/dotfiles/hypr/hyprland-gui.lua")` line at the end so it runs after Omarchy's defaults define the global `o` helper.
- **Legacy:** Appends a `source = /mnt/data/dotfiles/hypr/hyprland-gui.conf` line to `~/.config/hypr/hyprland.conf`.

Then restarts Hyprland via `hyprctl`.

### 4. Gaming Utilities
Installs gaming-focused packages via Omarchy's package manager:
- `gamescope` — Valve's micro-compositor for game sessions
- `mangohud` — In-game performance overlay
- `gamemode` — CPU/GPU optimization daemon
- `fuse2` — Required by some legacy AppImages
- `nvidia-settings` — NVIDIA GUI tool
- `bleachbit` *(Quattro only)* — System cleaner
- `nvidia-utils` + `lact` *(legacy only)* — In Quattro, `nvidia-utils` is dropped because the installer already selected the correct driver branch (open vs `580xx`); forcing it can conflict with the 580xx branch.

### 5. Steam
Installs Steam through Omarchy's gaming module, then pauses to let you log in before continuing.

### 6. AUR Packages
Installs the following via `yay`:
- `easyeffects` — Audio effects pipeline for PipeWire
- `deepfilternet-plugin-pipewire-bin` — AI-powered noise suppression
- `vesktop` — Feature-rich Discord client
- `cryptomator` — Client-side cloud encryption
- `nvibrant-bin` — NVIDIA digital vibrance control
- `faugus-launcher` — GUI launcher for Windows games (Proton/Wine)
- `iloader-bin` + `penguin-burner` *(Quattro only)*

### 7. Omarchy Repo Apps
Installs additional apps from the Omarchy package repo. Package name changes in Quattro:
- `lsp-plugins` → `lsp-plugins-lv2` (the name Omarchy's own package list uses)
- `bitwarden` → `keepassxc`
- Adds `usbmuxd`
- **`claude-code` is no longer a pacman package** in Quattro; it ships as a mise-backed wrapper installed via `omarchy mise install claude`. (And `omarchy remove preinstalls` deletes the wrapper, so it's reinstalled here.)

Then sets all NVIDIA outputs to max digital vibrance via `nvibrant`.

### 8. Spotify + Spicetify
Installs Spotify, prompts you to log in, then installs [Spicetify](https://spicetify.app/) to enable custom themes. Applies the necessary write permissions to `/opt/spotify` so Spicetify can patch it.

Quattro launches Spotify via `uwsm-app -- /usr/bin/spotify` to keep it under the session's uwsm scope. Legacy just runs `spotify &`.

### 9. Launcher Entry Cleanup
Hides noisy or redundant `.desktop` entries by setting `NoDisplay=true` and `Hidden=true`. Works on both user-level and system-level `.desktop` files, copying system files to `~/.local/share/applications/` before modifying them so system files are never touched directly.

- **Quattro:** Walker/elephant are gone; the Quickshell launcher reads `Hidden=`/`NoDisplay=`/`OnlyShowIn=`/`NotShowIn=` live (no cache to clear). The hide list is shorter because Quattro already hides `cmake-gui`, `electron37`, `lstopo`, and the OpenJDK GUIs system-wide via `/usr/share/omarchy/default/omarchy/launcher.hides`.
- **Legacy:** Targets the Walker launcher; the full manual hide list applies.

### 10. Theme Setup
- Sets the **Gruvbox** theme system-wide via Omarchy
- Sets the Plymouth boot screen to match
- **Quattro:** Installs `thpm` (theme package manager) and enables `gtk-css-compat`, `discord`, `spotify`, and `swaync`.
- **Legacy:** Installs the [omarchy-theme-hook](https://github.com/imbypass/omarchy-theme-hook), configures Spicetify to use the Marketplace theme, and disables `thctl` overrides for Spotify and Steam.

### 11. Misc Settings
- Removes FIDO2 and fingerprint security modules (not needed on this machine)
- Installs the Chromium Google Account integration
- Symlinks a MangoHud config from a personal dotfiles mount

### 12. Omarchy Plugins *(Quattro only)*
Enables a set of Omarchy plugins via `omarchy plugin add ... --enable`:
- `herald-notification`, `pick.screenshot`, `omarchy-flush-bar`, `omarchy-activity-monitor`, `omarchy-hsk`, `omarchy-spanned-background`, `omarchy-dpms-guard`

### 13. Reboot
Prompts for confirmation, then reboots. Quattro uses `omarchy system reboot`; legacy uses `reboot`.

---

## What Changed in Quattro

Summary of the meaningful differences the Quattro script accounts for:

- **Hyprland config is Lua now** (`hyprland.lua`), not hyprlang (`hyprland.conf`). `/mnt/data` is outside Lua's `package.path`, so external configs are loaded with `dofile()` by absolute path, appended after Omarchy's defaults so the global `o` helper is defined first.
- **Walker → Quickshell.** The Quickshell launcher picks up `.desktop` visibility changes live; no cache-clear step needed.
- **`claude-code` moved to mise.** No longer a pacman package; installed via `omarchy mise install claude`.
- **NVIDIA driver branch is auto-selected** by the installer (open vs `580xx`). Don't force `nvidia-utils`; `omarchy install gaming steam` pulls the matching lib32 drivers.
- **`lsp-plugins` renamed to `lsp-plugins-lv2`** in Omarchy's package list.
- **Plugin system** via `omarchy plugin add`.
- **Theme hook replaced** by `thpm`.
- **Reboot is `omarchy system reboot`**, not bare `reboot`.
- Several `.desktop` files (cmake-gui, electron37, lstopo, OpenJDK GUIs) are hidden system-wide by default, so no user-level hide entry is needed.

---

## Requirements

- **Omarchy** — Fresh install required. These scripts are not designed for existing setups.
- **NVIDIA GPU** — Several packages (`nvidia-settings`, `nvibrant`, `lact`) are NVIDIA-specific.
- **`yay`** — AUR helper must be installed. Omarchy typically handles this.
- **Dotfiles at `/mnt/data/dotfiles/`** — Both scripts expect a personal dotfiles directory mounted here. See [Before You Run](#before-you-run).

---

## Before You Run

Paths in these scripts are hardcoded to my personal setup. **You must update these before running:**

| Script | Setting | Hardcoded Value | What to Change It To |
|---|---|---|---|
| Quattro | Hyprland dofile | `/mnt/data/dotfiles/hypr/hyprland-gui.lua` | Path to your own Lua config |
| Legacy | Hyprland source | `/mnt/data/dotfiles/hypr/hyprland-gui.conf` | Path to your own hyprlang config |
| Both | MangoHud symlink target | `/mnt/data/dotfiles/MangoHud` | Your own MangoHud config path |
| Legacy | MangoHud symlink dest | `/home/marc/.config/MangoHud` | Your own username/path (Quattro uses `$HOME`) |
| Quattro | Vial udev serial | `*vial:f64c2b3c*` | Your keyboard's serial (or delete the section) |

Also review:
- The **AUR package list** — remove anything you don't need (e.g. `vesktop` if you don't use Discord)
- The **launcher hide list** — `.desktop` files to hide are personal preference
- The **`nvibrant` values** — `1000 1000 1000 1000 1000 1000 1000` sets max vibrance on all outputs; tune to taste
- The **plugin list** (Quattro) — enable only what you actually want

---

## Usage

Pick the script for your Omarchy version, then:

```bash
# Quattro 4+
chmod +x dotfiles/omarchy-fresh-quattro.sh
./dotfiles/omarchy-fresh-quattro.sh

# Pre-Quattro
chmod +x dotfiles/omarchy-fresh.sh
./dotfiles/omarchy-fresh.sh
```

Each script pauses twice for interactive logins — once for **Steam** and once for **Spotify** — before continuing. Everything else runs unattended.

---

## Interactive Pauses

| Pause | What To Do |
|---|---|
| After Steam installs | Log in to your Steam account, then press `Enter` |
| After Spotify installs | Log in to your Spotify account, then press `Enter` |

---

## License

Do whatever you want with this. It's a personal setup script shared for learning purposes — adapt it freely.
