# awesome-from-scratch

A comprehensive AwesomeWM/somewm configuration built from scratch, designed as both a fully-functional rice and a learning resource. **100% native** - no rofi, no polybar, no conky.

## Features

### Dashboard / Control Center
Press `Super+D` to toggle a beautiful control center featuring:
- Time and date with personalized greeting
- Volume and brightness sliders
- Quick toggles: WiFi, Bluetooth, DND, Night Light, Airplane Mode, Microphone
- Interactive calendar with month navigation

### Native App Launcher
Press `Super+P` for a fuzzy-search application launcher:
- Parses `.desktop` files automatically
- Fuzzy matching with intelligent scoring
- Keyboard navigation (Up/Down/Enter/Escape)
- Tab completion

### Exit Screen
Press `Super+Shift+E` for a full-screen power menu:
- Lock, Logout, Suspend, Reboot, Shutdown
- Keyboard shortcuts for each action
- Arrow key and vim-style navigation

### Wibar
A clean, functional status bar with:
- Custom taglist with icons (code, web, chat, db, games)
- Centered clock
- System tray
- Volume, WiFi, Battery widgets
- Power button

### Notifications
A sophisticated notification system with:
- Notification history
- Do Not Disturb mode
- Rule-based positioning and styling
- Notification center popup

### Theme
Gruvbox dark colorscheme throughout, with:
- Consistent color palette
- DPI-aware sizing
- macOS-style titlebars
- Beautiful window decorations

## Quick Start

```bash
# Clone the repo
git clone https://github.com/yourusername/awesome-from-scratch.git

# For somewm (Wayland)
cp -r awesome-from-scratch ~/.config/somewm

# For AwesomeWM (X11)
cp -r awesome-from-scratch ~/.config/awesome

# Restart your compositor
```

## Key Bindings

| Key | Action |
|-----|--------|
| `Super+D` | Toggle dashboard |
| `Super+P` | App launcher |
| `Super+Shift+E` | Exit screen |
| `Super+Return` | Terminal (ghostty) |
| `Super+S` | Show keybinding help |
| `Super+J/K` | Focus next/prev client |
| `Super+H/L` | Resize master |
| `Super+1-5` | Switch to tag |
| `Super+Shift+1-5` | Move client to tag |
| `Super+Ctrl+R` | Reload config |

## Dependencies

**Required:**
- somewm or AwesomeWM 4.3+
- JetBrainsMono Nerd Font

**Optional (for full functionality):**
- wpctl (volume control)
- brightnessctl (brightness control)
- nmcli (WiFi toggle)
- bluetoothctl (Bluetooth toggle)
- gammastep (night light)
- playerctl (media controls)
- swaylock/hyprlock/i3lock (screen lock)

## Directory Structure

```
.
├── rc.lua              # Main config
├── keybindings.lua     # All keybindings
├── wibar.lua           # Status bar
├── theme/
│   └── theme.lua       # Gruvbox theme
├── dashboard/          # Control center
│   ├── init.lua
│   ├── profile.lua
│   ├── sliders.lua
│   ├── toggles.lua
│   └── calendar.lua
├── launcher/           # App launcher
│   └── init.lua
├── exitscreen/         # Power menu
│   └── init.lua
├── widgets/            # Wibar widgets
│   ├── battery.lua
│   ├── clock.lua
│   ├── volume.lua
│   ├── wifi.lua
│   └── ...
├── notifications.lua   # Notification system
└── icons/              # SVG icons
```

## Learning Path

This config is structured as a tutorial series. Each branch builds on the previous:

| Branch | Topic |
|--------|-------|
| `main` | Complete config (you are here) |
| `01-theme` | Theme system fundamentals |
| `02-widgets` | Widget system deep dive |
| `03-dashboard` | Building the control center |
| `04-wibar` | Status bar with custom widgets |
| `05-notifications` | Notification system |
| `06-launcher` | Native app launcher |
| `07-titlebars` | Window decorations |
| `08-keybindings` | Organized bindings |
| `09-exit-screen` | Modal UI patterns |

## Customization

### Changing Colors
Edit `theme/theme.lua` and modify the `color_scheme` variable or add your own palette to the `colors` table.

### Adding Tags
Edit `widgets/taglist.lua` to add/remove tags and customize their icons.

### Wallpaper
Set your wallpaper path in `rc.lua` or place images in `~/wallpapers/gruvbox/`.

## Credits

- Built for [somewm](https://github.com/user/somewm) and [AwesomeWM](https://awesomewm.org/)
- Gruvbox colorscheme by [morhetz](https://github.com/morhetz/gruvbox)
- Icons from various Nerd Font sets

## License

MIT
