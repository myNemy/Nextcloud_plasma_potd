# Nextcloud Wallpaper Configuration GUI

Simple standalone GUI for configuring the Nextcloud wallpaper provider.

## Usage

### Method 1: Direct QML execution (no compilation needed)

```bash
cd gui
./run.sh
```

Or directly:
```bash
qml6 gui/main.qml
```

### Method 2: Create desktop entry

You can create a `.desktop` file to launch it from your application menu:

```ini
[Desktop Entry]
Name=Nextcloud Wallpaper Config
Comment=Configure Nextcloud Wallpaper Provider
Exec=qml6 /path/to/nextcloud-wallpaper/gui/main.qml
Icon=folder-remote
Type=Application
Categories=Settings;
```

## Requirements

- Qt6 QML runtime (`qml6` or `qmlscene`)
- Qt6 Quick Controls 2

On Arch Linux:
```bash
sudo pacman -S qt6-declarative
```

On Debian/Ubuntu:
```bash
sudo apt install qml6-module-qtquick-controls2
```

## Features

- Load existing configuration
- Save configuration to `~/.config/plasma_engine_potd/nextcloudprovider.conf`
- Switch between WebDAV and local path modes
- Browse for local folder
- Set maximum images limit
- Input validation

