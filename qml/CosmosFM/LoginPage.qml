import QtQuick 1.1
import com.nokia.symbian 1.1
import com.nokia.extras 1.1
import design.liya.cosmosfm 1.0

Page {
    id: page

    tools: ToolBarLayout {
        ToolButton {
            iconSource: "toolbar-back"
            onClicked: pageStack.pop()
        }
    }

    User {
        id: user
    }

    Flickable {
        id: flickable1
        x: 30
        y: 170
        width: 300
        height: 300

        TextField {
            id: textfield1
            x: 53
            y: 72
            width: 180
            height: 50
            text: "TextField"
        }

        Button {
            id: button1
            x: 72
            y: 168
            text: "Button"
            onClicked: user.sendCode();
        }

    }


}
