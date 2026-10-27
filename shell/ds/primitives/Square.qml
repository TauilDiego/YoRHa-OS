import QtQuick
import ".."

// The square marker in front of every tab and list item.
Rectangle {
    property real s: 1
    property real size: Tokens.space.square      // game px

    width: Tokens.px(size, s)
    height: width
    color: Tokens.color.darkGray
}
