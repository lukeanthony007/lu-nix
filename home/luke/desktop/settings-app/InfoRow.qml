import QtQuick

Item {
    property string label: ""
    property string value: ""
    width: parent ? parent.width : 200
    height: 28

    Text {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        text: label
        color: Qt.rgba(1, 1, 1, 0.5)
        font.pixelSize: 13
    }
    Text {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        text: value
        color: Qt.rgba(1, 1, 1, 0.85)
        font.pixelSize: 13
        font.family: "monospace"
    }
}
