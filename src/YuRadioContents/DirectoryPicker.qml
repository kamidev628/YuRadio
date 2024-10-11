import QtQuick
import QtCore
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

import Main

Item {
    id: root

    required property AudioStreamRecorder recorder

    implicitWidth: textField.implicitWidth
    implicitHeight: textField.implicitHeight

    TextField {
        id: textField

        anchors.fill: parent

        readOnly: true
        rightPadding: folderImage.width
        text: decodeURIComponent(root.recorder.outputLocation.toString())

        onReleased: {
            folderDialog.open();
        }

        Image {
            id: folderImage

            source: "images/folder.svg"
            sourceSize: Qt.size(width * Screen.devicePixelRatio, height * Screen.devicePixelRatio)
            fillMode: Image.PreserveAspectFit
            smooth: true

            width: height + 5

            anchors {
                top: parent.top
                bottom: parent.bottom
                right: parent.right

                topMargin: 5
                bottomMargin: 5
            }
        }
    }

    FolderDialog {
        id: folderDialog
        currentFolder: StandardPaths.standardLocations(StandardPaths.MusicLocation)[0]
        selectedFolder: root.recorder.outputLocation

        onSelectedFolderChanged: {
            root.recorder.outputLocation = selectedFolder;
        }
    }
}
