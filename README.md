# Nextcloud Provider for KDE Plasma Picture of the Day

Provider for the KDE Plasma "Picture of the Day" plugin that allows using images from Nextcloud.

## Features

- ✅ **WebDAV Support**: Direct connection to Nextcloud via WebDAV
- ✅ **Local Path**: Support for locally synchronized folders
- ✅ **App Password Authentication**: Support for Nextcloud App Passwords
- ✅ **Random Selection**: Randomly selects images from the folder
- ✅ **Recursive Search**: Searches for images in all subfolders
- ✅ **Image Limit**: Option to limit the number of images loaded
- ⚠️ **Automatic Rotation**: Not available (see [docs/CHANGE_IMAGE.md](docs/CHANGE_IMAGE.md))

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
sudo apt install cmake qt6-base-dev qt6-base-dev-tools libkf6coreaddons-dev libkf6config-dev libkf6kio-dev kdeplasma-addons-dev
```

On Fedora:
```bash
sudo dnf install cmake qt6-qtbase-devel kf6-kcoreaddons-devel kf6-kconfig-devel kf6-kio-devel kdeplasma-addons-devel
```

## Integration into kdeplasma-addons

To integrate this provider into the kdeplasma-addons repository:

1. Copy files to the correct structure:
   ```bash
   cp plugins/providers/* /path/to/kdeplasma-addons/wallpapers/potd/plugins/providers/
   ```

2. Add to `CMakeLists.txt`:
   ```cmake
   kcoreaddons_add_plugin(plasma_potd_nextcloudprovider SOURCES nextcloudprovider.cpp INSTALL_NAMESPACE "potd")
   target_link_libraries(plasma_potd_nextcloudprovider plasmapotdprovidercore plasma_wallpaper_potdplugin_debug KF6::KIOCore KF6::CoreAddons Qt6::Network)
   ```

3. Modify `package/contents/ui/config.qml` to add configuration fields when `cfg_Provider === "nextcloud"`:

   Add after the Provider selector (around line 124):
   ```qml
   // Nextcloud Configuration (visible only when Nextcloud provider is selected)
   Kirigami.Separator {
       Layout.fillWidth: true
       Layout.topMargin: Kirigami.Units.smallSpacing
       Layout.bottomMargin: Kirigami.Units.smallSpacing
       visible: cfg_Provider === "nextcloud"
   }

   QtControls2.CheckBox {
       id: useLocalPathCheck
       visible: cfg_Provider === "nextcloud"
       Kirigami.FormData.label: i18n("Mode:")
       text: i18n("Use local synchronized folder")
       checked: nextcloudConfig.useLocalPath
       onToggled: nextcloudConfig.useLocalPath = checked
   }

   QtControls2.TextField {
       id: localPathField
       visible: cfg_Provider === "nextcloud" && useLocalPathCheck.checked
       Kirigami.FormData.label: i18n("Local Path:")
       text: nextcloudConfig.localPath
       onTextChanged: nextcloudConfig.localPath = text
   }

   QtControls2.TextField {
       id: nextcloudUrlField
       visible: cfg_Provider === "nextcloud" && !useLocalPathCheck.checked
       Kirigami.FormData.label: i18n("Nextcloud URL:")
       text: nextcloudConfig.nextcloudUrl
       onTextChanged: nextcloudConfig.nextcloudUrl = text
   }

   QtControls2.TextField {
       id: nextcloudPathField
       visible: cfg_Provider === "nextcloud" && !useLocalPathCheck.checked
       Kirigami.FormData.label: i18n("WebDAV Path:")
       text: nextcloudConfig.nextcloudPath
       onTextChanged: nextcloudConfig.nextcloudPath = text
   }

   QtControls2.TextField {
       id: usernameField
       visible: cfg_Provider === "nextcloud" && !useLocalPathCheck.checked
       Kirigami.FormData.label: i18n("Username:")
       text: nextcloudConfig.username
       onTextChanged: nextcloudConfig.username = text
   }

   QtControls2.TextField {
       id: passwordField
       visible: cfg_Provider === "nextcloud" && !useLocalPathCheck.checked
       Kirigami.FormData.label: i18n("Password or App Password:")
       echoMode: TextInput.Password
       text: nextcloudConfig.password
       onTextChanged: nextcloudConfig.password = text
   }
   ```

   And add a component to manage configuration (before `Kirigami.FormLayout`):
   ```qml
   // Nextcloud Configuration Manager
   QtObject {
       id: nextcloudConfig
       property bool useLocalPath: false
       property string localPath: ""
       property string nextcloudUrl: ""
       property string nextcloudPath: ""
       property string username: ""
       property string password: ""

       function saveConfig() {
           const configPath = Qt.resolvedUrl("file://" + StandardPaths.writableLocation(StandardPaths.GenericConfigLocation) + "/plasma_engine_potd/nextcloudprovider.conf");
           // Save configuration using KConfig or other method
       }

       function loadConfig() {
           // Load configuration
       }

       Component.onCompleted: loadConfig()
   }
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

See [docs/CONFIGURATION.md](docs/CONFIGURATION.md) for complete details.

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
4. Configure the provider (see [docs/CONFIGURATION.md](docs/CONFIGURATION.md))
5. Restart Plasma: `killall plasmashell && kstart plasmashell`

## Documentation

- [docs/CONFIGURATION.md](docs/CONFIGURATION.md) - How to configure the provider
- [docs/CHANGE_IMAGE.md](docs/CHANGE_IMAGE.md) - How to change the image
- [docs/WHEN_LIST_UPDATES.md](docs/WHEN_LIST_UPDATES.md) - When the list is created/updated
- [docs/UNINSTALL.md](docs/UNINSTALL.md) - How to remove the provider
- [docs/CHANGELOG.md](docs/CHANGELOG.md) - Changelog
