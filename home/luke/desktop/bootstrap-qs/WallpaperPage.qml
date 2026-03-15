import QtQuick
import QtQuick.Layouts
import Quickshell.Io

Item {
    anchors.fill: parent

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 40
        spacing: 0

        // Title
        Text {
            Layout.alignment: Qt.AlignHCenter
            text: "Choose a wallpaper"
            color: "white"
            font.pixelSize: 32
            font.weight: Font.Bold
        }
        Text {
            Layout.alignment: Qt.AlignHCenter
            Layout.bottomMargin: 24
            text: root.selectedWallpaperName || "Select a wallpaper to get started"
            color: Qt.rgba(1, 1, 1, 0.5)
            font.pixelSize: 14
        }

        // Wallpaper grid or empty state
        GlassCard {
            Layout.fillWidth: true
            Layout.fillHeight: true

            // Empty state
            Text {
                anchors.centerIn: parent
                visible: root.wallpaperPaths.length === 0
                text: "No wallpapers downloaded yet.\nClick Get Started to continue."
                color: Qt.rgba(1, 1, 1, 0.4)
                font.pixelSize: 14
                horizontalAlignment: Text.AlignHCenter
            }

            Flickable {
                anchors.fill: parent
                anchors.margins: 16
                contentHeight: wallpaperGrid.implicitHeight + logCard.height + 16
                clip: true
                visible: root.wallpaperPaths.length > 0

                GridLayout {
                    id: wallpaperGrid
                    width: parent.width
                    columns: 4
                    rowSpacing: 12
                    columnSpacing: 12

                    Repeater {
                        model: root.wallpaperPaths

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 130
                            radius: 12
                            clip: true
                            border.width: root.selectedWallpaperIndex === index ? 3 : 0
                            border.color: "#60a5fa"
                            color: Qt.rgba(1, 1, 1, 0.05)

                            Image {
                                anchors.fill: parent
                                anchors.margins: parent.border.width
                                source: "file://" + modelData
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                sourceSize.width: 240
                                sourceSize.height: 160

                                onStatusChanged: {
                                    if (status === Image.Error)
                                        console.warn("Failed to load: " + source)
                                }
                            }

                            Rectangle {
                                anchors.fill: parent
                                color: wpMa.containsMouse ? Qt.rgba(1,1,1,0.1) : "transparent"
                                radius: 12
                                Behavior on color { ColorAnimation { duration: 150 } }
                            }

                            MouseArea {
                                id: wpMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.selectedWallpaperIndex = index;
                                    var parts = modelData.split("/");
                                    root.selectedWallpaperName = parts[parts.length - 1];
                                }
                            }
                        }
                    }
                }

                // Debug log
                Rectangle {
                    id: logCard
                    anchors.top: wallpaperGrid.bottom
                    anchors.topMargin: 16
                    width: parent.width
                    height: 100
                    radius: 12
                    color: Qt.rgba(0, 0, 0, 0.3)

                    Text {
                        id: wpLogText
                        anchors.fill: parent
                        anchors.margins: 8
                        text: "(loading log...)"
                        color: Qt.rgba(1, 1, 1, 0.4)
                        font.pixelSize: 9
                        font.family: "monospace"
                        wrapMode: Text.Wrap
                        elide: Text.ElideRight
                    }
                }
            }
        }

        // Debug: show last 10 lines of log even when empty
        Text {
            Layout.fillWidth: true
            visible: root.wallpaperPaths.length === 0
            text: "Paths: " + root.wallpaperPaths.length + " | " + wpDebugLogText.text
            color: Qt.rgba(1, 1, 1, 0.3)
            font.pixelSize: 9
            font.family: "monospace"
            wrapMode: Text.Wrap
            maximumLineCount: 6
            elide: Text.ElideRight
        }

        Text {
            id: wpDebugLogText
            visible: false
            text: "(no log)"
        }

        Process {
            id: wpLogReader
            running: false
            command: ["sh", "-c", "tail -30 " + root.home + "/.local/state/bootstrap.log 2>/dev/null || echo '(no log)'"]
            stdout: SplitParser {
                splitMarker: ""
                onRead: data => {
                    wpLogText.text = data;
                    wpDebugLogText.text = data;
                }
            }
        }

        Timer {
            interval: 2000
            running: true
            repeat: true
            onTriggered: wpLogReader.running = true
        }

        Item { Layout.preferredHeight: 24 }

        // Bottom bar
        RowLayout {
            Layout.alignment: Qt.AlignRight
            spacing: 12

            // Random button
            Rectangle {
                width: 100; height: 44
                radius: 12
                color: randomMa.containsMouse ? Qt.rgba(1,1,1,0.1) : "transparent"
                Behavior on color { ColorAnimation { duration: 150 } }

                Text {
                    anchors.centerIn: parent
                    text: "Random"
                    color: Qt.rgba(1,1,1,0.6)
                    font.pixelSize: 14
                }

                MouseArea {
                    id: randomMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (root.wallpaperPaths.length > 0) {
                            var idx = Math.floor(Math.random() * root.wallpaperPaths.length);
                            root.selectedWallpaperIndex = idx;
                            var parts = root.wallpaperPaths[idx].split("/");
                            root.selectedWallpaperName = parts[parts.length - 1];
                        }
                    }
                }
            }

            // Get Started button
            Rectangle {
                width: 160; height: 44
                radius: 12
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: "#60a5fa" }
                    GradientStop { position: 1.0; color: "#a78bfa" }
                }

                Text {
                    anchors.centerIn: parent
                    text: "Get Started"
                    color: "white"
                    font.pixelSize: 15
                    font.weight: Font.DemiBold
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.getStarted()
                }
            }
        }
    }
}
