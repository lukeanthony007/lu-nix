import QtQuick
import QtQuick.Layouts
import Quickshell.Io

Item {
    property var serviceList: [
        "dms", "foot-autostart", "bootstrap", "clone-nvchad",
        "clone-wallpapers", "lazy-wallpapers", "random-wallpaper",
        "vscode-extensions", "cloud-sync"
    ]
    property var serviceStates: ({})

    Flickable {
        anchors.fill: parent
        anchors.margins: 24
        contentHeight: col.implicitHeight
        clip: true

        ColumnLayout {
            id: col
            width: parent.width
            spacing: 16

            Text { text: "Services"; color: "white"; font.pixelSize: 20; font.weight: Font.Bold }

            GlassCard {
                Layout.fillWidth: true
                title: "User Services"

                Repeater {
                    model: serviceList

                    Item {
                        width: parent.width
                        height: 32

                        Text {
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            text: modelData + ".service"
                            color: Qt.rgba(1, 1, 1, 0.8)
                            font.pixelSize: 13
                            font.family: "monospace"
                        }

                        Rectangle {
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            width: stateText.implicitWidth + 16
                            height: 22
                            radius: 6
                            color: {
                                var s = serviceStates[modelData] || "unknown";
                                if (s === "active") return Qt.rgba(0.29, 0.85, 0.5, 0.15);
                                if (s === "inactive") return Qt.rgba(1, 1, 1, 0.05);
                                if (s.indexOf("failed") >= 0) return Qt.rgba(0.97, 0.44, 0.44, 0.15);
                                return Qt.rgba(1, 1, 1, 0.05);
                            }

                            Text {
                                id: stateText
                                anchors.centerIn: parent
                                text: serviceStates[modelData] || "..."
                                color: {
                                    var s = serviceStates[modelData] || "unknown";
                                    if (s === "active") return "#4ade80";
                                    if (s.indexOf("failed") >= 0) return "#f87171";
                                    return Qt.rgba(1, 1, 1, 0.5);
                                }
                                font.pixelSize: 11
                                font.family: "monospace"
                            }
                        }
                    }
                }
            }
        }
    }

    Process {
        id: svcCheck
        running: false
        command: ["sh", "-c", "for s in " + serviceList.join(" ") + "; do printf '%s:%s\\n' \"$s\" \"$(systemctl --user is-active $s.service 2>/dev/null || echo unknown)\"; done"]

        stdout: SplitParser {
            splitMarker: ""
            onRead: data => {
                var states = {};
                var lines = data.trim().split("\n");
                for (var i = 0; i < lines.length; i++) {
                    var parts = lines[i].split(":");
                    if (parts.length >= 2) states[parts[0]] = parts[1];
                }
                serviceStates = states;
            }
        }
    }

    Timer {
        interval: 3000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: svcCheck.running = true
    }
}
