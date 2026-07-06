# bb8-Hyprdots

Personal Hyprland rice — Hyprland, Quickshell, Kitty, cava and a custom
tree-style zsh prompt, all in one lavender/dark color scheme.

## ⚠️ Warnings — read before applying

These dotfiles are tailored to my exact hardware and preferences. If you
just copy them 1:1, things **will** break or feel wrong until you adjust:

- **Monitor setup** (`~/.config/hypr/monitors.lua`): hardcoded to my two
  monitors — a 1920x1080@60 side monitor on `HDMI-A-1` and a
  3840x1080@143.85 ultrawide on `DP-1`, with specific positions/workspace
  assignments. You **must** change `output`, `mode` (resolution@Hz) and
  `position` to match your own monitor names and specs
  (`hyprctl monitors` to find yours), or Hyprland may not draw anything.
- **Keybinds** (`~/.config/hypr/keybinds.lua`): bound to my own workflow
  and muscle memory. Go through them and rebind to your own taste.
- **Autostart / scripts** (`~/.config/hypr/autostart.lua`,
  `~/.config/hypr/scripts/`): may reference apps or paths that only exist
  on my machine (e.g. AUR helper scripts). Check before relying on them.
- **cava audio source** (`~/.config/cava/config`): input method defaults
  to auto-detecting pulse/pipewire — if your audio backend differs, set
  `method`/`source` under `[input]` yourself.
- **Zsh setup**: assumes Oh My Zsh is installed at `~/.oh-my-zsh` and that
  `eza`, `fzf`, `zoxide`, `fastfetch`, `zsh-autosuggestions` and
  `zsh-syntax-highlighting` are installed. The `masters-shell` theme is
  the prompt (tree-style path breadcrumbs, git branch inline, command
  duration shown after 30s) — set `ZSH_THEME="masters-shell"` and drop
  `masters-shell.zsh-theme` into `~/.oh-my-zsh/custom/themes/`.
- **Colors**: the palette lives in `~/.config/quickshell/colors.js` and is
  mirrored manually in `~/.config/hypr/colors.conf` and the Kitty theme —
  if you want different colors, you need to update all three.

## What's in here

```
.config/hypr/        Hyprland config (monitors, keybinds, window rules, colors)
.config/quickshell/   Bar/widgets (Qt Quickshell)
.config/kitty/        Terminal theme
.config/cava/         Audio visualizer config (lavender→green gradient)
.config/fastfetch/    System info fetch shown on shell startup
.oh-my-zsh/custom/themes/masters-shell.zsh-theme   Custom tree-style prompt
.zshrc                Full shell config
```
