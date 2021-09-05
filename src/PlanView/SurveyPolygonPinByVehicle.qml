import QtQuick          2.3

import QGroundControl               1.0
import QGroundControl.ScreenTools   1.0
import QGroundControl.Palette       1.0
import QGroundControl.Controls      1.0

Rectangle {
    id: pinVehiclePosition
    signal pinByVehicle(real xPosition, real yPosition)
    signal pinByPointer(real xPosition, real yPosition)
    signal pinByHandHeld(real xPosition, real yPosition)    
    signal pinByPhoneGPS(real xPosition, real yPosition)    
}
