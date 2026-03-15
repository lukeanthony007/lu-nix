import QtQuick
import QtQuick.Layouts

Item {
    id: setupPage
    anchors.fill: parent

    Flickable {
        anchors.fill: parent
        anchors.topMargin: 24
        anchors.bottomMargin: 24
        contentHeight: col.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        ColumnLayout {
            id: col
            x: (setupPage.width - width) / 2
            width: Math.min(setupPage.width - 60, 580)
            spacing: 0

            // Title
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "Welcome to lu-nix"
                color: "white"
                font.pixelSize: 36
                font.weight: Font.Bold
            }
            Text {
                Layout.alignment: Qt.AlignHCenter
                Layout.bottomMargin: 32
                text: "Setting up your system"
                color: Qt.rgba(1, 1, 1, 0.5)
                font.pixelSize: 15
            }

            // Task list card
            GlassCard {
                Layout.fillWidth: true
                Layout.preferredHeight: taskCol.implicitHeight + 16

                Column {
                    id: taskCol
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 8

                    Repeater {
                        model: root.tasks

                        Item {
                            width: taskCol.width
                            height: 56

                            Rectangle {
                                id: dot
                                x: 16
                                anchors.verticalCenter: parent.verticalCenter
                                width: 28; height: 28; radius: 14
                                color: modelData.state === "done" ? Qt.rgba(1, 1, 1, 0.12)
                                     : modelData.state === "running" ? Qt.rgba(1, 1, 1, 0.10)
                                     : modelData.state === "error" ? Qt.rgba(1, 1, 1, 0.08)
                                     : Qt.rgba(1, 1, 1, 0.04)

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.state === "done" ? "✓"
                                        : modelData.state === "running" ? "●"
                                        : modelData.state === "error" ? "✕"
                                        : "○"
                                    color: modelData.state === "done" ? Qt.rgba(1, 1, 1, 0.9)
                                         : modelData.state === "running" ? Qt.rgba(1, 1, 1, 0.7)
                                         : modelData.state === "error" ? Qt.rgba(1, 1, 1, 0.5)
                                         : Qt.rgba(1, 1, 1, 0.2)
                                    font.pixelSize: 13
                                }
                            }

                            Text {
                                anchors.left: dot.right
                                anchors.leftMargin: 16
                                anchors.right: parent.right
                                anchors.rightMargin: 16
                                anchors.bottom: parent.verticalCenter
                                anchors.bottomMargin: 1
                                text: modelData.name
                                color: Qt.rgba(1, 1, 1, 0.9)
                                font.pixelSize: 15
                                font.weight: Font.Medium
                                elide: Text.ElideRight
                            }

                            Text {
                                anchors.left: dot.right
                                anchors.leftMargin: 16
                                anchors.right: parent.right
                                anchors.rightMargin: 16
                                anchors.top: parent.verticalCenter
                                anchors.topMargin: 1
                                text: modelData.description
                                color: Qt.rgba(1, 1, 1, 0.5)
                                font.pixelSize: 12
                                elide: Text.ElideRight
                            }
                        }
                    }
                }
            }

            // Cloud provider picker
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: root.showCloudPicker ? cloudCol.implicitHeight + 24 : 0
                visible: root.showCloudPicker
                clip: true

                Behavior on Layout.preferredHeight { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }

                ColumnLayout {
                    id: cloudCol
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.topMargin: 24
                    spacing: 16

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "Choose your cloud storage"
                        color: Qt.rgba(1, 1, 1, 0.8)
                        font.pixelSize: 15
                        font.weight: Font.Medium
                    }

                    Row {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 12

                        Repeater {
                            model: [
                                { pid: "b2", label: "Backblaze B2" },
                                { pid: "gdrive", label: "Google Drive" },
                                { pid: "onedrive", label: "OneDrive" }
                            ]

                            Rectangle {
                                width: 150; height: 40
                                radius: 10
                                color: providerMa.containsMouse ? Qt.rgba(1,1,1,0.12) : Qt.rgba(1,1,1,0.06)
                                border.width: 1; border.color: Qt.rgba(1,1,1,0.1)
                                Behavior on color { ColorAnimation { duration: 150 } }

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.label
                                    color: Qt.rgba(1,1,1,0.85)
                                    font.pixelSize: 13
                                }

                                MouseArea {
                                    id: providerMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.selectProvider(modelData.pid)
                                }
                            }
                        }
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "Skip for now"
                        color: Qt.rgba(1,1,1,0.4)
                        font.pixelSize: 12

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.skipCloud()
                        }
                    }
                }
            }

            // Spacer
            Item { Layout.preferredHeight: 20 }

            // Progress bar
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 4
                radius: 2
                color: Qt.rgba(1, 1, 1, 0.08)

                Rectangle {
                    width: parent.width * root.progress
                    height: parent.height
                    radius: 2
                    color: Qt.rgba(1, 1, 1, 0.7)
                    Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
                }
            }

            // Status
            Text {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 10
                text: root.statusText
                color: Qt.rgba(1,1,1,0.4)
                font.pixelSize: 12
            }
        }
    }
}
