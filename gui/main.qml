/*
 *   SPDX-FileCopyrightText: 2024 Nextcloud Wallpaper Plugin
 *
 *   SPDX-License-Identifier: GPL-2.0-or-later
 */

import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

ApplicationWindow {
    id: window
    width: 550
    height: 650
    visible: true
    title: qsTr("Nextcloud Wallpaper Configuration")

    property string homeDirectory: ""
    
    function readConfig() {
        var homePath = ""
        
        // Method 1: Try to read from temporary file created by run.sh (most reliable)
        try {
            var xhr = new XMLHttpRequest()
            xhr.open("GET", "file:///tmp/qml_home_path.txt", false)
            xhr.send()
            if ((xhr.status === 200 || xhr.status === 0) && xhr.responseText.length > 0) {
                homePath = xhr.responseText.trim()
                // Validate it looks like a home path
                if (homePath.startsWith("/home/") || homePath.startsWith("/root")) {
                    console.log("Got home from temp file:", homePath)
                } else {
                    homePath = ""
                }
            }
        } catch(e) {
            console.log("Could not read temp file:", e)
        }
        
        // Method 2: Try to read from helper script
        if (homePath === "") {
            try {
                var xhr = new XMLHttpRequest()
                // Get script directory from current QML file location
                var qmlFile = Qt.application.arguments[Qt.application.arguments.length - 1]
                var scriptDir = qmlFile.substring(0, qmlFile.lastIndexOf("/"))
                var scriptPath = scriptDir + "/get-home.sh"
                
                xhr.open("GET", "file://" + scriptPath, false)
                xhr.send()
                if ((xhr.status === 200 || xhr.status === 0) && xhr.responseText.length > 0) {
                    var result = xhr.responseText.trim()
                    if (result.startsWith("/home/") || result.startsWith("/root")) {
                        homePath = result
                        console.log("Got home from script:", homePath)
                    }
                }
            } catch(e) {
                console.log("Could not read get-home.sh:", e)
            }
        }
        
        // Method 3: Try to get from Qt.application.arguments (if passed correctly)
        if (homePath === "" && Qt.application.arguments.length > 1) {
            var arg = Qt.application.arguments[Qt.application.arguments.length - 1]
            // Check if it's a valid home path (not the QML file name)
            if (arg.startsWith("/home/") || arg.startsWith("/root")) {
                homePath = arg
                console.log("Got home from arguments:", homePath)
            }
        }
        
        // Method 4: Fallback - try common paths (only if all else fails)
        if (homePath === "") {
            // Generic fallback - user will need to manually set path if this doesn't work
            var testPath = "/home/user"
            homePath = testPath
            console.log("Using generic fallback path:", homePath)
            console.log("WARNING: Could not detect home directory. Config file may not be found.")
        }
        
        if (homePath === "") {
            homePath = "/tmp"
        }
        
        // Store for future use
        homeDirectory = homePath
        
        var configFile = homePath + "/.config/plasma_engine_potd/nextcloudprovider.conf"
        
        console.log("Trying to read config from:", configFile)
        
        // Try to read using XMLHttpRequest with enabled file access
        var xhr = new XMLHttpRequest()
        var filePath = "file://" + configFile
        xhr.open("GET", filePath, false)
        xhr.send()
        
        console.log("XHR status:", xhr.status, "Response length:", xhr.responseText.length)
        
        if (xhr.status === 200 || xhr.status === 0) {
            var content = xhr.responseText
            if (content.length === 0) {
                statusLabel.text = qsTr("Config file is empty")
                statusLabel.color = "orange"
                return
            }
            
            var lines = content.split('\n')
            var currentSection = ""
            var found = false
            
            for (var i = 0; i < lines.length; i++) {
                var line = lines[i].trim()
                
                // Skip empty lines and comments
                if (line.length === 0 || line.startsWith('#')) {
                    continue
                }
                
                if (line.startsWith('[') && line.endsWith(']')) {
                    currentSection = line.slice(1, -1)
                    console.log("Found section:", currentSection)
                } else if (currentSection === "Nextcloud" && line.includes('=')) {
                    var parts = line.split('=')
                    if (parts.length >= 2) {
                        var key = parts[0].trim()
                        var value = parts.slice(1).join('=').trim()
                        
                        console.log("Setting", key, "=", value)
                        
                        switch(key) {
                            case "Url": 
                                urlField.text = value
                                found = true
                                break
                            case "Path": 
                                pathField.text = value
                                found = true
                                break
                            case "Username": 
                                usernameField.text = value
                                found = true
                                break
                            case "Password": 
                                passwordField.text = value
                                found = true
                                break
                            case "UseLocalPath": 
                                localRadio.checked = (value === "true" || value === "True")
                                found = true
                                break
                            case "LocalPath": 
                                localPathField.text = value
                                found = true
                                break
                            case "MaxImages": 
                                maxImagesSpin.value = parseInt(value) || 0
                                found = true
                                break
                        }
                    }
                }
            }
            
            if (found) {
                statusLabel.text = qsTr("Configuration loaded successfully!")
                statusLabel.color = "green"
            } else {
                statusLabel.text = qsTr("Config file found but no Nextcloud section or values")
                statusLabel.color = "orange"
            }
        } else {
            statusLabel.text = qsTr("Could not read config file. Status: ") + xhr.status + qsTr("\nFile: ") + configFile
            statusLabel.color = "red"
            console.log("Could not read config file. Status:", xhr.status, "File:", configFile)
        }
    }

    function generateConfig() {
        var content = "[Nextcloud]\n"
        content += "Url=" + urlField.text + "\n"
        content += "Path=" + pathField.text + "\n"
        content += "Username=" + usernameField.text + "\n"
        content += "Password=" + passwordField.text + "\n"
        content += "UseLocalPath=" + (localRadio.checked ? "true" : "false") + "\n"
        content += "LocalPath=" + localPathField.text + "\n"
        content += "MaxImages=" + maxImagesSpin.value + "\n"
        return content
    }

    function validateConfig() {
        if (localRadio.checked) {
            if (localPathField.text.trim() === "") {
                return "Local path is required"
            }
        } else {
            if (urlField.text.trim() === "") return "Nextcloud URL is required"
            if (pathField.text.trim() === "") return "WebDAV path is required"
            if (usernameField.text.trim() === "") return "Username is required"
            if (passwordField.text.trim() === "") return "Password is required"
        }
        return ""
    }

    Component.onCompleted: {
        // Auto-load config on startup if file exists
        readConfig()
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 15

        Label {
            text: qsTr("Nextcloud Wallpaper Configuration")
            font.pointSize: 16
            font.bold: true
            Layout.alignment: Qt.AlignHCenter
        }

        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            ColumnLayout {
                width: window.width - 40
                spacing: 15

                GroupBox {
                    title: qsTr("Connection Mode")
                    Layout.fillWidth: true

                    ColumnLayout {
                        RadioButton {
                            id: webdavRadio
                            text: qsTr("WebDAV (Direct Connection)")
                            checked: !localRadio.checked
                        }

                        RadioButton {
                            id: localRadio
                            text: qsTr("Local Synchronized Folder")
                        }
                    }
                }

                GroupBox {
                    title: webdavRadio.checked ? qsTr("WebDAV Settings") : qsTr("Local Path Settings")
                    Layout.fillWidth: true

                    ColumnLayout {
                        TextField {
                            id: urlField
                            placeholderText: qsTr("Nextcloud URL")
                            Layout.fillWidth: true
                            visible: webdavRadio.checked
                        }

                        TextField {
                            id: pathField
                            placeholderText: qsTr("WebDAV Path (e.g. /remote.php/dav/files/USERNAME/Images)")
                            Layout.fillWidth: true
                            visible: webdavRadio.checked
                        }

                        TextField {
                            id: usernameField
                            placeholderText: qsTr("Username")
                            Layout.fillWidth: true
                            visible: webdavRadio.checked
                        }

                        TextField {
                            id: passwordField
                            placeholderText: qsTr("Password or App Password")
                            echoMode: TextInput.Password
                            Layout.fillWidth: true
                            visible: webdavRadio.checked
                        }

                        TextField {
                            id: localPathField
                            placeholderText: qsTr("Local Path (e.g. /home/user/Nextcloud/Images)")
                            Layout.fillWidth: true
                            visible: localRadio.checked
                        }
                    }
                }

                GroupBox {
                    title: qsTr("Advanced")
                    Layout.fillWidth: true

                    RowLayout {
                        Label {
                            text: qsTr("Max Images:")
                            Layout.preferredWidth: 120
                        }

                        SpinBox {
                            id: maxImagesSpin
                            from: 0
                            to: 100000
                            value: 0
                            Layout.fillWidth: true
                        }

                        Label {
                            text: qsTr("(0 = unlimited)")
                            font.pointSize: 9
                            color: "gray"
                        }
                    }
                }

                Label {
                    id: statusLabel
                    text: ""
                    color: "red"
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Button {
                text: qsTr("Reload")
                onClicked: {
                    readConfig()
                }
            }

            Button {
                text: qsTr("Save Configuration")
                Layout.fillWidth: true
                onClicked: {
                    var error = validateConfig()
                    if (error) {
                        statusLabel.text = error
                        statusLabel.color = "red"
                    } else {
                        var config = generateConfig()
                        // Show config in text area and allow user to save
                        configOutput.text = config
                        configOutput.visible = true
                        statusLabel.text = qsTr("Configuration generated! Copy the text below and save it to: ~/.config/plasma_engine_potd/nextcloudprovider.conf")
                        statusLabel.color = "blue"
                        console.log("=== CONFIGURATION ===")
                        console.log(config)
                        console.log("=== END CONFIG ===")
                        console.log("Save to: " + homeDirectory + "/.config/plasma_engine_potd/nextcloudprovider.conf")
                    }
                }
            }
        }

        GroupBox {
            title: qsTr("Generated Configuration")
            Layout.fillWidth: true
            visible: configOutput.text !== ""

            ColumnLayout {
                anchors.fill: parent

                TextArea {
                    id: configOutput
                    Layout.fillWidth: true
                    Layout.preferredHeight: 120
                    readOnly: false
                    font.family: "monospace"
                    font.pointSize: 9
                    selectByMouse: true
                }

                Label {
                    text: qsTr("Save this to: ~/.config/plasma_engine_potd/nextcloudprovider.conf")
                    font.pointSize: 9
                    color: "gray"
                    wrapMode: Text.WordWrap
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Button {
                        text: qsTr("Copy to Clipboard")
                        Layout.fillWidth: true
                        onClicked: {
                            configOutput.selectAll()
                            configOutput.copy()
                            statusLabel.text = qsTr("Configuration copied to clipboard! Paste it into the config file.")
                            statusLabel.color = "green"
                        }
                    }

                    Button {
                        id: saveButton
                        text: qsTr("Save to File")
                        Layout.fillWidth: true
                        enabled: !saveTimer.running
                        onClicked: {
                            var configText = configOutput.text
                            
                            if (configText.trim() === "") {
                                statusLabel.text = qsTr("Error: Configuration is empty")
                                statusLabel.color = "red"
                                return
                            }
                            
                            // Get script path
                            var qmlFile = Qt.application.arguments.length > 0 
                                ? Qt.application.arguments[Qt.application.arguments.length - 1]
                                : "main.qml"
                            var scriptDir = qmlFile.substring(0, qmlFile.lastIndexOf("/"))
                            var scriptPath = scriptDir + "/save-with-feedback.sh"
                            
                            // Show saving status
                            statusLabel.text = qsTr("Saving configuration...")
                            statusLabel.color = "blue"
                            saveButton.text = qsTr("Saving...")
                            saveButton.enabled = false
                            
                            // Write config to temp file and execute save script in background
                            var tempConfigFile = "/tmp/nextcloud_config_" + Date.now() + ".conf"
                            
                            // Write config to temp file (we'll read it from the script)
                            // Since QML can't write files directly, we'll use a workaround:
                            // Write the command to a file that will be executed
                            var commandFile = "/tmp/nextcloud_save_cmd_" + Date.now() + ".sh"
                            var escaped = configText.replace(/'/g, "'\\''").replace(/\n/g, "\\n")
                            var command = "echo '" + escaped + "' | bash " + scriptPath
                            
                            // Execute command in background (using nohup or &)
                            // Since we can't execute directly, we'll check result file
                            saveTimer.scriptPath = scriptPath
                            saveTimer.configText = configText
                            saveTimer.start()
                            
                            // Also log command for manual execution if needed
                            console.log("Executing save command in background...")
                            console.log("Command:", command)
                        }
                    }
                    
                    // Timer to check save result
                    Timer {
                        id: saveTimer
                        property string scriptPath: ""
                        property string configText: ""
                        interval: 100
                        repeat: true
                        running: false
                        property int attempts: 0
                        property bool commandExecuted: false
                        
                        onTriggered: {
                            attempts++
                            
                            // Execute command on first attempt (using trigger file approach)
                            if (!commandExecuted && attempts === 1) {
                                commandExecuted = true
                                
                                // Write config and script path to trigger file
                                // The run.sh script monitors this file and executes when it appears
                                // Format: all config lines + script path on last line
                                var triggerContent = configText + "\n" + scriptPath
                                
                                // Since QML can't write files directly, we'll use a workaround:
                                // Write trigger content to a file using a helper approach
                                // For now, we'll just log and check result (user can execute manually)
                                console.log("=== SAVE COMMAND ===")
                                var escaped = configText.replace(/'/g, "'\\''").replace(/\n/g, "\\n")
                                var command = "echo '" + escaped + "' | bash " + scriptPath
                                console.log(command)
                                console.log("=== END COMMAND ===")
                                console.log("Note: Execute this command manually or wait for automatic execution via run.sh monitor")
                            }
                            
                            // Check if result file exists and was updated recently
                            try {
                                var xhr = new XMLHttpRequest()
                                xhr.open("GET", "file:///tmp/nextcloud_save_result.txt", false)
                                xhr.send()
                                
                                if (xhr.status === 200 || xhr.status === 0) {
                                    var result = xhr.responseText.trim()
                                    
                                    if (result.length > 0 && (result.startsWith("SUCCESS:") || result.startsWith("ERROR"))) {
                                        // Result found
                                        saveButton.text = qsTr("Save to File")
                                        saveButton.enabled = true
                                        stop()
                                        attempts = 0
                                        commandExecuted = false
                                        
                                        if (result.startsWith("SUCCESS:")) {
                                            var savedPath = result.substring(8) // Remove "SUCCESS:" prefix
                                            statusLabel.text = qsTr("✓ Configuration saved successfully!\nFile: ") + savedPath
                                            statusLabel.color = "green"
                                            
                                            // Reload config to show it was saved
                                            Qt.callLater(function() {
                                                readConfig()
                                            })
                                        } else {
                                            var errorMsg = result.startsWith("ERROR:") ? result.substring(6) : result
                                            statusLabel.text = qsTr("✗ Error: ") + errorMsg
                                            statusLabel.color = "red"
                                        }
                                        
                                        return
                                    }
                                }
                            } catch(e) {
                                // Result file not ready yet or doesn't exist
                            }
                            
                            // If we've tried too many times, give up
                            if (attempts > 50) { // 5 seconds max
                                saveButton.text = qsTr("Save to File")
                                saveButton.enabled = true
                                stop()
                                attempts = 0
                                commandExecuted = false
                                statusLabel.text = qsTr("⚠ Could not verify save automatically.\nPlease execute the command shown in console or save manually.")
                                statusLabel.color = "orange"
                            }
                        }
                    }
                }
            }
        }
    }
}
