import QtQuick
import QtQuick.Layouts
import Quickshell.Io

Item {
    property string currentWp: "..."
    property string wpCount: "..."
    property string wpDirSize: "..."

    Flickable {
        anchors.fill: parent
        anchors.margins: 24
        contentHeight: col.implicitHeight
        clip: true

        ColumnLayout {
            id: col
            width: parent.width
            spacing: 16

            Text { text: "Wallpapers"; color: "white"; font.pixelSize: 20; font.weight: Font.Bold }

            GlassCard {
                Layout.fillWidth: true
                title: "Current"

                InfoRow { label: "Active wallpaper"; value: currentWp }
                InfoRow { label: "Total wallpapers"; value: wpCount }
                InfoRow { label: "Collection size"; value: wpDirSize }
            }

            GlassCard {
                Layout.fillWidth: true
                title: "Actions"

                Item {
                    width: parent.width
                    height: 36

                    Text {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Randomize wallpaper now"
                        color: Qt.rgba(1, 1, 1, 0.5)
                        font.pixelSize: 13
                    }

                    Rectangle {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        width: 100; height: 30; radius: 8
                        color: randMa.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(1, 1, 1, 0.06)
                        border.width: 1; border.color: Qt.rgba(1, 1, 1, 0.1)

                        Text { anchors.centerIn: parent; text: "Randomize"; color: Qt.rgba(1, 1, 1, 0.8); font.pixelSize: 12 }

                        MouseArea {
                            id: randMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: randomizeProc.running = true
                        }
                    }
                }
            }
        }
    }

    Process { id: _cw; running: true; command: ["sh", "-c", "cat $HOME/.local/state/DankMaterialShell/session.json 2>/dev/null | jq -r '.wallpaperPath // \"none\"' 2>/dev/null | xargs basename 2>/dev/null || echo 'none'"]; stdout: SplitParser { splitMarker: ""; onRead: data => currentWp = data.trim() } }
    Process { id: _wc; running: true; command: ["sh", "-c", "find $HOME/Pictures/Wallpapers -type f \\( -name '*.jpg' -o -name '*.png' -o -name '*.jpeg' \\) 2>/dev/null | wc -l"]; stdout: SplitParser { splitMarker: ""; onRead: data => wpCount = data.trim() } }
    Process { id: _ws; running: true; command: ["sh", "-c", "du -sh $HOME/Pictures/Wallpapers 2>/dev/null | cut -f1 || echo '0'"]; stdout: SplitParser { splitMarker: ""; onRead: data => wpDirSize = data.trim() } }

    Process {
        id: randomizeProc; running: false
        command: ["sh", "-c", "WP=$(find $HOME/Pictures/Wallpapers -type f \\( -name '*.jpg' -o -name '*.png' \\) | shuf -n1) && jq -n --arg wp \"$WP\" '{wallpaperPath:$wp,wallpaperPathDark:$wp,wallpaperPathLight:$wp}' > $HOME/.local/state/DankMaterialShell/session.json"]
    }
}
