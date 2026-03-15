import QtQuick
import QtQuick.Layouts
import Quickshell.Io

Item {
    property string bootstrapLog: "(loading...)"
    property string bootstrapStatus: "(loading...)"

    Flickable {
        anchors.fill: parent
        anchors.margins: 24
        contentHeight: col.implicitHeight
        clip: true

        ColumnLayout {
            id: col
            width: parent.width
            spacing: 16

            Text { text: "Bootstrap"; color: "white"; font.pixelSize: 20; font.weight: Font.Bold }

            GlassCard {
                Layout.fillWidth: true
                title: "Status"

                InfoRow { label: "Marker file"; value: markerExists.text || "..." }
                InfoRow { label: "Status file"; value: statusExists.text || "..." }

                Item {
                    width: parent.width
                    height: 36

                    Text {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Re-run bootstrap"
                        color: Qt.rgba(1, 1, 1, 0.5)
                        font.pixelSize: 13
                    }

                    Rectangle {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        width: 100; height: 30; radius: 8
                        color: rerunMa.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(1, 1, 1, 0.06)
                        border.width: 1; border.color: Qt.rgba(1, 1, 1, 0.1)

                        Text {
                            anchors.centerIn: parent
                            text: "Reset"
                            color: "#f87171"
                            font.pixelSize: 12
                        }

                        MouseArea {
                            id: rerunMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: resetProc.running = true
                        }
                    }
                }
            }

            GlassCard {
                Layout.fillWidth: true
                title: "Bootstrap Log"
                collapsible: true

                Rectangle {
                    width: parent.width
                    height: 200
                    radius: 8
                    color: Qt.rgba(0, 0, 0, 0.3)
                    clip: true

                    Flickable {
                        anchors.fill: parent
                        anchors.margins: 8
                        contentHeight: logText.implicitHeight

                        Text {
                            id: logText
                            width: parent.width
                            text: bootstrapLog
                            color: Qt.rgba(1, 1, 1, 0.6)
                            font.pixelSize: 10
                            font.family: "monospace"
                            wrapMode: Text.Wrap
                        }
                    }
                }
            }

            GlassCard {
                Layout.fillWidth: true
                title: "Status JSON"
                collapsible: true
                expanded: false

                Rectangle {
                    width: parent.width
                    height: 120
                    radius: 8
                    color: Qt.rgba(0, 0, 0, 0.3)
                    clip: true

                    Text {
                        anchors.fill: parent
                        anchors.margins: 8
                        text: bootstrapStatus
                        color: Qt.rgba(1, 1, 1, 0.6)
                        font.pixelSize: 10
                        font.family: "monospace"
                        wrapMode: Text.Wrap
                    }
                }
            }
        }
    }

    Text { id: markerExists; visible: false }
    Text { id: statusExists; visible: false }

    Process { id: _me; running: true; command: ["sh", "-c", "[ -f $HOME/.local/state/bootstrap-done ] && echo 'exists (bootstrap complete)' || echo 'missing (will run on next login)'"]; stdout: SplitParser { splitMarker: ""; onRead: data => markerExists.text = data.trim() } }
    Process { id: _se; running: true; command: ["sh", "-c", "[ -f $HOME/.local/state/bootstrap-status.json ] && echo 'exists' || echo 'missing'"]; stdout: SplitParser { splitMarker: ""; onRead: data => statusExists.text = data.trim() } }

    Process { id: logReader; running: false; command: ["sh", "-c", "tail -40 $HOME/.local/state/bootstrap.log 2>/dev/null || echo '(no log file)'"]; stdout: SplitParser { splitMarker: ""; onRead: data => bootstrapLog = data } }
    Process { id: statusReader; running: false; command: ["sh", "-c", "cat $HOME/.local/state/bootstrap-status.json 2>/dev/null | jq . 2>/dev/null || echo '(no status file)'"]; stdout: SplitParser { splitMarker: ""; onRead: data => bootstrapStatus = data } }
    Process { id: resetProc; running: false; command: ["sh", "-c", "rm -f $HOME/.local/state/bootstrap-done $HOME/.local/state/bootstrap-status.json $HOME/.local/state/bootstrap.log"] }

    Timer { interval: 3000; running: true; repeat: true; triggeredOnStart: true; onTriggered: { logReader.running = true; statusReader.running = true } }
}
