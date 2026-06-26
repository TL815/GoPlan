# GoPlan Flutter

GoPlan is now a Flutter Android/iOS app shell with a native map bridge.

## Current Status

- Flutter UI shell is implemented in `lib/main.dart`.
- Existing GoPlan image/icon assets are registered in `pubspec.yaml`.
- Android uses a native `PlatformView` backed by AMap `MapView`.
- Flutter sends POI data to Android through `MethodChannel("goplan/native_map")`.
- iOS has the same `PlatformView`/`MethodChannel` bridge shape and is ready for `MAMapKit`.

## Build

```powershell
cd D:\03_项目工作区\GoPlan-flutter
flutter build apk --debug
```

The debug APK is generated at:

```text
build\app\outputs\flutter-apk\app-debug.apk
```

## Android AMap Key

The Android manifest reads the key from the Gradle property `AMAP_API_KEY`.

For one-off testing, run Gradle directly with:

```powershell
android\gradlew.bat -p android :app:assembleDebug -PAMAP_API_KEY=your_android_amap_key
```

You can also add this line to `android/gradle.properties` for local development:

```properties
AMAP_API_KEY=your_android_amap_key
```

After that, the normal Flutter command will include the key:

```powershell
flutter build apk --debug
```

Do not commit real production keys.

## Android Native Map Files

- `android/app/src/main/kotlin/com/tl815/goplan/MainActivity.kt`
- `android/app/src/main/AndroidManifest.xml`
- `android/app/build.gradle.kts`

The Android map currently supports:

- Native AMap display.
- Marker rendering from Flutter POI data.
- Camera fit to marker bounds.
- `setMarkers` and `moveCamera` method channel commands.

## iOS Native Map Next Step

The iOS bridge is prepared in:

```text
ios/Runner/NativeMapView.swift
ios/Runner/AppDelegate.swift
```

On macOS, add the iOS AMap SDK (`MAMapKit`) through CocoaPods or Swift Package Manager, then replace the placeholder `UIView` in `NativeMapView.swift` with `MAMapView`.

The Flutter-facing API should remain the same:

```text
PlatformView id: goplan/native_map_view
MethodChannel:   goplan/native_map
```
