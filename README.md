# Nextcloud Provider for KDE Plasma Picture of the Day

Provider for the KDE Plasma "Picture of the Day" plugin that allows using images from Nextcloud.

## Features

- ✅ **WebDAV Support**: Direct connection to Nextcloud via WebDAV
- ✅ **Local Path**: Support for locally synchronized folders
- ✅ **App Password Authentication**: Support for Nextcloud App Passwords
- ✅ **Random Selection**: Randomly selects images from the folder
- ✅ **Recursive Search**: Searches for images in all subfolders
- ✅ **Image Limit**: Option to limit the number of images loaded

## Requirements

### Minimum Requirements

- **KDE Plasma**: 6.5.0 or higher
- **KDE Frameworks**: 6.19.0 or higher (KF6)
- **Qt**: 6.0.0 or higher (Qt6)
- **CMake**: 3.16 or higher
- **C++ Compiler**: C++17 support (GCC 7+, Clang 5+)
- **kdeplasma-addons**: Development packages with potd provider support

### Required KDE Frameworks Components

- KF6::CoreAddons
- KF6::ConfigCore
- KF6::KIOCore

### Required Qt Components

- Qt6::Core
- Qt6::Network
- Qt6::Gui

### Build Dependencies

On Arch Linux:
```bash
sudo pacman -S cmake qt6-base qt6-network qt6-gui kf6-coreaddons kf6-config kf6-kio kdeplasma-addons
```

On Debian/Ubuntu:
```bash
sudo apt install cmake qt6-base-dev qt6-base-dev-tools libkf6coreaddons-dev libkf6config-dev libkf6kio-dev kdeplasma-addons libkf6plasma-dev plasma-workspace-dev
```

**Note for Ubuntu 25.04+**: The `kdeplasma-addons-dev` package doesn't exist. Install `kdeplasma-addons` (runtime) and `libkf6plasma-dev` + `plasma-workspace-dev` (development headers). If `potdprovider.h` is still not found, you may need to build `kdeplasma-addons` from source or use the file from this repository (`plugins/providers/potdprovider.h`).

On Fedora:
```bash
sudo dnf install cmake qt6-qtbase-devel kf6-kcoreaddons-devel kf6-kconfig-devel kf6-kio-devel kdeplasma-addons-devel
```

## Configuration

The provider reads configuration from:
`~/.config/plasma_engine_potd/nextcloudprovider.conf`

Format:
```ini
[Nextcloud]
Url=https://nextcloud.example.com
Path=/remote.php/dav/files/USERNAME/Images
Username=username
Password=app_password_here
UseLocalPath=false
LocalPath=/home/user/Nextcloud/Images
MaxImages=0  # Maximum number of images to load (0 = unlimited)
```

## Compilation

```bash
cd /path/to/kdeplasma-addons
mkdir build && cd build
cmake ..
make
sudo make install
```

## Usage

1. Go to Settings → Appearance → Background
2. Select "Picture of the Day"
3. In the "Provider" menu select "Nextcloud"
4. Configure the provider (create `~/.config/plasma_engine_potd/nextcloudprovider.conf` as shown above)
5. Restart Plasma: `killall plasmashell && kstart plasmashell`

## License

This project is licensed under the **GPL-2.0-or-later** license, the same license used by the KDE Plasma potd provider system.

See the [LICENSE](LICENSE) file for the full text of the GNU General Public License version 2.

## Development

This project was developed with the assistance of AI coding tools.

## Trademark Notice

"Nextcloud" is a registered trademark. This project is not affiliated with, sponsored by, or endorsed by Nextcloud GmbH.
