import QtQuick
import QtQuick.Layouts
import Quickshell.Io

Item {
    anchors.fill: parent

    property bool compact: parent.width < 700
    property bool tiny: parent.width < 500

    ColumnLayout {
        anchors.centerIn: parent
        width: Math.min(parent.width - (tiny ? 40 : compact ? 80 : 160), 700)
        spacing: 0

        // Title
        Text {
            Layout.alignment: Qt.AlignHCenter
            text: "Welcome to lu-nix"
            color: "white"
            font.pixelSize: tiny ? 22 : compact ? 28 : 36
            font.weight: Font.Bold
        }
        Text {
            Layout.alignment: Qt.AlignHCenter
            Layout.bottomMargin: compact ? 20 : 40
            text: "Setting up your system"
            color: Qt.rgba(1, 1, 1, 0.5)
            font.pixelSize: tiny ? 12 : 16
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

                    // Inline task row — avoids required property issues
                    Item {
                        width: taskCol.width
                        height: 56

                        // Status dot
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

                        // Name
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

                        // Description
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
            Layout.preferredHeight: root.showCloudPicker ? 160 : 0
            visible: root.showCloudPicker
            clip: true

            Behavior on Layout.preferredHeight { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }

            ColumnLayout {
                anchors.fill: parent
                anchors.topMargin: 24
                spacing: 16

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Choose your cloud storage"
                    color: Qt.rgba(1, 1, 1, 0.8)
                    font.pixelSize: 16
                    font.weight: Font.Medium
                }

                Flow {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.fillWidth: true
                    Layout.leftMargin: 16
                    Layout.rightMargin: 16
                    spacing: 12
                    flow: Flow.LeftToRight

                    Repeater {
                        model: [
                            { pid: "b2", label: "Backblaze B2" },
                            { pid: "gdrive", label: "Google Drive" },
                            { pid: "onedrive", label: "OneDrive" }
                        ]

                        Rectangle {
                            width: compact ? Math.min(160, (parent.width - 24) / 3) : 160
                            height: 44
                            radius: 12
                            color: providerMa.containsMouse ? Qt.rgba(1,1,1,0.12) : Qt.rgba(1,1,1,0.06)
                            border.width: 1; border.color: Qt.rgba(1,1,1,0.1)
                            Behavior on color { ColorAnimation { duration: 150 } }

                            Text {
                                anchors.centerIn: parent
                                text: modelData.label
                                color: Qt.rgba(1,1,1,0.85)
                                font.pixelSize: 14
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
                    font.pixelSize: 13

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.skipCloud()
                    }
                }
            }
        }

        // Spacer
        Item { Layout.preferredHeight: 24 }

        // Progress bar
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 6
            radius: 3
            color: Qt.rgba(1, 1, 1, 0.08)

            Rectangle {
                width: parent.width * root.progress
                height: parent.height
                radius: 3

                color: Qt.rgba(1, 1, 1, 0.7)

                Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
            }
        }

        // Status
        Text {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 12
            text: root.statusText
            color: Qt.rgba(1,1,1,0.4)
            font.pixelSize: 13
        }

        // Debug log
        Item { Layout.preferredHeight: compact ? 8 : 16 }

        GlassCard {
            Layout.fillWidth: true
            Layout.preferredHeight: compact ? 100 : 140

            Flickable {
                anchors.fill: parent
                anchors.margins: 8
                contentHeight: logText.implicitHeight
                clip: true

                Text {
                    id: logText
                    width: parent.width
                    text: logView.text() || "(waiting for log...)"
                    color: Qt.rgba(1, 1, 1, 0.5)
                    font.pixelSize: 10
                    font.family: "monospace"
                    wrapMode: Text.Wrap
                }
            }
        }
    }

    FileView {
        id: logView
        path: root.home + "/.local/state/bootstrap.log"
        watchChanges: true
        printErrors: false

        onLoaded: logText.text = logView.text() || "(empty log)"
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: {
            var t = logView.text();
            if (t && t.length > 0) logText.text = t;
        }
    }
}
