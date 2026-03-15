import QtQuick

Rectangle {
    id: card
    property string title: ""
    property bool collapsible: false
    property bool expanded: true
    default property alias content: contentCol.data

    radius: 16
    color: Qt.rgba(1, 1, 1, 0.03)
    border.width: 1
    border.color: Qt.rgba(1, 1, 1, 0.05)
    implicitHeight: col.implicitHeight + 24

    Column {
        id: col
        anchors.fill: parent
        anchors.margins: 12

        // Header
        Item {
            width: parent.width
            height: card.title !== "" ? 36 : 0
            visible: card.title !== ""

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: card.title
                color: Qt.rgba(1, 1, 1, 0.8)
                font.pixelSize: 14
                font.weight: Font.Medium
            }

            Text {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                visible: card.collapsible
                text: card.expanded ? "▾" : "▸"
                color: Qt.rgba(1, 1, 1, 0.3)
                font.pixelSize: 14
            }

            MouseArea {
                anchors.fill: parent
                visible: card.collapsible
                cursorShape: Qt.PointingHandCursor
                onClicked: card.expanded = !card.expanded
            }
        }

        // Content
        Column {
            id: contentCol
            width: parent.width
            visible: card.expanded
            spacing: 8
        }
    }
}
