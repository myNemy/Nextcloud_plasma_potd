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

- **Load Configuration**: Click "Load" to read your existing configuration file
- **Edit Settings**: Modify URL, path, username, password, etc.
- **Switch Modes**: Choose between WebDAV (direct connection) or local synchronized folder
- **Generate Config**: Click "Save Configuration" to generate the config file content
- **Copy & Save**: Copy the generated configuration and save it manually to `~/.config/plasma_engine_potd/nextcloudprovider.conf`

## How to Use

1. **Launch the GUI**: `./run.sh`
2. **Load existing config** (if you have one): Click "Load" button
3. **Fill in your settings**:
   - Choose connection mode (WebDAV or Local)
   - Enter Nextcloud URL, WebDAV path, username, password (for WebDAV mode)
   - Or enter local path (for Local mode)
   - Set MaxImages if needed (0 = unlimited)
4. **Generate configuration**: Click "Save Configuration"
5. **Copy the generated text** from the text area
6. **Save manually**: 
   ```bash
   mkdir -p ~/.config/plasma_engine_potd
   nano ~/.config/plasma_engine_potd/nextcloudprovider.conf
   # Paste the generated configuration
   ```
7. **Restart Plasma**: `killall plasmashell && kstart plasmashell`

## Note

The GUI cannot write files directly due to QML security restrictions. You need to manually save the generated configuration. This is a simple visual editor to help you create the correct configuration format.

