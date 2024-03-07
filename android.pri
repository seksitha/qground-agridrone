include($$PWD/libs/qtandroidserialport/src/qtandroidserialport.pri)
message("Adding Serial Java Classes")
QT += androidextras
ANDROID_PACKAGE_SOURCE_DIR = $$PWD/android
OTHER_FILES += \
    $$PWD/android/AndroidManifest.xml \
    $$PWD/android/res/xml/device_filter.xml \
    $$PWD/android/src/com/hoho/android/usbserial/driver/CdcAcmSerialDriver.java \
    $$PWD/android/src/com/hoho/android/usbserial/driver/CommonUsbSerialDriver.java \
    $$PWD/android/src/com/hoho/android/usbserial/driver/Cp2102SerialDriver.java \
    $$PWD/android/src/com/hoho/android/usbserial/driver/FtdiSerialDriver.java \
    $$PWD/android/src/com/hoho/android/usbserial/driver/ProlificSerialDriver.java \
    $$PWD/android/src/com/hoho/android/usbserial/driver/UsbId.java \
    $$PWD/android/src/com/hoho/android/usbserial/driver/UsbSerialDriver.java \
    $$PWD/android/src/com/hoho/android/usbserial/driver/UsbSerialProber.java \
    $$PWD/android/src/com/hoho/android/usbserial/driver/UsbSerialRuntimeException.java \
    $$PWD/android/src/org/mavlink/bayondrone/QGCActivity.java \
    $$PWD/android/src/org/mavlink/bayondrone/UsbIoManager.java \
    $$PWD/android/src/org/mavlink/bayondrone/TaiSync.java \
    $$PWD/android/src/org/freedesktop/gstreamer/androidmedia/GstAhcCallback.java \
    $$PWD/android/src/org/freedesktop/gstreamer/androidmedia/GstAhsCallback.java \
    $$PWD/android/src/org/freedesktop/gstreamer/androidmedia/GstAmcOnFrameAvailableListener.java


DISTFILES += \
    $$PWD/android/gradle/wrapper/gradle-wrapper.jar \
    $$PWD/android/gradlew \
    $$PWD/android/res/values/libs.xml \
    $$PWD/android/build.gradle \
    $$PWD/android/gradle/wrapper/gradle-wrapper.properties \
    $$PWD/android/gradlew.bat
