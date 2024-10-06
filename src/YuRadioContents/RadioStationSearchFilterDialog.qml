pragma ComponentBehavior: Bound

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

    function forEachTag(callback: var): void {
        for (var i = 0; i < tagsModel.count; ++i) {
            let section = tagsModel.get(i).sectionData;
            for (var j = 0; j < section.count; ++j) {
                let tag = section.get(j);
                callback(tag);
            }
        }
    }

    function selectedTags(): var {
        let tags = [];
        forEachTag(tag => {
            if (tag.selected) {
                tags.push(tag.tagName);
            }
        });
        console.log("SELECTED TAGS", tags);
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
    }

    onAboutToShow: {}

    onAccepted: {
        let tags = selectedTags();
        if (internal.prevSelectedCountry == countryCombo.currentIndex && internal.prevSelectedState == stateCombo.currentIndex && internal.prevSelectedLanguage == languageCombo.currentIndex && internal.prevSelectedTags.sort().join('@') == tags.sort().join('@')) {} else {
            root.filtersChanged(selectedCountry, selectedState, selectedLanguage, tags);
        }
        internal.prevSelectedCountry = countryCombo.currentIndex;
        internal.prevSelectedState = stateCombo.currentIndex;
        internal.prevSelectedLanguage = languageCombo.currentIndex;
        internal.prevSelectedTags = tags;
    }

    onRejected: {
        countryCombo.restore(internal.prevSelectedCountry);
        stateCombo.restore(internal.prevSelectedState);
        languageCombo.restore(internal.prevSelectedLanguage);
        forEachTag(tag => tag.selected = internal.prevSelectedTags.includes(tag.tagName));
    }

    StateGroup {
        states: [
            State {
                name: "scrollView"
                when: columnLayout.implicitHeight > scrollView.height
                PropertyChanges {
                    tagsView.Layout.preferredHeight: 300
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
                wrapMode: Text.WordWrap
            }

            GridLayout {
                Layout.topMargin: 20
                columns: 2

                ScalableLabel {
                    id: countryLabel

                    Layout.fillWidth: true

                    text: qsTr("Country")
                    elide: Text.ElideRight
                }

                CustomHeaderComboBox {
                    id: countryCombo

                    Layout.fillWidth: true
                    Layout.leftMargin: 10
                    Accessible.name: countryLabel.text

                    model: Storage.getCountries()
                }

                ScalableLabel {
                    id: stateText

                    Layout.fillWidth: true

                    text: qsTr("State")
                    elide: Text.ElideRight
                }

                CustomHeaderComboBox {
                    id: stateCombo

                    Layout.fillWidth: true
                    Layout.leftMargin: 10
                    Accessible.name: stateText.text

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
                    id: languageLabel

                    Layout.fillWidth: true

                    text: qsTr("Language")
                    elide: Text.ElideRight
                }

                CustomHeaderComboBox {
                    id: languageCombo

                    Layout.fillWidth: true
                    Layout.leftMargin: 10
                    Accessible.name: languageLabel.text

                    model: Storage.getLanguages()
                }
            }

            ScalableLabel {
                id: tagsLabel

                Layout.topMargin: 10
                Layout.fillWidth: true

                text: qsTr("Tags")
            }

            ListView {
                id: tagsView

                function getSections(words) {
                    return Object.values(words.reduce((acc, word) => {
                        let c = word[0].toLocaleUpperCase();
                        let isNumeric = Utils.isNumericChar(c);
                        if (isNumeric) {
                            c = "0";
                        }
                        let sectionObject = {
                            "tagName": word,
                            "selected": false
                        };
                        if (acc[c])
                            acc[c].sectionData.push(sectionObject);
                        else
                            acc[c] = {
                                "title": isNumeric ? "0-9" : c,
                                "sectionData": [sectionObject]
                            };
                        return acc;
                    }, {}));
                }

                model: ListModel {
                    id: tagsModel

                    Component.onCompleted: {
                        let sections = tagsView.getSections(Storage.getTags());
                        sections.forEach(section => {
                            tagsModel.append(section);
                        });
                    }
                }

                spacing: 5
                clip: true
                Layout.fillWidth: true
                Layout.fillHeight: true
                Accessible.name: tagsLabel.text

                delegate: Flow {
                    id: tagsDelegate

                    required property int index
                    required property string title
                    required property var sectionData

                    width: ListView.view.width
                    height: implicitHeight

                    spacing: 4

                    ScalableLabel {
                        id: tagLabel

                        text: tagsDelegate.title
                        height: tagsRepeater.buttonHeight
                        fontPointSize: 14

                        verticalAlignment: Text.AlignVCenter
                        Material.foreground: Material.accent
                        font.bold: true
                    }

                    Item {
                        width: 5
                        height: tagLabel.height
                    }

                    Repeater {
                        id: tagsRepeater

                        property int buttonHeight

                        model: tagsDelegate.sectionData

                        OutlinedButton {
                            id: outlinedButtonDelegate

                            required property int index
                            required property string tagName
                            required property bool selected
                            required property var model

                            focusPolicy: Qt.StrongFocus
                            height: Math.max(implicitHeight, 40 * AppSettings.fontScale)

                            onHeightChanged: {
                                tagsRepeater.buttonHeight = height;
                            }

                            leftPadding: 12
                            rightPadding: 12
                            topInset: 3
                            bottomInset: 3

                            checkable: true
                            checked: selected

                            onClicked: {
                                model.selected = checked;
                            }

                            text: tagName
                        }
                    }
                }
            }
        }
    }

    component CustomHeaderComboBox: HeaderComboBox {
        function resetInput() {
            currentIndex = -1;
            editText = "";
        }

        function restore(index) {
            currentIndex = index;
            editText = textAt(currentIndex);
        }

        editable: true
        currentIndex: -1

        fontPointSize: 13

        onAccepted: {
            if (find(editText) === -1) {
                resetInput();
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
