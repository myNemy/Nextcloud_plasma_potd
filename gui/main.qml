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

    property string configPath: {
        var home = Qt.application.arguments.length > 0 ? Qt.application.arguments[0] : ""
        // Try to get from environment or use default
        var homeDir = ""
        try {
            // Use a simple approach - hardcode the path
            homeDir = "/home/" + (typeof process !== 'undefined' ? process.env.USER : "user")
        } catch(e) {
            homeDir = "/tmp"
        }
        return homeDir + "/.config/plasma_engine_potd/nextcloudprovider.conf"
    }
    
    // Simpler approach - use fixed path
    property string simpleConfigPath: "/home/" + (typeof process !== 'undefined' ? process.env.USER : "user") + "/.config/plasma_engine_potd/nextcloudprovider.conf"

    property string homeDirectory: ""
    
    function readConfig() {
        var homePath = ""
        
        // Method 1: Try to get from Qt.application.arguments (passed by run.sh)
        if (Qt.application.arguments.length > 1) {
            homePath = Qt.application.arguments[1]
            console.log("Got home from arguments:", homePath)
        }
        
        // Method 2: Try to read from temporary file created by run.sh
        if (homePath === "") {
            try {
                var xhr = new XMLHttpRequest()
                xhr.open("GET", "file:///tmp/qml_home_path.txt", false)
                xhr.send()
                if ((xhr.status === 200 || xhr.status === 0) && xhr.responseText.length > 0) {
                    homePath = xhr.responseText.trim()
                    console.log("Got home from temp file:", homePath)
                }
            } catch(e) {
                console.log("Could not read temp file:", e)
            }
        }
        
        // Method 3: Try to read from helper script
        if (homePath === "") {
            try {
                var xhr = new XMLHttpRequest()
                var scriptPath = Qt.application.arguments.length > 0 
                    ? Qt.application.arguments[0].replace(/\/[^\/]*$/, "") + "/get-home.sh"
                    : "./get-home.sh"
                xhr.open("GET", "file://" + scriptPath, false)
                xhr.send()
                if (xhr.status === 200 || xhr.status === 0) {
                    homePath = xhr.responseText.trim()
                    console.log("Got home from script:", homePath)
                }
            } catch(e) {
                console.log("Could not read get-home.sh:", e)
            }
        }
        
        // Method 4: Fallback - try common paths
        if (homePath === "") {
            var possibleUsers = ["nemeyes", "user"]
            for (var i = 0; i < possibleUsers.length; i++) {
                var testPath = "/home/" + possibleUsers[i]
                homePath = testPath
                console.log("Using fallback path:", homePath)
                break
            }
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
                        console.log("Save to: " + configPath)
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
                        text: qsTr("Save to File")
                        Layout.fillWidth: true
                        onClicked: {
                            var configText = configOutput.text
                            
                            // Get script path
                            var scriptPath = Qt.application.arguments.length > 0 
                                ? Qt.application.arguments[0].replace(/\/[^\/]*$/, "") + "/save-config.sh"
                                : "./save-config.sh"
                            
                            // Create command
                            var escaped = configText.replace(/'/g, "'\\''").replace(/\n/g, "\\n")
                            var command = "echo '" + escaped + "' | bash " + scriptPath
                            
                            // Show command and instructions
                            statusLabel.text = qsTr("To save, run this command in terminal:\n\n") + 
                                             command + 
                                             qsTr("\n\nOr copy the configuration text above and save manually to:\n~/.config/plasma_engine_potd/nextcloudprovider.conf")
                            statusLabel.color = "blue"
                            
                            // Also log to console for easy copy
                            console.log("=== COPY THIS COMMAND ===")
                            console.log(command)
                            console.log("=== OR COPY CONFIG TEXT ===")
                            console.log(configText)
                        }
                    }
                }
            }
        }
    }
}
