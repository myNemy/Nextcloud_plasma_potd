# Nextcloud Wallpaper Configuration GUI

Standalone Qt6/QML application for configuring the Nextcloud Wallpaper provider.

## Features

- ✅ Configure Nextcloud connection (WebDAV or local path)
- ✅ Save/load configuration from `~/.config/plasma_engine_potd/nextcloudprovider.conf`
- ✅ Validate configuration before saving
- ✅ Browse for local folder path
- ✅ No dependency on provider compilation

## Build

```bash
cd gui
mkdir build && cd build
cmake ..
make
```

## Run

```bash
./nextcloud-wallpaper-config
```

## Install

```bash
sudo make install
# Then run: nextcloud-wallpaper-config
```

## Requirements

- Qt6 (Core, Quick, Qml)
- KF6::ConfigCore

