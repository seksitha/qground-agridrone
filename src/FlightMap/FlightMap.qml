/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick          2.3
import QtQuick.Controls 1.2
import QtLocation       5.12
import QtPositioning    5.12
import QtQuick.Dialogs  1.2
import QtQuick.Layouts  1.2

import QGroundControl                       1.0
import QGroundControl.FactSystem            1.0
import QGroundControl.Controls              1.0
import QGroundControl.Controllers   1.0
import QGroundControl.FlightMap             1.0
import QGroundControl.ScreenTools           1.0
import QGroundControl.MultiVehicleManager   1.0
import QGroundControl.Vehicle               1.0
import QGroundControl.QGCPositionManager    1.0

Map {
    id: _map

    //-- Qt 5.9 has rotation gesture enabled by default. Here we limit the possible gestures.
    gesture.acceptedGestures:   MapGestureArea.PinchGesture | MapGestureArea.PanGesture //| MapGestureArea.FlickGesture  | MapGestureArea.RotationGesture
    gesture.flickDeceleration:  3000
    plugin:                     Plugin { name: "QGroundControl" }

    // https://bugreports.qt.io/browse/QTBUG-82185
    opacity:                    0.99
//    tilt: 45 //tilt 45 degree
//    bearing: 45 //rotate 45 degree

    property string mapName:                        'defaultMap'
    property bool   isSatelliteMap:                 activeMapType.name.indexOf("Satellite") > -1 || activeMapType.name.indexOf("Hybrid") > -1
    property var    gcsPosition:                    QGroundControl.qgcPositionManger.gcsPosition
    property real   gcsHeading:                     QGroundControl.qgcPositionManger.gcsHeading
    property real   mapRotateAngle:                 0

    property bool   userPanned:                     false   ///< true: the user has manually panned the map
    property bool   allowGCSLocationCenter:         false   ///< true: map will center/zoom to gcs location one time
    property bool   allowVehicleLocationCenter:     false   ///< true: map will center/zoom to vehicle location one time
    property bool   firstGCSPositionReceived:       false   ///< true: first gcs position update was responded to
    property bool   firstVehiclePositionReceived:   false   ///< true: first vehicle position update was responded to
    property bool   planView:                       false   ///< true: map being using for Plan view, items should be draggable

    readonly property real  maxZoomLevel: 30

    property var    activeVehicleCoordinate:        activeVehicle ? activeVehicle.coordinate : QtPositioning.coordinate()

    function setVisibleRegion(region) {
        // TODO: Is this still necessary with Qt 5.11?
        // This works around a bug on Qt where if you set a visibleRegion and then the user moves or zooms the map
        // and then you set the same visibleRegion the map will not move/scale appropriately since it thinks there
        // is nothing to do.
        _map.visibleRegion = QtPositioning.rectangle(QtPositioning.coordinate(0, 0), QtPositioning.coordinate(0, 0))
        _map.visibleRegion = region
    }

    function _possiblyCenterToVehiclePosition() {
        if (!firstVehiclePositionReceived && allowVehicleLocationCenter && activeVehicleCoordinate.isValid) {
            firstVehiclePositionReceived = true
            center = activeVehicleCoordinate
            zoomLevel = QGroundControl.flightMapInitialZoom
        }
    }

    function centerToSpecifiedLocation() {
        mainWindow.showComponentDialog(specifyMapPositionDialog, qsTr("Specify Position"), mainWindow.showDialogDefaultWidth, StandardButton.Close)
    }

    Component {
        id: specifyMapPositionDialog
        EditPositionDialog {
            coordinate:             center
            onCoordinateChanged:    center = coordinate
        }
    }

    // Center map to gcs location
    onGcsPositionChanged: {
        if (gcsPosition.isValid && allowGCSLocationCenter && !firstGCSPositionReceived && !firstVehiclePositionReceived) {
            firstGCSPositionReceived = true
            //-- Only center on gsc if we have no vehicle (and we are supposed to do so)
            var activeVehicleCoordinate = activeVehicle ? activeVehicle.coordinate : QtPositioning.coordinate()
            if(QGroundControl.settingsManager.flyViewSettings.keepMapCenteredOnVehicle.rawValue || !activeVehicleCoordinate.isValid)
                center = gcsPosition
        }
    }
  
    signal rotateAngleChanged(real angle)

    GridLayout{
        anchors.top:            parent.top
        anchors.right: parent.right
        anchors.rightMargin:           mainWindow.width/2

        width:          mainWindow.width/3.5
        rows:1
        columns: 5
        z:1000

        QGCSlider {
            id:                     mapRotator
            minimumValue:           -180
            maximumValue:           180
            stepSize:               1
            tickmarksEnabled:       false
            Layout.fillWidth:       true
            Layout.columnSpan:      2
            Layout.preferredWidth:  2
            Layout.preferredHeight: 50
            z:1000
            value: 0
            onValueChanged:  function(){
                _map.bearing = -1*value
                mapRotateAngle = -1*value       // used to set drone head
                rotateAngleChanged(-1*value)    // used to set arrow
            }

            updateValueWhileDragging: true
        }
    }

    // We track whether the user has panned or not to correctly handle automatic map positioning
    Connections {
        target: gesture
        onPanFinished:      userPanned = true
        onFlickFinished:    userPanned = true
        
    }

    function updateActiveMapType() {
        var settings =  QGroundControl.settingsManager.flightMapSettings
        var fullMapName = settings.mapProvider.value + " " + settings.mapType.value

        for (var i = 0; i < _map.supportedMapTypes.length; i++) {
            if (fullMapName === _map.supportedMapTypes[i].name) {
                _map.activeMapType = _map.supportedMapTypes[i]
                return
            }
        }
    }

    onActiveVehicleCoordinateChanged: _possiblyCenterToVehiclePosition()

    Component.onCompleted: {
        updateActiveMapType()
        _possiblyCenterToVehiclePosition()
    }

    Connections {
        target:             QGroundControl.settingsManager.flightMapSettings.mapType
        onRawValueChanged:  updateActiveMapType()
    }

    Connections {
        target:             QGroundControl.settingsManager.flightMapSettings.mapProvider
        onRawValueChanged:  updateActiveMapType()
    }
    property var correct_coordinate_we : 0
    property var correct_coordinate_ns : 0

    function correctCoordiante (coordinate){
        var R = 6378137;
        var lat = coordinate.latitude
        var lon = coordinate.longitude
        var dn = correct_coordinate_ns * (-1)
        var de = correct_coordinate_we * (-1)
        var dlat = dn/R
        var dlon = de /(R*Math.cos(Math.PI*lat/180))
        var newlat = (lat + dlat * 180/Math.PI)
        var newlon = (lon + dlon * 180/Math.PI)
        var coor = QtPositioning.coordinate(newlat, newlon);
        return coor
    }

    Loader {
        id: ld
        sourceComponent: paramComponent
        active: false
        anchors.fill: parent
    }

    Component{
        id: paramComponent
        ParameterEditorController {
            id:paramController 
            Component.onCompleted:{
                // console.log('run')
                correct_coordinate_we = parseFloat(paramController.getParams("WPNAV_COOR_WE"))
                correct_coordinate_ns = parseFloat(paramController.getParams("WPNAV_COOR_NS"))
            }
        }
    }
    Connections {
        target: QGroundControl.multiVehicleManager
        onParameterReadyVehicleAvailableChanged: ld.active = true;
    }
    Timer {
        id:         param
        interval:   2500;
        running:    true;
        repeat:     true
        onTriggered: {
            ld.active = activeVehicle ?  !ld.active : false;
        }
    }
    /// Ground Station location
    MapQuickItem {
        anchorPoint.x:  sourceItem.width / 2
        anchorPoint.y:  sourceItem.height / 2
        visible:        gcsPosition.isValid
        coordinate:     correctCoordiante(gcsPosition)

        sourceItem: Image {
            id:             mapItemImage
            source:         isNaN(gcsHeading) ? "/res/QGCLogoFull" : "/res/QGCLogoArrow"
            mipmap:         true
            antialiasing:   true
            fillMode:       Image.PreserveAspectFit
            height:         ScreenTools.defaultFontPixelHeight * (isNaN(gcsHeading) ? 1.75 : 2.5 )
            sourceSize.height: height
            transform: Rotation {
                origin.x:       mapItemImage.width  / 2
                origin.y:       mapItemImage.height / 2
                angle:          isNaN(gcsHeading) ? 0 : gcsHeading
            }
        }
    }
} // Map
