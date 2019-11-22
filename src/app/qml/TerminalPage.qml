/*
 * Copyright (C) 2014 Canonical Ltd
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 3 as
 * published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Authored-by: Filippo Scognamiglio <flscogna@gmail.com>
 */
import QtQuick 2.4
import Ubuntu.Components 1.3
import Ubuntu.Components.Popups 1.3
import Ubuntu.Components.Extras 0.3
import QMLTermWidget 1.0
import GSettings 1.0

// For FastBlur
import QtGraphicalEffects 1.0

Page {
    id: terminalPage
    property alias terminalContainer: terminalContainer
    property Terminal terminal
    property var tabsModel
    property bool narrowLayout
    theme: ThemeSettings {
        name: tabsBar.isDarkBackground ? "Ubuntu.Components.Themes.SuruDark"
                                       : "Ubuntu.Components.Themes.Ambiance"
    }

    function openSettingsPage() {
        if (!settingsLoader.item) {
            settingsLoader.active = true;
        } else {
            settingsLoader.item.requestActivate();
        }
    }

    Loader {
        id: settingsLoader
        source: Qt.resolvedUrl("Settings/SettingsWindow.qml")
        active: false
        asynchronous: true

        Connections {
            target: settingsLoader.item
            onClosing: settingsLoader.active = false
        }
    }


    anchors.fill: parent

    header: PageHeader {
        title: i18n.tr("Terminal")
        StyleHints {
            foregroundColor: terminalPage.terminal.foregroundColor
            backgroundColor: tabsBar.color
            dividerColor: UbuntuColors.slate
        }
        visible: terminalPage.narrowLayout ? true : false

        AbstractButton {
            id: settingsButton
            height: width
            width: units.gu(4)
            anchors {
                top: parent.top
                right: parent.right
                margins: units.gu(1)
            }
            visible: terminalPage.narrowLayout

            onClicked: openSettingsPage()

            Rectangle {
                anchors.fill: parent
                color: Theme.palette.selected.background
                visible: parent.pressed
            }

            Icon {
                anchors.centerIn: parent
                color: tabsBar.actionColor
                height: width
                width: units.gu(2.5)
                name: "settings"
            }
        }

        AbstractButton {
            id: tabsButton
            height: width
            width: units.gu(4)
            anchors {
                top: parent.top
                right: settingsButton.left
                margins: units.gu(1)
            }
            visible: terminalPage.narrowLayout

            onClicked: pageStack.push(tabsPage)

            Rectangle {
                anchors.fill: parent
                color: Theme.palette.selected.background
                visible: parent.pressed
            }

            Icon {
                anchors.centerIn: parent
                color: tabsBar.actionColor
                height: width
                width: units.gu(2.5)
                name: "browser-tabs"
            }
        }

        AbstractButton {
            id: closeSelectionButton
            height: width
            width: units.gu(4)
            anchors {
                top: parent.top
                right: parent.right
                margins: units.gu(1)
            }
            visible: false

            onClicked: {
              terminalPage.state = "DEFAULT";
              PopupUtils.open(Qt.resolvedUrl("AlternateActionPopover.qml"));
            }

            Rectangle {
                anchors.fill: parent
                color: Theme.palette.selected.background
                visible: parent.pressed
            }

            Icon {
                anchors.centerIn: parent
                color: tabsBar.actionColor
                height: width
                width: units.gu(2.5)
                name: "close"
            }
        }
    }

    TabsBar {
        id: tabsBar
        anchors {
            left: parent.left
            top: parent.top
            right: parent.right
        }
        property bool isDarkBackground: terminalPage.terminal && terminalPage.terminal.isDarkBackground
        actionColor: isDarkBackground ? "white" : "black"
        backgroundColor: terminalPage.terminal ? terminalPage.terminal.backgroundColor : ""
        foregroundColor: terminalPage.terminal ? terminalPage.terminal.foregroundColor : ""
        contourColor: terminalPage.terminal ? terminalPage.terminal.contourColor : ""
        color: isDarkBackground ? Qt.tint(backgroundColor, "#0DFFFFFF") : Qt.tint(backgroundColor, "#0D000000")
        model: terminalPage.tabsModel
        visible: !terminalPage.narrowLayout
        function titleFromModelItem(modelItem) {
            return modelItem.focusedTerminal ? modelItem.focusedTerminal.session.title : "";
        }

        AbstractButton {
            id: settingsButtonTab
            height: width
            width: units.gu(2)
            anchors {
                top: parent.top
                right: parent.right
                margins: units.gu(0.5)
            }
            visible: !terminalPage.narrowLayout

            onClicked: openSettingsPage()

            Icon {
                anchors.centerIn: parent
                color: tabsBar.actionColor
                height: width
                width: units.gu(2)
                name: "settings"
            }
        }

        AbstractButton {
            id: tabsButtonTab
            height: width
            width: units.gu(2)
            anchors {
                top: parent.top
                right: settingsButtonTab.left
                topMargin: units.gu(0.5)
                rightMargin: units.gu(1)
            }
            visible: !terminalPage.narrowLayout

            onClicked: pageStack.push(tabsPage)

            Icon {
                anchors.centerIn: parent
                color: tabsBar.actionColor
                height: width
                width: units.gu(2)
                name: "browser-tabs"
            }
        }

        AbstractButton {
            id: closeSelectionButtonTab
            height: width
            width: units.gu(2)
            anchors {
                top: parent.top
                right: parent.right
                margins: units.gu(0.5)
            }
            visible: false

            onClicked: {
              terminalPage.state = "DEFAULT";
              PopupUtils.open(Qt.resolvedUrl("AlternateActionPopover.qml"));
            }

            Icon {
                anchors.centerIn: parent
                color: tabsBar.actionColor
                height: width
                width: units.gu(2)
                name: "close"
            }
        }
    }

    Item {
        id: terminalContainer

        anchors {
            left: parent.left;
            top: terminalPage.narrowLayout ? header.bottom : tabsBar.bottom;
            right: parent.right;
            bottom: keyboardBarLoader.top
        }

        Binding {
            target: tabsModel.currentItem
            property: "focus"
            value: true
        }
    }

    Loader {
        id: keyboardBarLoader
        height: active ? units.gu(5) : 0
        anchors {left: parent.left; right: parent.right}
        active: !QuickUtils.keyboardAttached

        y: parent.height - height - Qt.inputMethod.keyboardRectangle.height
        z: parent.z + 0.1

        sourceComponent: KeyboardBar {
            height: units.gu(5)
            backgroundColor: tabsBar.color
            foregroundColor: tabsBar.foregroundColor
            onSimulateKey: terminal.simulateKeyPress(key, mod, true, 0, "");
            onSimulateCommand: terminal.focusedTerminal.session.sendText(command);
        }
    }

    Loader {
        id: bottomMessage

        height: units.gu(5)
        anchors {left: parent.left; right: parent.right}

        y: parent.height - height - Qt.inputMethod.keyboardRectangle.height
        z: parent.z + 0.2

        active: false
        sourceComponent:  Rectangle {
            anchors.fill: parent
            color: "black"
            opacity: 0.9

            Label {
                anchors.centerIn: parent
                color: "white"
                text: i18n.tr("Selection Mode")
            }
        }
    }

    GSettings {
        id: unity8Settings
        schema.id: "com.canonical.Unity8"
    }

    Loader {
        id: keyboardButton
        active: !QuickUtils.keyboardAttached || unity8Settings.alwaysShowOsk
        anchors {right: parent.right; margins: units.gu(1)}

        y: parent.height - height - units.gu(1) - keyboardBarLoader.height

        sourceComponent: CircularTransparentButton {
            backgroundColor: tabsBar.color
            iconColor: tabsBar.actionColor
            action: Action {
                iconName: "input-keyboard-symbolic"
                onTriggered: {
                    Qt.inputMethod.show();
                    terminal.forceActiveFocus();
                }
            }
        }
    }

    Loader {
        id: returnButton
        active: !QuickUtils.keyboardAttached || unity8Settings.alwaysShowOsk
        anchors {right: keyboardButton.left; margins: units.gu(2)}
        y: parent.height - height - units.gu(1) - keyboardBarLoader.height

        sourceComponent: CircularTransparentButton {
            backgroundColor: tabsBar.color
            iconColor: tabsBar.actionColor
            action: Action {
                id: pressAction
                iconName: "keyboard-enter"
                onTriggered: {
                    terminal.simulateKeyPress(Qt.Key_Enter, Qt.NoModifier, true, 0, "");
                }
            }
        }
    }

    state: "DEFAULT"
    states: [
        State {
            name: "DEFAULT"
            PropertyChanges { target: settingsButton; iconName: "settings" }
        },
        State {
            name: "SELECTION"
            PropertyChanges { target: closeSelectionButton; visible: true }
            PropertyChanges { target: closeSelectionButtonTab; visible: true }
            PropertyChanges { target: settingsButton; visible: false }
            PropertyChanges { target: settingsButtonTab; visible: false }
            PropertyChanges { target: tabsButton; visible: false }
            PropertyChanges { target: tabsButtonTab; visible: false }
            PropertyChanges { target: keyboardButton; visible: false }
            PropertyChanges { target: returnButton; visible: false }
            PropertyChanges { target: bottomMessage; active: true }
            PropertyChanges { target: keyboardBarLoader; enabled: false }
        }
    ]
}
