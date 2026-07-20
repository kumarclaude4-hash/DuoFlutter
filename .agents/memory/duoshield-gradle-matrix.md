---
name: DuoShield Gradle version matrix
description: Exact compatible AGP / Gradle / Kotlin / SDK versions for the DuoFlutter Android build
---

## Working version set (as of run #13)

| Component | Version |
|-----------|---------|
| Android Gradle Plugin (AGP) | 8.9.1 |
| Gradle wrapper | 8.11.1 |
| Kotlin | 2.0.21 |
| compileSdk | 36 |
| targetSdk | 35 |
| minSdk | 26 |
| Flutter channel | stable 3.44.6 |

**Why these exact versions:**
- `androidx.browser:1.9.0` and `androidx.activity:activity-ktx:1.12.4` require compileSdk ≥ 36 AND AGP ≥ 8.9.1
- AGP 8.9.x requires Gradle ≥ 8.11.1
- AGP 8.7.3 max supported compileSdk is 35 — cannot use 36 with it

**How to apply:**
- `settings.gradle`: plugin id `"com.android.application"` version `"8.9.1"`
- `gradle-wrapper.properties`: `distributionUrl=...gradle-8.11.1-all.zip`
- `app/build.gradle`: `compileSdk 36`, `targetSdk 35`

## Core library desugaring
`flutter_local_notifications` requires it. Must add to `app/build.gradle`:
```groovy
compileOptions {
    coreLibraryDesugaringEnabled true
}
dependencies {
    coreLibraryDesugaring 'com.android.tools:desugar_jdk_libs:2.1.4'
}
```
