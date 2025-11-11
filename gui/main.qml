/*
 *   SPDX-FileCopyrightText: 2024 Nextcloud Wallpaper Plugin
 *
 *   SPDX-License-Identifier: GPL-2.0-or-later
 */

import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Dialogs 1.3

ApplicationWindow {
    id: window
    width: 550
    height: 650
    visible: true
    title: qsTr("Nextcloud Wallpaper Configuration")

    property string configPath: Qt.StandardPaths.writableLocation(Qt.StandardPaths.ConfigLocation) + "/plasma_engine_potd/nextcloudprovider.conf"

    function readConfig() {
        var file = Qt.createQmlObject('import QtQuick 2.15; QtObject {}', window)
        var xhr = new XMLHttpRequest()
        xhr.open("GET", "file://" + configPath, false)
        xhr.send()
        
        if (xhr.status === 200) {
            var content = xhr.responseText
            // Simple INI parser
            var lines = content.split('\n')
            var currentSection = ""
            
            for (var i = 0; i < lines.length; i++) {
                var line = lines[i].trim()
                if (line.startsWith('[') && line.endsWith(']')) {
                    currentSection = line.slice(1, -1)
                } else if (currentSection === "Nextcloud" && line.includes('=')) {
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
        }
    }

    function writeConfig() {
        var content = "[Nextcloud]\n"
        content += "Url=" + urlField.text + "\n"
        content += "Path=" + pathField.text + "\n"
        content += "Username=" + usernameField.text + "\n"
        content += "Password=" + passwordField.text + "\n"
        content += "UseLocalPath=" + (localRadio.checked ? "true" : "false") + "\n"
        content += "LocalPath=" + localPathField.text + "\n"
        content += "MaxImages=" + maxImagesSpin.value + "\n"
        
        var file = Qt.createQmlObject('import QtQuick 2.15; QtObject {}', window)
        var xhr = new XMLHttpRequest()
        xhr.open("PUT", "file://" + configPath, false)
        xhr.send(content)
        
        return xhr.status === 200 || xhr.status === 0
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

    FileDialog {
        id: folderDialog
        selectFolder: true
        onAccepted: {
            localPathField.text = folderDialog.fileUrl.toString().replace("file://", "")
        }
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

                        RowLayout {
                            visible: localRadio.checked
                            Layout.fillWidth: true

                            TextField {
                                id: localPathField
                                placeholderText: qsTr("Local Path")
                                Layout.fillWidth: true
                            }

                            Button {
                                text: qsTr("Browse...")
                                onClicked: folderDialog.open()
                            }
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
                text: qsTr("Save")
                Layout.fillWidth: true
                onClicked: {
                    var error = validateConfig()
                    if (error) {
                        statusLabel.text = error
                        statusLabel.color = "red"
                    } else {
                        if (writeConfig()) {
                            statusLabel.text = qsTr("Configuration saved!")
                            statusLabel.color = "green"
                        } else {
                            statusLabel.text = qsTr("Failed to save")
                            statusLabel.color = "red"
                        }
                    }
                }
            }
        }
    }
}

