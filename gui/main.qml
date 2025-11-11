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
    width: 600
    height: 700
    visible: true
    title: qsTr("Nextcloud Wallpaper Configuration")

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 15

        Label {
            text: qsTr("Nextcloud Wallpaper Provider Configuration")
            font.pointSize: 18
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
                        anchors.fill: parent

                        RadioButton {
                            id: webdavRadio
                            text: qsTr("WebDAV (Direct Connection)")
                            checked: !configManager.useLocalPath
                            onToggled: configManager.useLocalPath = false
                        }

                        RadioButton {
                            id: localRadio
                            text: qsTr("Local Synchronized Folder")
                            checked: configManager.useLocalPath
                            onToggled: configManager.useLocalPath = true
                        }
                    }
                }

                GroupBox {
                    title: webdavRadio.checked ? qsTr("WebDAV Settings") : qsTr("Local Path Settings")
                    Layout.fillWidth: true
                    visible: true

                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 10

                        // WebDAV fields
                        TextField {
                            id: urlField
                            placeholderText: qsTr("Nextcloud URL (e.g. https://nextcloud.example.com)")
                            text: configManager.nextcloudUrl
                            onTextChanged: configManager.nextcloudUrl = text
                            Layout.fillWidth: true
                            visible: webdavRadio.checked
                        }

                        TextField {
                            id: pathField
                            placeholderText: qsTr("WebDAV Path (e.g. /remote.php/dav/files/USERNAME/Images)")
                            text: configManager.nextcloudPath
                            onTextChanged: configManager.nextcloudPath = text
                            Layout.fillWidth: true
                            visible: webdavRadio.checked
                        }

                        TextField {
                            id: usernameField
                            placeholderText: qsTr("Username")
                            text: configManager.username
                            onTextChanged: configManager.username = text
                            Layout.fillWidth: true
                            visible: webdavRadio.checked
                        }

                        TextField {
                            id: passwordField
                            placeholderText: qsTr("Password or App Password")
                            text: configManager.password
                            echoMode: TextInput.Password
                            onTextChanged: configManager.password = text
                            Layout.fillWidth: true
                            visible: webdavRadio.checked
                        }

                        // Local path field
                        RowLayout {
                            Layout.fillWidth: true
                            visible: localRadio.checked

                            TextField {
                                id: localPathField
                                placeholderText: qsTr("Local Path (e.g. /home/user/Nextcloud/Images)")
                                text: configManager.localPath
                                onTextChanged: configManager.localPath = text
                                Layout.fillWidth: true
                            }

                            Button {
                                text: qsTr("Browse...")
                                onClicked: {
                                    const path = configManager.browseFolder()
                                    if (path) {
                                        configManager.localPath = path
                                    }
                                }
                            }
                        }
                    }
                }

                GroupBox {
                    title: qsTr("Advanced Settings")
                    Layout.fillWidth: true

                    ColumnLayout {
                        anchors.fill: parent

                        RowLayout {
                            Label {
                                text: qsTr("Max Images:")
                                Layout.preferredWidth: 150
                            }

                            SpinBox {
                                id: maxImagesSpin
                                from: 0
                                to: 100000
                                value: configManager.maxImages
                                onValueChanged: configManager.maxImages = value
                                Layout.fillWidth: true
                            }

                            Label {
                                text: qsTr("(0 = unlimited)")
                                font.pointSize: 9
                                color: "gray"
                            }
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
                text: qsTr("Load Configuration")
                onClicked: {
                    configManager.loadConfig()
                    statusLabel.text = qsTr("Configuration loaded")
                    statusLabel.color = "green"
                }
            }

            Button {
                text: qsTr("Save Configuration")
                Layout.fillWidth: true
                onClicked: {
                    const error = configManager.validateConfig()
                    if (error) {
                        statusLabel.text = error
                        statusLabel.color = "red"
                    } else {
                        if (configManager.saveConfig()) {
                            statusLabel.text = qsTr("Configuration saved successfully!")
                            statusLabel.color = "green"
                        } else {
                            statusLabel.text = qsTr("Failed to save configuration")
                            statusLabel.color = "red"
                        }
                    }
                }
            }
        }
    }
}

