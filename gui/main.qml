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

    function readConfig() {
        // Use a simpler path
        var path = Qt.application.arguments.length > 0 
            ? Qt.application.arguments[0].replace(/\/[^\/]*$/, "") + "/.config/plasma_engine_potd/nextcloudprovider.conf"
            : "/home/" + (typeof process !== 'undefined' ? process.env.USER : "user") + "/.config/plasma_engine_potd/nextcloudprovider.conf"
        
        // Try to read using XMLHttpRequest with enabled file access
        var xhr = new XMLHttpRequest()
        var filePath = "file://" + path
        xhr.open("GET", filePath, false)
        xhr.send()
        
        if (xhr.status === 200 || xhr.status === 0) {
            var content = xhr.responseText
            var lines = content.split('\n')
            var currentSection = ""
            
            for (var i = 0; i < lines.length; i++) {
                var line = lines[i].trim()
                if (line.startsWith('[') && line.endsWith(']')) {
                    currentSection = line.slice(1, -1)
                } else if (currentSection === "Nextcloud" && line.includes('=') && !line.startsWith('#')) {
                    var parts = line.split('=')
                    var key = parts[0].trim()
                    var value = parts.slice(1).join('=').trim()
                    
                    switch(key) {
                        case "Url": urlField.text = value; break
                        case "Path": pathField.text = value; break
                        case "Username": usernameField.text = value; break
                        case "Password": passwordField.text = value; break
                        case "UseLocalPath": localRadio.checked = (value === "true"); break
                        case "LocalPath": localPathField.text = value; break
                        case "MaxImages": maxImagesSpin.value = parseInt(value) || 0; break
                    }
                }
            }
        } else {
            console.log("Could not read config file. Status:", xhr.status)
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
                text: qsTr("Load")
                onClicked: {
                    readConfig()
                    statusLabel.text = qsTr("Configuration loaded")
                    statusLabel.color = "green"
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

                Button {
                    text: qsTr("Save to File")
                    Layout.fillWidth: true
                    onClicked: {
                        // Use helper script to save
                        var process = Qt.createQmlObject('import QtQuick 2.15; QtObject {}', window)
                        statusLabel.text = qsTr("Run this command to save: echo '...' > ~/.config/plasma_engine_potd/nextcloudprovider.conf")
                        statusLabel.color = "orange"
                    }
                }
            }
        }
    }
}
