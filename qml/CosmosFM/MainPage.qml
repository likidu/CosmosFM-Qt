import QtQuick 1.1
import com.nokia.symbian 1.1
import QtMobility.systeminfo 1.2

Page {
    id: mainPage



    DeviceInfo {
        id: deviceinfo
        monitorBatteryLevelChanges: true
    }

    Text {
        id: text1
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        text: qsTr("Battery Status: %1%").arg(progressbar1.value)
        color: platformStyle.colorNormalLight
        font.pixelSize: 20
    }

    ProgressBar {
        id: progressbar1
        anchors.horizontalCenterOffset: 0
        anchors.horizontalCenter: text1.horizontalCenter
        anchors.top: text1.bottom
        anchors.topMargin: 20
        minimumValue: 0
        maximumValue: 100
        value: deviceinfo.batteryLevel
    }

    tools: ToolBarLayout {
        ToolButton {
            iconSource: "toolbar-back"
            onClicked: quitTimer.running ? Qt.quit() : quitTimer.start()
            Timer {
                id: quitTimer
                interval: infoBanner.timeout
                onRunningChanged: if (running) infoBanner.showMessage("再按一次退出")
            }
        }

        ToolButton {
            iconSource: "toolbar-search"
            onClicked: pageStack.push(Qt.resolvedUrl("SearchPage.qml"))
        }

        ToolButton {
            iconSource: "toolbar-menu"
            onClicked: mainMenu.open()
        }
    }

    Menu {
        id: mainMenu
        x: 0
        y: 351
        MenuLayout {
            MenuItem {
                text: "Settings"
                onClicked: pageStack.push(Qt.resolvedUrl("SettingsPage.qml"))
            }
            MenuItem {
                text: "Send Feedback"
                onClicked: pageStack.push(Qt.resolvedUrl("FeedbackPage.qml"))
            }
            MenuItem {
                text: "About"
                onClicked: pageStack.push(Qt.resolvedUrl("AboutPage.qml"))
            }
        }
    }

    Flickable {
        id: flickable1
        x: 20
        y: 179
        width: 300
        height: 300

        Column {
            id: column1
            x: 50
            y: 35
            width: 200
            height: 400

            ToolButton {
                anchors {
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                }
                iconSource: "assets/contacts.svg"
                // onClicked: user.loggedIn ? pageStack.push(Qt.resolvedUrl("UserInfoPage.qml"), {userId: qmlApi.getUserId()})
                // : pageStack.push(Qt.resolvedUrl("LoginPage.qml"))
                onClicked: pageStack.push(Qt.resolvedUrl("LoginPage.qml"))
            }
        }
    }
}
