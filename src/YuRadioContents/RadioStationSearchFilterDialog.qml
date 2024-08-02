pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts

import network

Dialog {
    id: root

    readonly property var selectedCountry: countryCombo.currentIndex !== -1 ? countryCombo.model[countryCombo.currentIndex] : undefined
    readonly property var selectedState: stateCombo.currentIndex !== -1 ? stateModel.get(stateCombo.currentIndex).name : undefined
    readonly property var selectedLanguage: languageCombo.currentIndex !== -1 ? languageCombo.model[languageCombo.currentIndex] : undefined

    function selectedTags() {
        let selectedTags = [];
        for (let i = 0; i < tagsRepeater.count; i++) {
            let item = tagsRepeater.itemAt(i);
            if (item.checked) {
                selectedTags.push(item.modelData);
            }
        }
        return selectedTags;
    }

    QtObject {
        id: internal
    }
    property int _prevSelectedCountry
    property int _prevSelectedState
    property int _prevSelectedLanguage
    property list<int> _prevSelectedTags

    required property NetworkManager networkManager

    Binding {
        when: AppSettings.isDarkTheme
        root.Material.background: root.Material.color(Material.Grey, Material.Shade900)
    }

    Material.roundedScale: Material.NotRounded
    standardButtons: Dialog.Ok | Dialog.Cancel

    onOpened: {
        if (stateModel.status == JsonRestListModel.Error) {
            stateModel.reset();
        }
        _prevSelectedCountry = countryCombo.currentIndex;
        _prevSelectedState = stateCombo.currentIndex;
        _prevSelectedLanguage = languageCombo.currentIndex;
        _prevSelectedTags = [];
        for (let i = 0; i < tagsRepeater.count; i++) {
            if (tagsRepeater.itemAt(i).checked) {
                _prevSelectedTags.push(i);
            }
        }
    }

    onRejected: {
        for (let i = 0; i < tagsRepeater.count; i++) {
            let item = tagsRepeater.itemAt(i);
            item.checked = _prevSelectedTags.includes(i);
        }
        countryCombo.currentIndex = _prevSelectedCountry;
        stateCombo.currentIndex = _prevSelectedState;
        languageCombo.currentIndex = _prevSelectedLanguage;
    }

    ColumnLayout {
        anchors.fill: parent

        Label {
            text: qsTr("Search Filters")
            font.bold: true
            font.pointSize: 18
        }

        GridLayout {
            Layout.topMargin: 20
            columns: 2

            Label {
                text: qsTr("Country")
            }

            HeaderComboBox {
                id: countryCombo

                Layout.fillWidth: true
                Layout.leftMargin: 10

                implicitHeight: 40

                editable: true
                currentIndex: -1

                font.pointSize: 13
                popup.font.pointSize: font.pointSize

                model: Storage.getCountries()
            }

            Label {
                id: stateText
                text: qsTr("State")
            }

            HeaderComboBox {
                id: stateCombo
                Layout.fillWidth: true
                Layout.leftMargin: 10
                implicitHeight: 40

                implicitContentWidthPolicy: ComboBox.WidestTextWhenCompleted
                editable: true
                textRole: "name"

                font.pointSize: 13
                popup.font.pointSize: font.pointSize
                currentIndex: -1

                model: JsonRestListModel {
                    id: stateModel
                    restManager: root.networkManager
                    pagination: LimitPagination {
                        id: statesPagination
                        offset: 0
                        limit: totalCount
                        totalCount: 300
                    }

                    orderByQuery: "order"
                    orderBy: "stationcount"
                    filters: [
                      RestListModelFilter {
                        key: "reverse"
                        value: true
                      }
                    ]

                    path: root.selectedCountry ? `/json/states/${root.selectedCountry}/` : '/json/states'

                    fetchMoreHandler: () => {
                        loadPage();
                        pagination.nextPage();
                    }

                    onPathChanged: {
                        statesPagination.offset = 0;
                        stateModel.reset();
                    }
                }
            }

            Label {
                text: qsTr("Language")
            }

            HeaderComboBox {
                id: languageCombo
                Layout.fillWidth: true
                Layout.leftMargin: 10

                currentIndex: -1
                displayText: currentIndex === -1 ? "Station Language" : currentText
                implicitHeight: 40
                font.pointSize: 13
                popup.font.pointSize: font.pointSize

                editable: true

                model: Storage.getLanguages()
            }
        }

        Label {
            Layout.topMargin: 10
            text: qsTr("Tags")
        }

        Flickable {
            id: tagsFlickable
            Layout.fillHeight: true
            Layout.fillWidth: true
            Layout.topMargin: 10

            clip: true

            boundsBehavior: Flickable.StopAtBounds

            contentHeight: tagsFlow.implicitHeight
            contentWidth: tagsFlow.implicitWidth

            Flow {
                id: tagsFlow
                width: tagsFlickable.width

                spacing: 4

                Repeater {
                    id: tagsRepeater
                    model: Storage.getTags()

                    OutlinedButton {
                        required property int index
                        required property string modelData

                        focusPolicy: Qt.NoFocus

                        checkable: true
                        implicitHeight: 35

                        text: modelData
                    }
                }
            }
        }
    }

    Connections {
        target: root.networkManager
        function onBaseUrlChanged() {
            stateModel.reset();
        }
    }
}
