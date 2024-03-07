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
    gesture.acceptedGestures:   MapGestureArea.PinchGesture | MapGestureArea.PanGesture | MapGestureArea.FlickGesture  | MapGestureArea.RotationGesture
    gesture.flickDeceleration:  3000

    plugin: Plugin {
        name: "QGroundControl"
    }

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
    property bool   planView:                       false   ///< true: map being using for Plan view, items should be draggabl

    property var    activeVehicleCoordinate:        activeVehicle ? activeVehicle.coordinate : QtPositioning.coordinate()
    property int timer_index : 0
    property var paramEditor
    property int sprayAll : 0

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
        
    // We track whether the user has panned or not to correctly handle automatic map positioning
    Connections {
        target: gesture
        onPanFinished:      userPanned = true
        onFlickFinished:    userPanned = true
        onRotationUpdated: function(e){
            //wrap 180 degree(+,-) not 360
            var ang = _map.bearing > 180 ? _map.bearing - 360 : _map.bearing
            mapRotateAngle = ang
            rotateAngleChanged(ang)
        }
        
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

    function correctCoordinate (coordinate){
        // https://gis.stackexchange.com/questions/2951/algorithm-for-offsetting-a-latitude-longitude-by-some-amount-of-meters
        var R = 6378137;
        var lat = coordinate.latitude
        var lon = coordinate.longitude
        var dn = correct_coordinate_ns * (-1) //in meter get from fc
        var de = correct_coordinate_we * (-1) //in meter get from fc
        var dlat = dn/R
        var dlon = de /(R*Math.cos(Math.PI*lat/180))
        var newlat = (lat + dlat * 180/Math.PI)
        var newlon = (lon + dlon * 180/Math.PI)
        var coor = QtPositioning.coordinate(newlat, newlon);
        return coor
    }

    Loader { // sitha: prevent popup warning no wpnav param available? no parameter available only when reload the component
        id: ld
        sourceComponent: paramComponent
        active: false 
        anchors.fill: parent
    }

    Component{ //sitha use to reload parameter because to get current param value paramComponent need to be load for constructor to get param
        id: paramComponent
        ParameterEditorController {
            id: paramController 
            Component.onCompleted:{
                // console.log('run')
                paramEditor = paramController
                correct_coordinate_we = parseFloat(paramController.getParamValue("WPNAV_COOR_WE"))
                correct_coordinate_ns = parseFloat(paramController.getParamValue("WPNAV_COOR_NS"))
                sprayAll = parseInt(paramController.getParamValue("WPNAV_SPRAY_ALL"))
            }
        }  
    }
    Connections { // sitha
        target: QGroundControl.multiVehicleManager
        onParameterReadyVehicleAvailableChanged: function(val){
            ld.active = true; // to avoid asking param while it is not connected to drone
            paramTimer.start(); // Sitha start timer only 3 time when the app load parameters after that we stop timer please look at trigger code 
        }
        onParamHasUpdated: function(paramName){ // this will handle the update after load all param and user change
            if(paramName == "WPNAV_COOR_WE")    correct_coordinate_we = parseFloat(paramEditor.getParamValue("WPNAV_COOR_WE"))
            if(paramName == "WPNAV_COOR_NS")    correct_coordinate_ns = parseFloat(paramEditor.getParamValue("WPNAV_COOR_NS"))
            if(paramName == "WPNAV_SPRAY_ALL")  sprayAll = parseInt(paramEditor.getParamValue("WPNAV_SPRAY_ALL"))
        }
    }

    Timer {
        id:         paramTimer
        interval:   1000;
        running:    false;
        repeat:     true
        onTriggered: {
            timer_index++
            ld.active = activeVehicle ?  !ld.active : false; // preventing asking for parameter when no vihecles connected
            if(timer_index > 3 && ld.active) paramTimer.stop();
        }
    }

    /// Ground Station location
    MapQuickItem {
        anchorPoint.x:  sourceItem.width / 2
        anchorPoint.y:  sourceItem.height / 2
        visible:        gcsPosition.isValid
        coordinate:     correctCoordinate(gcsPosition)

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
