pragma ComponentBehavior

import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts

import network
import YuRadioContents
import Main

Dialog {
    id: root

    required property NetworkManager networkManager

    readonly property var selectedCountry: countryCombo.currentIndex !== -1 ? countryCombo.model[countryCombo.currentIndex] : undefined
    readonly property var selectedState: stateCombo.currentIndex !== -1 ? stateModel.get(stateCombo.currentIndex).name : undefined
    readonly property var selectedLanguage: languageCombo.currentIndex !== -1 ? languageCombo.model[languageCombo.currentIndex] : undefined

    signal filtersChanged(var country, var state, var language, var tags)

    function selectedTags(): var {
        let tags = [];
        for (let i = 0; i < tagsRepeater.count; i++) {
            let item = tagsRepeater.itemAt(i) as Button;
            if (item.checked) {
                tags.push(item.text);
            }
        }
        return tags;
    }

    Binding {
        when: AppConfig.isDarkTheme
        root.Material.background: root.Material.color(Material.Grey, Material.Shade900)
    }

    Material.roundedScale: Material.NotRounded
    standardButtons: Dialog.Ok | Dialog.Cancel

    onOpened: {
        if (stateModel.status == JsonRestListModel.Error) {
            stateModel.reset();
        }
        internal.prevSelectedCountry = countryCombo.currentIndex;
        internal.prevSelectedState = stateCombo.currentIndex;
        internal.prevSelectedLanguage = languageCombo.currentIndex;
        internal.prevSelectedTags = selectedTags();
    }

    onAccepted: {
        let tags = selectedTags();
        if (internal.prevSelectedCountry == countryCombo.currentIndex && internal.prevSelectedState == stateCombo.currentIndex && internal.prevSelectedLanguage == languageCombo.currentIndex && internal.prevSelectedTags.sort().join('@') == tags.sort().join('@')) {} else {
            root.filtersChanged(selectedCountry, selectedState, selectedLanguage, tags);
        }
    }

    onRejected: {
        for (let i = 0; i < tagsRepeater.count; i++) {
            let item = tagsRepeater.itemAt(i);
            item.checked = internal.prevSelectedTags.includes(item.text);
        }
        countryCombo.currentIndex = internal.prevSelectedCountry;
        stateCombo.currentIndex = internal.prevSelectedState;
        languageCombo.currentIndex = internal.prevSelectedLanguage;
    }

    StateGroup {
        states: [
            State {
                name: "scrollView"
                when: columnLayout.implicitHeight > scrollView.height
                PropertyChanges {
                    tagsFlickable.Layout.preferredHeight: 300
                    scrollView.contentHeight: columnLayout.implicitHeight
                    columnLayout.height: undefined
                }
            }
        ]
    }

    ScrollView {
        id: scrollView

        anchors.fill: parent

        contentWidth: -1
        contentHeight: -1

        ColumnLayout {
            id: columnLayout

            width: scrollView.width
            height: scrollView.height

            ScalableLabel {
                text: qsTr("Search Filters")

                Layout.fillWidth: true

                font.bold: true
                fontPointSize: 18
            }

            GridLayout {
                Layout.topMargin: 20
                columns: 2

                ScalableLabel {
                    Layout.fillWidth: true
                    text: qsTr("Country")
                }

                component CustomHeaderComboBox: HeaderComboBox {
                    editable: true
                    currentIndex: -1

                    fontPointSize: 13
                }

                CustomHeaderComboBox {
                    id: countryCombo

                    Layout.fillWidth: true
                    Layout.leftMargin: 10

                    model: Storage.getCountries()
                }

                ScalableLabel {
                    id: stateText

                    Layout.fillWidth: true

                    text: qsTr("State")
                }

                CustomHeaderComboBox {
                    id: stateCombo

                    Layout.fillWidth: true
                    Layout.leftMargin: 10

                    implicitContentWidthPolicy: ComboBox.WidestTextWhenCompleted
                    textRole: "name"

                    model: JsonRestListModel {
                        id: stateModel

                        restManager: root.networkManager
                        pagination: LimitPagination {
                            id: statesPagination
                            offset: 0
                            limit: totalCount
                            totalCount: 300
                        }

                        filters: [
                            RestListModelSortFilter {
                                key: "order"
                                value: "stationcount"
                            },
                            RestListModelSortFilter {
                                key: "reverse"
                                value: true
                            }
                        ]

                        path: root.selectedCountry ? `/json/states/${root.selectedCountry}/` : '/json/states'

                        fetchMoreHandler: () => {
                            loadPage();
                        }

                        onStatusChanged: {
                            if (status == JsonRestListModel.Ready) {
                                pagination.nextPage();
                            }
                        }

                        onPathChanged: {
                            statesPagination.offset = 0;
                            stateModel.reset();
                        }
                    }
                }

                ScalableLabel {
                    Layout.fillWidth: true

                    text: qsTr("Language")
                }

                CustomHeaderComboBox {
                    id: languageCombo

                    Layout.fillWidth: true
                    Layout.leftMargin: 10

                    model: Storage.getLanguages()
                }
            }

            ScalableLabel {
                Layout.topMargin: 10
                Layout.fillWidth: true

                text: qsTr("Tags")
            }

            ScrollableFlickable {
                id: tagsFlickable

                Layout.fillWidth: true
                Layout.fillHeight: true

                contentHeight: tagsFlow.implicitHeight
                contentWidth: tagsFlow.implicitWidth

                boundsBehavior: Flickable.StopAtBounds
                clip: true

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
                            height: 40 * AppSettings.fontScale

                            checkable: true

                            text: modelData
                        }
                    }
                }
            }
        }
    }

    QtObject {
        id: internal

        property int prevSelectedCountry: -1
        property int prevSelectedState: -1
        property int prevSelectedLanguage: -1
        property list<string> prevSelectedTags
    }

    Connections {
        target: root.networkManager

        function onBaseUrlChanged() {
            stateModel.reset();
        }
    }
}
