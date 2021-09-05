/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick          2.3
import QtQuick.Controls 2.4

import QGroundControl.Controls      1.0
import QGroundControl.Palette       1.0
import QGroundControl.ScreenTools   1.0

// Important Note: Toolbar buttons must manage their checked state manually in order to support
// view switch prevention. This means they can't be checkable or autoExclusive.

Button {
    property real userHeight
    property bool backgroundOverlay : false
    property bool logo: false
    property real _horizontalMargin: ScreenTools.defaultFontPixelWidth
    
    id:                 button
    height:             userHeight ? userHeight : ScreenTools.defaultFontPixelHeight * 3
    leftPadding:        _horizontalMargin
    rightPadding:       _horizontalMargin
    width : userHeight ? userHeight : button.width
    checkable:          false

    onCheckedChanged: checkable = false

    background: Rectangle {
        id:rec
        radius : backgroundOverlay ? (height * 0.5) : 0
        anchors.fill: parent
        color:  logo ? qgcPal.brandingPurple : (button.checked ? qgcPal.buttonHighlight : backgroundOverlay ? Qt.rgba(0, 0, 0, 0.25) : Qt.rgba(0,0,0,0))
    }

    contentItem: Row {
        spacing:                ScreenTools.defaultFontPixelWidth
        anchors.verticalCenter: button.verticalCenter
        QGCColoredImage {
            id:                     _icon
            height:                 backgroundOverlay? button.height * (0.55) : ScreenTools.defaultFontPixelHeight * 2
            width:                  height
            sourceSize.height:      parent.height
            fillMode:               Image.PreserveAspectFit
            color:                  logo ? "white" : (button.checked ? qgcPal.buttonHighlightText : qgcPal.buttonText)
            source:                 button.icon.source
            anchors.verticalCenter: parent.verticalCenter
            anchors.horizontalCenter: button.backgroundOverlay ? parent.horizontalCenter : _icon.horizontalCenter
        }
        Label {
            id:                     _label
            visible:                text !== ""
            text:                   button.text
            color:                  button.checked ? qgcPal.buttonHighlightText : qgcPal.buttonText
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
