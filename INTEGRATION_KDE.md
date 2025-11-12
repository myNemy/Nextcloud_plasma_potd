# Integration into kdeplasma-addons

**For KDE Developers**: This guide explains how to integrate the Nextcloud provider into the official kdeplasma-addons repository.

## Overview

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

## Notes

- This integration is intended for KDE developers who want to include the provider in the official kdeplasma-addons repository
- For regular users, simply compile and install the provider as described in the main README
- The QML configuration interface is optional - the provider works with manual configuration file editing

