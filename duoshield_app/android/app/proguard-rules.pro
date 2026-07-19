# ── Flutter ──────────────────────────────────────────────────────────────────
-keep class io.flutter.** { *; }
-dontwarn io.flutter.**

# ── Firebase ──────────────────────────────────────────────────────────────────
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# ── SQLCipher ─────────────────────────────────────────────────────────────────
-keep class net.sqlcipher.** { *; }
-keep class net.sqlcipher.database.** { *; }
-dontwarn net.sqlcipher.**

# ── WebRTC (flutter_webrtc) ───────────────────────────────────────────────────
-keep class org.webrtc.** { *; }
-dontwarn org.webrtc.**

# ── Kotlin ────────────────────────────────────────────────────────────────────
-keep class kotlin.** { *; }
-keep class kotlin.Metadata { *; }
-dontwarn kotlin.**
-keepclassmembers class **$WhenMappings {
    <fields>;
}

# ── Gson / JSON (used internally by Firebase) ─────────────────────────────────
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn sun.misc.**
-keep class com.google.gson.** { *; }

# ── Coroutines (Kotlin, used internally by Firebase SDK) ──────────────────────
-keepnames class kotlinx.coroutines.internal.MainDispatcherFactory {}
-keepnames class kotlinx.coroutines.CoroutineExceptionHandler {}

# ── OkHttp (used by Firebase) ─────────────────────────────────────────────────
-dontwarn okhttp3.**
-dontwarn okio.**

# ── BouncyCastle / PointyCastle (crypto) ─────────────────────────────────────
-keep class org.bouncycastle.** { *; }
-dontwarn org.bouncycastle.**

# ── Prevent stripping of native methods ──────────────────────────────────────
-keepclasseswithmembernames class * {
    native <methods>;
}
