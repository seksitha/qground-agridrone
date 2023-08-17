/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick                          2.11
import QtQuick.Controls                 2.4
import QtLocation                       5.3
import QtPositioning                    5.3
import QtQuick.Dialogs                  1.2
import QtQuick.Layouts                  1.11
import QtQuick.Window                   2.2
import QGroundControl                   1.0
import QGroundControl.ScreenTools       1.0
import QGroundControl.Palette           1.0
import QGroundControl.Controls          1.0
import QGroundControl.FlightMap         1.0
import QGroundControl.ShapeFileHelper   1.0

/// QGCMapPolygon map visuals
Item {
    id: _root

    property var    mapControl                                  ///< Map control to place item in
    property var    mapPolygon  // assign from parent           ///< QGCMapPolygon object
    property var    missionItem
    property bool   interactive:        mapPolygon.interactive
    property color  interiorColor
    property color  borderColor
    property real   interiorOpacity:    1
    property int    borderWidth:        0


    property bool   _circleMode:                false
    property real   _circleRadius
    property bool   _circleRadiusDrag:          false
    property var    _circleRadiusDragCoord:     QtPositioning.coordinate()
    property bool   _editCircleRadius:          false
    property string _instructionText:           _polygonToolsText
    property var    _savedVertices:             [ ]
    property bool   _savedCircleMode

    property real _zorderDragHandle:    QGroundControl.zOrderMapItems + 3   // Highest to prevent splitting when items overlap
    property real _zorderSplitHandle:   QGroundControl.zOrderMapItems + 2
    property real _zorderCenterHandle:  QGroundControl.zOrderMapItems + 1   // Lowest such that drag or split takes precedence

    readonly property string _polygonToolsText: qsTr("")
    readonly property string _traceText:        qsTr("ចុចលើប្លង់ដើម្បីដៅប្លង់ រួចហើយចុច OK")

    function addCommonVisuals() {
        if (_objMgrCommonVisuals.empty) {
            _objMgrCommonVisuals.createObject(polygonComponent, mapControl, true)
        }
    }

    function removeCommonVisuals() {
        _objMgrCommonVisuals.destroyObjects()
    }

    function addEditingVisuals() {
        if (_objMgrEditingVisuals.empty) {
            _objMgrEditingVisuals.createObjects([ dragHandlesComponent, splitHandlesComponent, centerDragHandleComponent ], mapControl, false /* addToMap */)
        }
    }

    function removeEditingVisuals() {
        _objMgrEditingVisuals.destroyObjects()
    }


    function addToolbarVisuals() {
        if (_objMgrToolVisuals.empty) {
            // _objMgrToolVisuals.createObject(toolbarComponent, mapControl)
        }
    }

    function removeToolVisuals() {
        _objMgrToolVisuals.destroyObjects()
    }

    function addCircleVisuals() {
        if (_objMgrCircleVisuals.empty) {
            _objMgrCircleVisuals.createObject(radiusVisualsComponent, mapControl)
        }
    }

    /// Calculate the default/initial 4 sided polygon
    function defaultPolygonVertices() {
        // Initial polygon is inset to take 2/3rds space
        var rect = Qt.rect(mapControl.centerViewport.x, mapControl.centerViewport.y, mapControl.centerViewport.width, mapControl.centerViewport.height)
        rect.x += (rect.width * 0.25) / 2
        rect.y += (rect.height * 0.25) / 2
        rect.width *= 0.75
        rect.height *= 0.75

        var centerCoord =       mapControl.toCoordinate(Qt.point(rect.x + (rect.width / 2), rect.y + (rect.height / 2)),   false /* clipToViewPort */)
        var topLeftCoord =      mapControl.toCoordinate(Qt.point(rect.x, rect.y),                                          false /* clipToViewPort */)
        var topRightCoord =     mapControl.toCoordinate(Qt.point(rect.x + rect.width, rect.y),                             false /* clipToViewPort */)
        var bottomLeftCoord =   mapControl.toCoordinate(Qt.point(rect.x, rect.y + rect.height),                            false /* clipToViewPort */)
        var bottomRightCoord =  mapControl.toCoordinate(Qt.point(rect.x + rect.width, rect.y + rect.height),               false /* clipToViewPort */)

        // Initial polygon has max width and height of 3000 meters
        var halfWidthMeters =   Math.min(topLeftCoord.distanceTo(topRightCoord), 3000) / 2
        var halfHeightMeters =  Math.min(topLeftCoord.distanceTo(bottomLeftCoord), 3000) / 2
        topLeftCoord =      centerCoord.atDistanceAndAzimuth(halfWidthMeters, -90).atDistanceAndAzimuth(halfHeightMeters, 0)
        topRightCoord =     centerCoord.atDistanceAndAzimuth(halfWidthMeters, 90).atDistanceAndAzimuth(halfHeightMeters, 0)
        bottomLeftCoord =   centerCoord.atDistanceAndAzimuth(halfWidthMeters, -90).atDistanceAndAzimuth(halfHeightMeters, 180)
        bottomRightCoord =  centerCoord.atDistanceAndAzimuth(halfWidthMeters, 90).atDistanceAndAzimuth(halfHeightMeters, 180)

        return [ topLeftCoord, topRightCoord, bottomRightCoord, bottomLeftCoord, centerCoord  ]
    }

    /// Reset polygon back to initial default
    function _resetPolygon() {
        mapPolygon.beginReset()
        mapPolygon.clear()
        var initialVertices = defaultPolygonVertices()
        for (var i=0; i<4; i++) {
            mapPolygon.appendVertex(initialVertices[i])
        }
        mapPolygon.endReset()
        _circleMode = false
    }

    function _createCircularPolygon(center, radius) {
        var unboundCenter = center.atDistanceAndAzimuth(0, 0)
        var segments = 16
        var angleIncrement = 360 / segments
        var angle = 0
        mapPolygon.beginReset()
        mapPolygon.clear()
        _circleRadius = radius
        for (var i=0; i<segments; i++) {
            var vertex = unboundCenter.atDistanceAndAzimuth(radius, angle)
            mapPolygon.appendVertex(vertex)
            angle += angleIncrement
        }
        mapPolygon.endReset()
        _circleMode = true
    }

    /// Reset polygon to a circle which fits within initial polygon
    function _resetCircle() {
        var initialVertices = defaultPolygonVertices()
        var width = initialVertices[0].distanceTo(initialVertices[1])
        var height = initialVertices[1].distanceTo(initialVertices[2])
        var radius = Math.min(width, height) / 2
        var center = initialVertices[4]
        _createCircularPolygon(center, radius)
    }

    function _handleInteractiveChanged() {
        if (interactive) {
            addEditingVisuals()
            addToolbarVisuals()
        } else {
            mapPolygon.traceMode = false
            removeEditingVisuals()
            removeToolVisuals()
        }
    }

    function _saveCurrentVertices() {
        _savedVertices = [ ]
        _savedCircleMode = _circleMode
        for (var i=0; i<mapPolygon.count; i++) {
            _savedVertices.push(mapPolygon.vertexCoordinate(i))
        }
    }

    function _restorePreviousVertices() {
        mapPolygon.beginReset()
        mapPolygon.clear()
        for (var i=0; i<_savedVertices.length; i++) {
            mapPolygon.appendVertex(_savedVertices[i])
        }
        mapPolygon.endReset()
        _circleMode = _savedCircleMode
    }

    function getBearing(lat1, lon1, lat2, lon2) {
        const φ1 = lat1 * Math.PI / 180
        const φ2 = lat2 * Math.PI / 180
        const λ2 = lon1 * Math.PI / 180
        const λ1 = lon2 * Math.PI / 180

        const y = Math.sin(λ2 - λ1) * Math.cos(φ2);
        const x = Math.cos(φ1) * Math.sin(φ2) -
            Math.sin(φ1) * Math.cos(φ2) * Math.cos(λ2 - λ1);
        const θ = Math.atan2(y, x);
        //(θ*180/Math.PI + 360) % 360; 
        let brng = (-(θ * 180 / Math.PI) + 360) % 360
        //return θ
        return brng
    }
    // get a new coordinate from coor1 where distand is half between coo1 and coo2 
    // and xDegree from north
    function getHalfDistance (coordinate1, coordinate2, brg){
        const d = coordinate1.distanceTo(coordinate2)/2

        const lat = coordinate1.latitude * Math.PI / 180 //convert degree to radian
        const lon = coordinate1.longitude * Math.PI / 180
        const R = 6378137; // Sitha: Earth radius in meter
        const brng = brg * Math.PI / 180
        const newLat = Math.asin(Math.sin(lat) * Math.cos(d / R) + Math.cos(lat) * Math.sin(d / R) * Math.cos(brng));
        const newLon = lon + Math.atan2(Math.sin(brng) * Math.sin(d / R) * Math.cos(lat), Math.cos(d / R) - Math.sin(lat) * Math.sin(newLat));
        return QtPositioning.coordinate(newLat * 180 / Math.PI, newLon * 180 / Math.PI); // result as radian so convert back to degree
    }

    onInteractiveChanged: _handleInteractiveChanged()

    on_CircleModeChanged: {
        if (_circleMode) {
            addCircleVisuals()
        } else {
            _objMgrCircleVisuals.destroyObjects()
        }
    }

    // Component{
    //     id: tr
    //     Repeater{
    //         model: mapPolygon.pathModel
    //         delegate: Item {
    //             Component.onCompleted:{
    //                 console.log(object.coordinate)
    //                 console.log(object.ind)
    //                 // if(object.ind == 1){
                        
    //                 // }
    //             }
    //         }
    //     }
    // }

    // Rectangle{
    //     x: 55
    //     y: 55
    //     width: 60
    //     Button{
    //         text: "auto take off point"
    //         onClicked:function(){
    //             load.active = !load.active
    //             console.log(mapPolygon)
    //         }
    //     }
    // }
   Connections {
       target: mapPolygon
       onTraceModeChanged: {
           if (mapPolygon.traceMode) {
               _instructionText = _traceText
               _objMgrTraceVisuals.createObject(traceMouseAreaComponent, mapControl, false)
           } else {
               _instructionText = _polygonToolsText
               _objMgrTraceVisuals.destroyObjects()
           }
       }
   }

    Component.onCompleted: {
        addCommonVisuals()
        _handleInteractiveChanged()
    }
    Component.onDestruction: mapPolygon.traceMode = false

    QGCDynamicObjectManager { id: _objMgrCommonVisuals }
    QGCDynamicObjectManager { id: _objMgrToolVisuals }
    QGCDynamicObjectManager { id: _objMgrEditingVisuals }
    QGCDynamicObjectManager { id: _objMgrTraceVisuals }
    QGCDynamicObjectManager { id: _objMgrCircleVisuals }

    QGCPalette { id: qgcPal }

    KMLOrSHPFileDialog {
        id:             kmlOrSHPLoadDialog
        title:          qsTr("Select Polygon File")
        selectExisting: true

        onAcceptedForLoad: {
            mapPolygon.loadKMLOrSHPFile(file)
            mapFitFunctions.fitMapViewportToMissionItems()
            close()
        }
    }

    QGCMenu {
        id: menu

        property int _editingVertexIndex: -1

        function popupVertex(curIndex) {
            menu._editingVertexIndex = curIndex
            removeVertexItem.visible = (mapPolygon.count > 3 && menu._editingVertexIndex >= 0)
            menu.popup()
        }

        function popupCenter() {
            menu.popup()
        }

        QGCMenuItem {
            id:             removeVertexItem
            visible:        !_circleMode
            text:           qsTr("លុបចេញ")
            onTriggered: {
                if (menu._editingVertexIndex >= 0) {
                    mapPolygon.removeVertex(menu._editingVertexIndex)
                }
            }
        }

        QGCMenuSeparator {
            visible:        removeVertexItem.visible
        }

        QGCMenuItem {
            text:           qsTr("Set radius..." )
            visible:        _circleMode
            onTriggered:    _editCircleRadius = true
        }

        QGCMenuItem {
            text:           qsTr("ធ្វើកំណែរ" )
            visible:        _circleMode
            onTriggered:    mainWindow.showComponentDialog(editCenterPositionDialog, qsTr("Edit Center Position"), mainWindow.showDialogDefaultWidth, StandardButton.Close)
        }

        QGCMenuItem {
            text:           qsTr("ធ្វើកំណែរ" )
            visible:        !_circleMode && menu._editingVertexIndex >= 0
            onTriggered:    mainWindow.showComponentDialog(editVertexPositionDialog, qsTr("Edit Vertex Position"), mainWindow.showDialogDefaultWidth, StandardButton.Close)
        }
    }

    Component {
        id: polygonComponent

        MapPolygon {
            color:          interiorColor
            opacity:        interiorOpacity
            border.color:   borderColor
            border.width:   borderWidth
            path:           mapPolygon.path
        }
    }

    Component {
        id: splitHandleComponent

        MapQuickItem {
            id:             mapQuickItem
            anchorPoint.x:  sourceItem.width / 2
            anchorPoint.y:  sourceItem.height / 2
            visible:        !_circleMode

            property int vertexIndex

            sourceItem: SplitIndicator {
                z:          _zorderSplitHandle
                onClicked:  mapPolygon.splitPolygonSegment(mapQuickItem.vertexIndex)
            }
        }
    }

    Component {
        id: splitHandlesComponent

        Repeater {
            model: mapPolygon.path

            delegate: Item {
                property var _splitHandle
                property var _vertices:     mapPolygon.path

                function _setHandlePosition() {
                    var nextIndex = index + 1
                    if (nextIndex > _vertices.length - 1) {
                        nextIndex = 0
                    }
                    var distance = _vertices[index].distanceTo(_vertices[nextIndex])
                    var azimuth = _vertices[index].azimuthTo(_vertices[nextIndex])
                    _splitHandle.coordinate = _vertices[index].atDistanceAndAzimuth(distance / 2, azimuth)
                }

                Component.onCompleted: {
                    _splitHandle = splitHandleComponent.createObject(mapControl)
                    _splitHandle.vertexIndex = index
                    _setHandlePosition()
                    mapControl.addMapItem(_splitHandle)
                }

                Component.onDestruction: {
                    if (_splitHandle) {
                        _splitHandle.destroy()
                    }
                }
            }
        }
    }
    property var rotatePoints :[]
    property var _visualAngles:[]
    // Control which is used to drag polygon vertices
    Component {
        id: dragAreaComponent

        MissionItemIndicatorDrag {
            id:         dragArea
            mapControl: _root.mapControl
            z:          _zorderDragHandle
            visible:    !_circleMode

            property int polygonVertex

            property bool _creationComplete: false
            Component.onCompleted: {
                _creationComplete = true
                createAngleComps()
            }
            onItemCoordinateChanged: {
                if (_creationComplete) {
                    // During component creation some bad coordinate values got through which screws up draw
                    mapPolygon.adjustVertex(polygonVertex, itemCoordinate)
                    createAngleComps()
                }   
            }
            onDragStop: {
                mapPolygon.verifyClockwiseWinding()
            }
            Component.onDestruction:{
                console.log('destruct')
                createAngleComps()
                _visualAngles.forEach(function(obj){
                    obj.destroy()
                })
            }
            onClicked: menu.popupVertex(polygonVertex)
        }
    }

    function createAngleComps (){
        // console.log(_visualAngles.length)
        for(var j = 0; j < _visualAngles.length; j++){
            mapControl.removeMapItem(_visualAngles[j])
        }
        if(mapPolygon.pathModel.count > 1){
            for(var i = 0 ; i < mapPolygon.pathModel.count-1; i++){
                createAngleComp(mapPolygon, rotatePoints, _visualAngles, i, false)
                if(i == mapPolygon.pathModel.count-2 ){ // get angle for the last->0
                    createAngleComp(mapPolygon, rotatePoints, _visualAngles, i, true)
                }
            }
        }

    }

    function createAngleComp(polygonModels, rotateAngleModel, visualAngleModel, index, last){
        const ind = last ? index +1 : index
        const distanceFromSpitPoint = 15
        var coo1 = polygonModels.pathModel.get(ind ).coordinate
        var coo2 = polygonModels.pathModel.get(last ? 0 : index+1).coordinate
        var angleComponent = polylineAngle.createObject(mapControl)
        var bearing = (getBearing(coo1.latitude, coo1.longitude, coo2.latitude, coo2.longitude))
        rotateAngleModel[ind]= bearing // globel array
        angleComponent.coordinate = Qt.binding(function(){return getHalfDistance(coo1,coo2,bearing).atDistanceAndAzimuth(distanceFromSpitPoint,bearing-90)})
        angleComponent.index = ind
        visualAngleModel[ind]=angleComponent
        mapControl.addMapItem(angleComponent)
    }

    Component{
        id: polylineAngle
        MapQuickItem {
            property int index 
            id:             angleGrid
            anchorPoint.x:  sourceItem.width / 2
            anchorPoint.y:  sourceItem.height / 2
            sourceItem: Rectangle {
                id:             anglePoint //Sitha anglePoint
                width:          ScreenTools.defaultFontPixelHeight * 1.3
                height:         width
                radius:         width * 0.5
                color:          "cyan"
                border.color:   Qt.rgba(0,0,0,0.25)
                border.width:   1
                MouseArea{
                    anchors.fill:  parent
                    onClicked:{
                        missionItem.gridAngle.value = rotatePoints[index]
                    }
                }

            }
        }
                    
    }

    Component {
        id: centerDragHandle
        MapQuickItem {
            id:             mapQuickItem
            anchorPoint.x:  dragHandle.width  * 0.5
            anchorPoint.y:  dragHandle.height * 0.5
            z:              _zorderDragHandle
            sourceItem: Rectangle {
                id:             dragHandle
                width:          ScreenTools.defaultFontPixelHeight * 1.3
                height:         width
                radius:         width * 0.5
                color:          Qt.rgba(1,1,1,0.8)
                border.color:   Qt.rgba(0,0,0,0.25)
                border.width:   1
                QGCColoredImage {
                    width:      parent.width
                    height:     width
                    color:      Qt.rgba(0,0,0,1)
                    mipmap:     true
                    fillMode:   Image.PreserveAspectFit
                    source:     "/qmlimages/MapCenter.svg"
                    sourceSize.height:  height
                    anchors.centerIn:   parent
                }
            }
        }
    }

    Component {
        id: editCenterPositionDialog

        EditPositionDialog {
            coordinate: mapPolygon.center
            onCoordinateChanged: {
                // Prevent spamming signals on vertex changes by setting centerDrag = true when changing center position.
                // This also fixes a bug where Qt gets confused by all the signalling and draws a bad visual.
                mapPolygon.centerDrag = true
                mapPolygon.center = coordinate
                mapPolygon.centerDrag = false
            }
        }
    }

    Component {
        id: editVertexPositionDialog

        EditPositionDialog {
            coordinate:             mapPolygon.vertexCoordinate(menu._editingVertexIndex)
            onCoordinateChanged: {
                mapPolygon.adjustVertex(menu._editingVertexIndex, coordinate)
                mapPolygon.verifyClockwiseWinding()
            }
        }
    }

    Component {
        id: centerDragAreaComponent

        MissionItemIndicatorDrag {
            mapControl:                 _root.mapControl
            z:                          _zorderCenterHandle
            onItemCoordinateChanged:{
                 mapPolygon.center = itemCoordinate
                 createAngleComps()
            }   
            onDragStart:                mapPolygon.centerDrag = true
            onDragStop:                 {
                mapPolygon.centerDrag = false
            }
        }
    }

    Component {
        id: centerDragHandleComponent

        Item {
            property var dragHandle
            property var dragArea

            Component.onCompleted: {
                dragHandle = centerDragHandle.createObject(mapControl)
                dragHandle.coordinate = Qt.binding(function() { return mapPolygon.center })
                mapControl.addMapItem(dragHandle)
                dragArea = centerDragAreaComponent.createObject(mapControl, { "itemIndicator": dragHandle, "itemCoordinate": mapPolygon.center })
            }

            Component.onDestruction: {
                dragHandle.destroy()
                dragArea.destroy()
            }
        }
    }

    Component {
        id: radiusDragHandleComponent

        MapQuickItem {
            id:             mapQuickItem
            anchorPoint.x:  dragHandle.width / 2
            anchorPoint.y:  dragHandle.height / 2
            z:              QGroundControl.zOrderMapItems + 2

            sourceItem: Rectangle {
                id:         dragHandle
                width:      ScreenTools.defaultFontPixelHeight * 1.3
                height:     width
                radius:     width / 2
                border.width:   1
                color:      "white"
                opacity:    .90
            }
        }
    }

    Component {
        id: radiusDragAreaComponent
        MissionItemIndicatorDrag {
            mapControl: _root.mapControl
            property real _lastRadius
            onItemCoordinateChanged: {
                var radius = mapPolygon.center.distanceTo(itemCoordinate)
                // Prevent signalling re-entrancy
                if (!_circleRadiusDrag && Math.abs(radius - _lastRadius) > 0.1) {
                    _circleRadiusDrag = true
                    _createCircularPolygon(mapPolygon.center, radius)
                    _circleRadiusDragCoord = itemCoordinate
                    _circleRadiusDrag = false
                    _lastRadius = radius
                }
            }
        }
    }

    Component {
        id: radiusVisualsComponent

        Item {
            property var    circleCenterCoord:  mapPolygon.center

            function _calcRadiusDragCoord() {
                _circleRadiusDragCoord = circleCenterCoord.atDistanceAndAzimuth(_circleRadius, 90)
            }

            onCircleCenterCoordChanged: {
                if (!_circleRadiusDrag) {
                    _calcRadiusDragCoord()
                }
            }

            QGCDynamicObjectManager {
                id: _objMgr
            }

            Component.onCompleted: {
                _calcRadiusDragCoord()
                var radiusDragHandle = _objMgr.createObject(radiusDragHandleComponent, mapControl, true)
                radiusDragHandle.coordinate = Qt.binding(function() { return _circleRadiusDragCoord })
                var radiusDragIndicator = radiusDragAreaComponent.createObject(mapControl, { "itemIndicator": radiusDragHandle, "itemCoordinate": _circleRadiusDragCoord })
                _objMgr.addObject(radiusDragIndicator)
            }
        }
    }

    
    Item {
        id: pointer
        Rectangle{
            id:  getPolygonPin // pointer pin point
            width: 50
            height: 50
            color: Qt.rgba(167, 0, 255, 0.28)
            border.color: "white"
            border.width: 2
            radius: 25
            y:150
            x: mainWindow.width/2
            z:1000
            MouseArea {
                anchors.fill:  parent
                onClicked:{
                    if (mouse.button === Qt.LeftButton) {
                        mapPolygon.appendVertex(mapControl.toCoordinate(Qt.point(getPolygonByPin.x+8, getPolygonByPin.y+8), false /* clipToViewPort */))
                    }   
                }
            }
        }

           // move polyline close to borders
    Item {
        id: movePolyline

        Rectangle{
            x: 150
            y: 50
            width: parent.width / 3
            Button{
                text: "to <="
                y: 50
                height: 24
                onClicked : missionItem.movePolyline("left")
            }
            Button{
                text: "to =>"
                y: 75
                 height: 24
            }
            Button{
                text: "to ^"
                y: 100
                height: 24
            }
            Button{
                text: "to V"
                y: 125
                height: 24
            }
        }
    }

        Rectangle{
            id:  getPolygonByPin // pointer pin point
            width: 15
            height: 15
            color: "white"
            radius: 7.5
            y:167
            x: mainWindow.width/2 + 17
            z:1001
        }    
    }

    Connections  {
        target: surveyPolygonPinByVehicle
        onPinByHandHeld:{
            mapPolygon.appendVertex(editorMap.correctCoordinate(QGroundControl.multiVehicleManager.vehicles.get(0).coordinate))
        }
        onPinByVehicle:{
            mapPolygon.appendVertex(editorMap.correctCoordinate(QGroundControl.multiVehicleManager.vehicles.get(0).coordinate))
        }
        onPinByPointer:{
            mapPolygon.appendVertex(mapControl.toCoordinate(Qt.point(getPolygonByPin.x+8, getPolygonByPin.y+8), false /* clipToViewPort */))
        }
        onPinByPhoneGPS:{
            mapPolygon.appendVertex(editorMap.correctCoordinate(editorMap.gcsPosition), false /* clipToViewPort */)
        }
    }


    Component { // Sitha Vertex white dot polygon points
        id: dragHandleComponent

        MapQuickItem {
            id:             mapQuickItem
            anchorPoint.x:  dragHandle.width  / 2
            anchorPoint.y:  dragHandle.height / 2
            z:              _zorderDragHandle
            visible:        !_circleMode

            property int polygonVertex

            sourceItem: Rectangle {
                id:             dragHandle
                width:          ScreenTools.defaultFontPixelHeight * 1.3
                height:         width
                radius:         width * 0.5
                color:          Qt.rgba(128,0,255)
                border.color:   Qt.rgba(1,1,1,0.8)
                border.width:   1
                QGCLabel{ // index of pollygon point purple color
                    anchors.fill: parent
                    width: parent.width
                    text: polygonVertex + 1
                    horizontalAlignment : Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }
        }
    }

    // Add all polygon vertex drag handles to the map
    Component { // this got created on parentCompoent completed event
        id: dragHandlesComponent

        Repeater {
            model: mapPolygon.pathModel
            
            delegate: Item {
                property var _visuals: [ ]
                Component.onCompleted: {
                    var dragHandle = dragHandleComponent.createObject(mapControl) // add vertex here
                    dragHandle.coordinate = Qt.binding(function() { return object.coordinate })
                    dragHandle.polygonVertex = Qt.binding(function() { return index })
                    mapControl.addMapItem(dragHandle)
                    var dragArea = dragAreaComponent.createObject(mapControl, { "itemIndicator": dragHandle, "itemCoordinate": object.coordinate })
                    dragArea.polygonVertex = Qt.binding(function() { return index })
                    object.ind = index
                    _visuals.push(dragHandle)
                    _visuals.push(dragArea)
                    mapPolygon.verifyClockwiseWinding() // set vertex to be clockwise
                    
                }

                Component.onDestruction: {
                    for (var i=0; i<_visuals.length; i++) {
                        _visuals[i].destroy()
                    }
                    _visuals = [ ]
                }
            }
        }
    }
    
    // Item {
    //     id: handheld
    //     Rectangle{
    //         width: 8
    //         height: 50
    //         color: "purple"
    //         border.color: "blue"
    //         border.width: 1
    //         radius: 0
    //         y:200
    //         x: mainWindow.width/2+21
    //     }
    //     Rectangle{
    //         width: 30
    //         height: 30
    //         color: "white"
    //         radius: 25
    //         y:160
    //         x: mainWindow.width/2 + 10
    //         z:1001
    //         MouseArea {
    //             anchors.fill:  parent
    //             onClicked:{
    //                 if (mouse.button === Qt.LeftButton) {
    //                     mapPolygon.appendVertex(mapControl.toCoordinate(Qt.point(mainWindow.width/2+24, 250), false /* clipToViewPort */))
    //                 }   
    //             }
    //         }
    //     }
    //     Rectangle{
    //         id:  getPolygonPin // pointer pin point
    //         width: 50
    //         height: 50
    //         color: "purple"
    //         border.color: "blue"
    //         border.width: 1
    //         radius: 25
    //         y:150
    //         x: mainWindow.width/2
    //         z:1000
    //         MouseArea {
    //             anchors.fill:  parent
    //             onClicked:{
    //                 if (mouse.button === Qt.LeftButton) {
    //                     mapPolygon.appendVertex(mapControl.toCoordinate(Qt.point(mainWindow.width/2+24, 230), false /* clipToViewPort */))
    //                 }   
    //             }
    //         }
    //     }
    // }
    
    

    
    // Component {
    //     id: toolbarComponent

    //     PlanEditToolbar {
    //         anchors.horizontalCenter:       mapControl.left
    //         anchors.horizontalCenterOffset: mapControl.centerViewport.left + (mapControl.centerViewport.width / 2)
    //         y:                              mapControl.centerViewport.top
    //         z:                              QGroundControl.zOrderMapItems + 2
    //         availableWidth:                 mapControl.centerViewport.width

    //     //    QGCButton {
    //     //        _horizontalPadding: 0
    //     //        text:               qsTr("Basic")
    //     //        visible:            !mapPolygon.traceMode
    //     //        onClicked:          _resetPolygon()
    //     //    }

    //     //    QGCButton {
    //     //        _horizontalPadding: 0
    //     //        text:               qsTr("Circular")
    //     //        visible:            !mapPolygon.traceMode
    //     //        onClicked:          _resetCircle()
    //     //    }

    //         // QGCButton {
    //         //     _horizontalPadding: 0
    //         //     text:               mapPolygon.traceMode ? qsTr("OK") : qsTr("គូសព្រំ")
    //         //     onClicked: {
    //         //         if (mapPolygon.traceMode) {
    //         //             if (mapPolygon.count < 3) {
    //         //                 _restorePreviousVertices()
    //         //             }
    //         //             mapPolygon.traceMode = false
    //         //         } else {
    //         //             _saveCurrentVertices()
    //         //             _circleMode = false
    //         //             mapPolygon.traceMode = true
    //         //             mapPolygon.clear();
    //         //         }
    //         //     }
    //         // }

    //     //    QGCButton {
    //     //        _horizontalPadding: 0
    //     //        text:               qsTr("Load KML/SHP...")
    //     //        onClicked:          kmlOrSHPLoadDialog.openForLoad()
    //     //        visible:            !mapPolygon.traceMode
    //     //    }
    //     }
    // }

    // Mouse area to capture clicks for tracing a polygon
    // Component {
    //     id:  traceMouseAreaComponent

    //     // MouseArea {
    //     //     anchors.fill:       mapControl
    //     //     preventStealing:    true
    //     //     z:                  QGroundControl.zOrderMapItems + 1   // Over item indicators

    //     //     // onClicked: {
    //     //     //     if (mouse.button === Qt.LeftButton) {
    //     //     //         mapPolygon.appendVertex(mapControl.toCoordinate(Qt.point(mouse.x, mouse.y), false /* clipToViewPort */))
    //     //     //     }
    //     //     // }
    //     // }
    // }
    
}

