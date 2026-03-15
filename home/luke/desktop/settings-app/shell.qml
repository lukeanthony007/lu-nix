import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

ShellRoot {
    id: root

    property int currentTab: 0
    property string home: Quickshell.env("HOME") || "/home/luke"

    FloatingWindow {
        id: settingsWindow
        visible: true
        color: "#0a0a0a"
        width: 900
        height: 640
        title: "lu-nix Settings"

        RowLayout {
            anchors.fill: parent
            spacing: 0

            // Sidebar
            Rectangle {
                Layout.preferredWidth: 220
                Layout.fillHeight: true
                color: Qt.rgba(1, 1, 1, 0.03)

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 4

                    // Title
                    Text {
                        text: "lu-nix"
                        color: "white"
                        font.pixelSize: 22
                        font.weight: Font.Bold
                        Layout.bottomMargin: 8
                        Layout.leftMargin: 8
                    }
                    Text {
                        text: "Settings"
                        color: Qt.rgba(1, 1, 1, 0.4)
                        font.pixelSize: 13
                        Layout.bottomMargin: 16
                        Layout.leftMargin: 8

                    }

                    // Nav items
                    Repeater {
                        model: [
                            { label: "System Info", icon: "\ue88e" },
                            { label: "Services", icon: "\ue8b8" },
                            { label: "Bootstrap", icon: "\ue863" },
                            { label: "Cloud Sync", icon: "\ue2c3" },
                            { label: "Wallpapers", icon: "\ue3f4" },
                            { label: "Debug", icon: "\ue868" }
                        ]

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 38
                            radius: 10
                            color: root.currentTab === index
                                ? Qt.rgba(1, 1, 1, 0.08)
                                : navMa.containsMouse ? Qt.rgba(1, 1, 1, 0.04) : "transparent"
                            Behavior on color { ColorAnimation { duration: 150 } }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 10

                                Text {
                                    text: modelData.icon
                                    font.pixelSize: 18
                                    font.family: "Material Symbols Rounded"
                                    color: root.currentTab === index ? Qt.rgba(1, 1, 1, 0.9) : Qt.rgba(1, 1, 1, 0.4)
                                }
                                Text {
                                    text: modelData.label
                                    color: root.currentTab === index ? "white" : Qt.rgba(1, 1, 1, 0.6)
                                    font.pixelSize: 13
                                    font.weight: root.currentTab === index ? Font.Medium : Font.Normal
                                    Layout.fillWidth: true
                                }
                            }

                            MouseArea {
                                id: navMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.currentTab = index
                            }
                        }
                    }

                    Item { Layout.fillHeight: true }

                    // Version
                    Text {
                        text: "lu-nix v0.1.0"
                        color: Qt.rgba(1, 1, 1, 0.2)
                        font.pixelSize: 11
                    }
                }
            }

            // Separator
            Rectangle {
                Layout.preferredWidth: 1
                Layout.fillHeight: true
                color: Qt.rgba(1, 1, 1, 0.06)
            }

            // Content area
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                Loader { anchors.fill: parent; active: root.currentTab === 0; sourceComponent: SystemInfoPage {} }
                Loader { anchors.fill: parent; active: root.currentTab === 1; sourceComponent: ServicesPage {} }
                Loader { anchors.fill: parent; active: root.currentTab === 2; sourceComponent: BootstrapPage {} }
                Loader { anchors.fill: parent; active: root.currentTab === 3; sourceComponent: CloudSyncPage {} }
                Loader { anchors.fill: parent; active: root.currentTab === 4; sourceComponent: WallpapersPage {} }
                Loader { anchors.fill: parent; active: root.currentTab === 5; sourceComponent: DebugPage {} }
            }
        }
    }
}
