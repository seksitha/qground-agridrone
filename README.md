### QT verion 5.12.5 (Master now 5.15.2)

- chose 5.12.5 `MVMC 2017` `android eamV7` & `86x` & `Qt chart`
- MinGW chose `base system gcc g++ 4.x`

### Adroid sdk

- 19.x ndk
- plateform
- skd buid tool

### Mac
- we need to install gradle to build successfully
- `brew install gradle` is install incorrect gradle version
- need to use sdkman https://sdkman.io/
https://stackoverflow.com/questions/25769536/how-when-to-generate-gradle-wrapper-files
### this is qt command build android
`Starting: "/Users/sithasek/Qt5.12.5/5.12.5/android_armv7/bin/androiddeployqt" --input /Users/sithasek/001_Codes/build-qgroundcontrol-Android_for_armeabi_v7a_Clang_Qt_5_12_5_for_Android_ARMv7-Debug/android-libQGroundControl.so-deployment-settings.json --output /Users/sithasek/001_Codes/build-qgroundcontrol-Android_for_armeabi_v7a_Clang_Qt_5_12_5_for_Android_ARMv7-Debug/android-build --android-platform android-25 --jdk /Library/Java/JavaVirtualMachines/jdk-1.8.jdk/Contents/Home --verbose --gradle`

### could not load main class
- for qt it the problem is with gradle specifily gradlew exec java command we need to take out --stacktrace
https://stackoverflow.com/questions/18093928/what-does-could-not-find-or-load-main-class-mean
- when building we need to the keystore in make_apk profile. follow link below solve our problem
https://stackoverflow.com/questions/66846074/how-to-solve-invalid-keystore-format


### todo
- double click add polygon vertix 
- TAKE OUT: auto takeoff, red square, clickme, doubleclick, index number 2 confuse