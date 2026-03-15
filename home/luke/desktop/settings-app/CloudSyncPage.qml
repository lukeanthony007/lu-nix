import QtQuick
import QtQuick.Layouts
import Quickshell.Io

Item {
    property string rcloneStatus: "..."
    property string providerChoice: "..."

    Flickable {
        anchors.fill: parent
        anchors.margins: 24
        contentHeight: col.implicitHeight
        clip: true

        ColumnLayout {
            id: col
            width: parent.width
            spacing: 16

            Text { text: "Cloud Sync"; color: "white"; font.pixelSize: 20; font.weight: Font.Bold }

            GlassCard {
                Layout.fillWidth: true
                title: "Configuration"

                InfoRow { label: "rclone config"; value: rcloneStatus }
                InfoRow { label: "Provider"; value: providerChoice }
            }

            GlassCard {
                Layout.fillWidth: true
                title: "Setup"

                Text {
                    width: parent.width
                    text: "Run 'rclone config' in a terminal to set up your cloud provider.\nThe bootstrap screen will detect the config on next run."
                    color: Qt.rgba(1, 1, 1, 0.5)
                    font.pixelSize: 12
                    wrapMode: Text.Wrap
                    lineHeight: 1.4
                }
            }
        }
    }

    Process { id: _rc; running: true; command: ["sh", "-c", "[ -f $HOME/.config/rclone/rclone.conf ] && echo 'configured' || echo 'not configured'"]; stdout: SplitParser { splitMarker: ""; onRead: data => rcloneStatus = data.trim() } }
    Process { id: _pr; running: true; command: ["sh", "-c", "cat $HOME/.local/state/bootstrap-state.json 2>/dev/null | jq -r '.provider // \"not set\"' 2>/dev/null || echo 'not set'"]; stdout: SplitParser { splitMarker: ""; onRead: data => providerChoice = data.trim() } }
}
