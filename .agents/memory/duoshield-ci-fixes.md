---
name: DuoShield CI build fixes
description: History of Dart/Gradle errors hit in CI and how each was resolved
---

## Dart fixes (conflict remnants from git overlay import)
- `display_name_screen.dart` + `restore_from_seed_screen.dart`: duplicate `final token` lines — keep hex-value version
- `theme.dart`: `DialogTheme` → `DialogThemeData`, `TabBarTheme` → `TabBarThemeData`
- `seed_phrase_helper.dart`: `bip39.wordlists.english` does not exist — replaced with `bip39.validateMnemonic` logic
- `conversation_list_screen.dart` line ~141: `items: [...]` in `showMenu()` must be typed as `<PopupMenuEntry<String>>[...]`

## Gradle/AGP progression
- Run #9: flutter pub get fixed (conflict markers gone)
- Run #10: settings.gradle migrated to declarative `pluginManagement`/`plugins {}` DSL (required by Flutter 3.44.6)
- Run #11: AGP 8.3→8.7.3, Gradle 8.7→8.9, Kotlin 1.9.22→2.0.21, compileSdk 34→35
- Run #12: CheckAarMetadataWorkAction — 13 AAR issues (browser:1.9.0, activity-ktx:1.12.4 etc.) needed compileSdk 36 + AGP 8.9.1
- Run #13: AGP 8.7.3→8.9.1, Gradle 8.9→8.11.1, compileSdk 35→36, targetSdk 34→35, coreLibraryDesugaringEnabled true, desugar_jdk_libs:2.1.4
- Run #13 failure: record_linux:0.7.2 missing startStream/hasPermission vs record_platform_interface:1.6.0
- Run #14-15: dependency solver conflicts (record_platform_interface 1.5.1 doesn't exist; record 6.2.1 + share_plus 9.x web version conflict)
- Run #16: flutter_webrtc ^0.10.6 + mobile_scanner ^5.1.0 + file_picker ^8.0.0 all need web ^1.0.0 compatible versions
- Run #17: pub get passed! Build failed: duplicate libsqlcipher.so (sqflite_sqlcipher AND explicit android-database-sqlcipher dep)
- Run #18 fix: removed android-database-sqlcipher from app/build.gradle

## Web package version alignment (critical)
All packages must agree on `web` version. record 6.2.1 + record_web 1.3.0 requires `web ^1.0.0`:
- `record: ^6.2.1` (was ^5.1.0) — brings record_linux:^1.3.1 compatible with platform_iface:^1.6.0
- `share_plus: ^10.0.1` (was ^9.0.0) — 10.0.0 still used web ^0.5.0; 10.0.1+ uses web ^1.0.0
- `flutter_webrtc: ^0.11.7` (was ^0.10.6) — 0.11.7+ uses web ^1.0.0
- `mobile_scanner: ^5.2.1` (was ^5.1.0) — 5.2.1 uses web >=0.5.1 <2.0.0 (compat)
- `file_picker: ^8.1.0` (was ^8.0.0) — 8.1.0+ uses web ^1.0.0

## Gradle wrapper
- `gradle/wrapper/` was entirely absent from repo — had to create jar, properties, gradlew, gradlew.bat from scratch
- Existing wrapper jar bootstraps any version; only `gradle-wrapper.properties` needs updating for version bumps

## Duplicate native lib fix
- `sqflite_sqlcipher` bundles its own `libsqlcipher.so` — never add `net.zetetic:android-database-sqlcipher` explicitly in app/build.gradle
- Same principle applies to `androidx.sqlite` — let sqflite_sqlcipher manage its own deps

## settings.gradle DSL (Flutter 3.44.6 requirement)
Must use declarative style — old `apply from:` imperative style breaks with Flutter 3.44.6+:
```groovy
pluginManagement {
    def flutterSdkPath = { ... }()
    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")
    repositories { google(); mavenCentral(); gradlePluginPortal() }
}
plugins {
    id "dev.flutter.flutter-plugin-loader" version "1.0.0"
    id "com.android.application" version "8.9.1" apply false
    id "org.jetbrains.kotlin.android" version "2.0.21" apply false
    ...
}
```
