import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts

import Main
import YuRest

Dialog {
    id: root

    readonly property var selectedCountry: countryCombo.currentIndex !== -1 ? countryModel.get(countryCombo.currentIndex).name : undefined
    readonly property var selectedState: stateCombo.currentIndex !== -1 ? stateModel.get(stateCombo.currentIndex).name : undefined
    readonly property var selectedLanguage: languageCombo.currentIndex !== -1 ? languageModel.get(languageCombo.currentIndex).name : undefined

    function selectedTags() {
        let selectedTags = [];
        for (let i = 0; i < tagsRepeater.count; i++) {
            let item = tagsRepeater.itemAt(i);
            if (item.checked) {
                selectedTags.push(item.name);
            }
        }
        return selectedTags;
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

            ComboBox {
                id: countryCombo

                Layout.fillWidth: true
                Layout.leftMargin: 10

                implicitHeight: 40

                editable: true

                textRole: "name"
                font.pointSize: 13
                popup.font.pointSize: font.pointSize

                model: JsonRestListModel {
                    id: countryModel
                    restManager: root.networkManager
                    pagination: LimitPagination {
                        id: countriesPagination
                        offset: 0
                        limit: totalCount
                        totalCount: 400
                    }

                    orderByQuery: "order"
                    orderBy: "stationcount"
                    filters: {
                        "reverse": true
                    }
                    path: "/json/countries"

                    preprocessItem: item => item.name && item.iso_3166_1 ? item : undefined

                    fetchMoreHandler: () => {
                        loadPage();
                        pagination.nextPage();
                    }
                }

                Binding {
                    target: countryCombo.popup.contentItem
                    property: "header"
                    value: Component {
                        ItemDelegate {
                            text: "SELECT ALL"
                            width: ListView.view.width
                            onClicked: {
                                countryCombo.currentIndex = -1;
                                countryCombo.popup.close();
                            }
                        }
                    }
                }

                onAccepted: {
                    if (find(editText) === -1) {
                        editText = textAt(0);
                    }
                }
            }

            Label {
                id: stateText
                text: qsTr("State")
            }

            ComboBox {
                id: stateCombo
                Layout.fillWidth: true
                Layout.leftMargin: 10
                implicitHeight: 40

                implicitContentWidthPolicy: ComboBox.WidestTextWhenCompleted
                editable: true
                textRole: "name"

                font.pointSize: 13
                popup.font.pointSize: font.pointSize

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
                    filters: {
                        "reverse": true
                    }

                    path: countryCombo.currentIndex !== -1 ? `/json/states/${countryModel.get(countryCombo.currentIndex).name}/` : '/json/states'

                    fetchMoreHandler: () => {
                        loadPage();
                        pagination.nextPage();
                    }

                    onPathChanged: {
                        statesPagination.offset = 0;
                        stateModel.reset();
                    }
                }

                onAccepted: {
                    if (find(editText) === -1) {
                        editText = textAt(0);
                    }
                }
            }

            Label {
                text: qsTr("Language")
            }

            ComboBox {
                id: languageCombo
                Layout.fillWidth: true
                Layout.leftMargin: 10

                displayText: currentIndex === -1 ? "Station Language" : currentText
                implicitHeight: 40
                font.pointSize: 13
                popup.font.pointSize: font.pointSize

                editable: true
                textRole: "name"

                model: JsonRestListModel {
                    id: languageModel
                    restManager: root.networkManager
                    pagination: LimitPagination {
                        id: languagesPagination
                        offset: 0
                        limit: totalCount
                        totalCount: 300
                    }

                    orderByQuery: "order"
                    orderBy: "stationcount"
                    filters: {
                        "reverse": true
                    }

                    path: "/json/languages"

                    preprocessItem: item => item.name && item.iso_639 ? item : undefined

                    fetchMoreHandler: () => {
                        loadPage();
                        pagination.nextPage();
                    }
                }

                onAccepted: {
                    if (find(editText) === -1) {
                        editText = textAt(0);
                    }
                }
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
                    model: JsonRestListModel {
                        id: tagsModel
                        restManager: root.networkManager
                        pagination: LimitPagination {
                            id: tagsPagination
                            offset: 0
                            limit: totalCount
                            totalCount: 50
                        }

                        orderByQuery: "order"
                        orderBy: "stationcount"
                        filters: {
                            "reverse": true
                        }

                        path: "/json/tags"

                        fetchMoreHandler: () => {
                            loadPage();
                            pagination.nextPage();
                        }
                    }

                    OutlinedButton {
                        required property int index
                        required property string name

                        focusPolicy: Qt.NoFocus

                        checkable: true
                        implicitHeight: 35

                        text: name
                    }
                }
            }
        }
    }

    Connections {
        target: root.networkManager
        function onBaseUrlChanged() {
            languageModel.reset();
            countryModel.reset();
            stateModel.reset();
            tagsModel.reset();
        }
    }
}
