import QtQuick          2.3

import QGroundControl               1.0
import QGroundControl.ScreenTools   1.0
import QGroundControl.Palette       1.0
import QGroundControl.Controls      1.0

Rectangle {
    id: pinVehiclePosition
    signal pushed(real xPosition, real yPosition)
    
}
