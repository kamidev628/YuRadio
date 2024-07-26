import QtQuick
import QtQuick.Controls.Material
import QtQuick.Controls
import QtQuick.Layouts

Drawer {
    id: drawer

    width: Math.min(parent.width, parent.height) / 3 * 2
    height: parent.height

    Material.roundedScale: Material.NotRounded

    Image {
        id: image
        anchors.fill: parent
        fillMode: Image.PreserveAspectFit
        asynchronous: true
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 20

        Image {
            id: profileImage
            source: "images/profile-picture.jpg"
            asynchronous: true
            smooth: true
            visible: false
        }

        ShaderEffectSource {
            id: shaderEffectSource
            sourceItem: profileImage
        }

        ShaderEffect {
            Layout.preferredWidth: parent.width * 2 / 3
            Layout.preferredHeight: parent.width * 2 / 3

            property variant source: shaderEffectSource

            fragmentShader: "qrc:/shaders/RoundImage.frag.qsb"
        }

        ListView {
            focus: true
            currentIndex: -1

            Layout.fillHeight: true
            Layout.fillWidth: true
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            ScrollIndicator.vertical: ScrollIndicator {}

            model: ListModel {
                ListElement {
                    text: qsTr("About")
                    iconName: "help-about"
                    iconSource: "images/about.svg"
                    triggered: function () {
                        aboutDialog.open();
                    }
                }
            }

            delegate: ItemDelegate {
                required property ListModel model

                width: parent.width
                text: model.text
                icon.source: model.iconSource
                icon.name: model.iconName
                highlighted: ListView.isCurrentItem
                onClicked: {
                    drawer.close();
                    model.triggered();
                }
            }
        }

        Row {
            Layout.alignment: Qt.AlignHCenter

            Text {
                text: "Dark"
                anchors.verticalCenter: parent.verticalCenter
                color: Material.primaryTextColor
            }
            Switch {
                id: themeSwitch
                checked: !AppSettings.isDarkTheme
                onClicked: {
                    AppSettings.theme = Qt.binding(() => {
                        return checked ? "Light" : "Dark";
                    });
                }
            }
            Text {
                text: "Light"
                anchors.verticalCenter: parent.verticalCenter
                color: Material.primaryTextColor
            }
        }
    }
}
