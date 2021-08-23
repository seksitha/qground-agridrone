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
import QtLocation       5.3
import QtPositioning    5.3

import QGroundControl               1.0
import QGroundControl.ScreenTools   1.0
import QGroundControl.Palette       1.0
import QGroundControl.Controls      1.0
import QGroundControl.FlightMap     1.0

/// Base control for both Survey and Corridor Scan map visuals
Item {
    id: _root

    property var    map                                                 ///< Map control to place item in
    property bool   polygonInteractive: true

    property var    _missionItem:               object
    property var    _mapPolygon:                object.surveyAreaPolygon
    property bool   _currentItem:               object.isCurrentItem
    property var    _transectPoints:            _missionItem.visualTransectPoints
    property int    _transectCount:             _transectPoints.length / (_hasTurnaround ? 4 : 2)
    property bool   _hasTurnaround:             _missionItem.turnAroundDistance.rawValue !== 0
    property int    _firstTrueTransectIndex:    _hasTurnaround ? 1 : 0
    property int    _lastTrueTransectIndex:     _transectPoints.length - (_hasTurnaround ? 2 : 1)
    property int    _lastPointIndex:            _transectPoints.length - 1
    property bool   _showPartialEntryExit:      !_currentItem && _hasTurnaround &&_transectPoints.length >= 2
    property var    _fullTransectsComponent:    null
    property var    _entryTransectsComponent:   null
    property var    _exitTransectsComponent:    null
    property var    _entryCoordinate
    property var    _exitCoordinate

    signal clicked(int sequenceNumber)

    function _addVisualElements() {
        var toAdd = [ fullTransectsComponent, entryTransectComponent, exitTransectComponent, entryPointComponent, exitPointComponent,
                     entryArrow1Component, entryArrow2Component, exitArrow1Component, exitArrow2Component ]
        objMgr.createObjects(toAdd, map, true /* parentObjectIsMap */)
    }

    function _destroyVisualElements() {
        objMgr.destroyObjects()
    }

    Component.onCompleted: {
        _addVisualElements()
    }

    Component.onDestruction: {
        _destroyVisualElements()
    }

    QGCDynamicObjectManager {
        id: objMgr
    }

    // Area polygon
    QGCMapPolygonVisuals {
        id:                 mapPolygonVisuals
        mapControl:         map
        mapPolygon:         _mapPolygon
        interactive:        polygonInteractive && _missionItem.isCurrentItem
        borderWidth:        2
        borderColor:        "#1100cc" // blue sitha
        interiorColor:      "#1e34c8" // dark blue sitha
        interiorOpacity:    0.1
    }

    // Full set of transects lines. Shown when item is selected.
    Component {
        id: fullTransectsComponent

        MapPolyline { // sitha this component is build in qt component
            line.color: "white" // to blue sitha weypoints line 
            line.width: 2
            path:      _transectPoints
            visible:    _currentItem
        }
    }

    // Entry and exit transect lines only. Used when item is not selected.
    Component {
        id: entryTransectComponent

        MapPolyline {
            line.color: "#1e34c8" // ???
            line.width: 2
            path:       _showPartialEntryExit ? [ _transectPoints[0], _transectPoints[1] ] : []
            visible:    _showPartialEntryExit
        }
    }
    Component {
        id: exitTransectComponent

        MapPolyline { 
            line.color: "white" // ??
            line.width: 2
            path:       _showPartialEntryExit ? [ _transectPoints[_lastPointIndex - 1], _transectPoints[_lastPointIndex] ] : []
            visible:    _showPartialEntryExit
        }
    }

    // Entry point
    Component {
        id: entryPointComponent

        MapQuickItem {
            anchorPoint.x:  sourceItem.anchorPointX
            anchorPoint.y:  sourceItem.anchorPointY
            z:              QGroundControl.zOrderMapItems
            coordinate:     _missionItem.coordinate
            visible:        _missionItem.exitCoordinate.isValid

            sourceItem: MissionItemIndexLabel {
                index:      _missionItem.sequenceNumber
                checked:    _missionItem.isCurrentItem
                onClicked:  {
                    console.log('run')
                    _root.clicked(_missionItem.sequenceNumber)
                }
            }
        }
    }

    Component {
        id: entryArrow1Component

        MapLineArrow {
            map:map
            fromCoord:      _transectPoints[_firstTrueTransectIndex]
            toCoord:        _transectPoints[_firstTrueTransectIndex + 1]
            arrowPosition:  1
            visible:        _currentItem
        }
    }

    Component {
        id: entryArrow2Component

        MapLineArrow {
            map:map
            fromCoord:      _transectPoints[nextTrueTransectIndex]
            toCoord:        _transectPoints[nextTrueTransectIndex + 1]
            arrowPosition:  1
            visible:        _currentItem && _transectCount > 3

            property int nextTrueTransectIndex: _firstTrueTransectIndex + (_hasTurnaround ? 4 : 2)
        }
    }

    Component {
        id: exitArrow1Component

        MapLineArrow {
            map:map
            fromCoord:      _transectPoints[_lastTrueTransectIndex - 1]
            toCoord:        _transectPoints[_lastTrueTransectIndex]
            arrowPosition:  3
            visible:        _currentItem
        }
    }

    Component {
        id: exitArrow2Component

        MapLineArrow {
            map:map
            fromCoord:      _transectPoints[prevTrueTransectIndex - 1]
            toCoord:        _transectPoints[prevTrueTransectIndex]
            arrowPosition:  13
            visible:        _currentItem && _transectCount > 3

            property int prevTrueTransectIndex: _lastTrueTransectIndex - (_hasTurnaround ? 4 : 2)
        }
    }

    // Exit point
    Component {
        id: exitPointComponent

        MapQuickItem {
            anchorPoint.x:  sourceItem.anchorPointX
            anchorPoint.y:  sourceItem.anchorPointY
            z:              QGroundControl.zOrderMapItems
            coordinate:     _missionItem.exitCoordinate
            visible:        _missionItem.exitCoordinate.isValid

            sourceItem: MissionItemIndexLabel {
                index:      _missionItem.lastSequenceNumber
                checked:    _missionItem.isCurrentItem
                onClicked:  {
                    console.log('run')
                    _root.clicked(_missionItem.sequenceNumber)
                }
            }
        }
    }
}
