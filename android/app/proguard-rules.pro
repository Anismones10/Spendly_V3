# R8 keep rules for the release build.
#
# Everything here exists because R8 cannot see the reference: the class is
# reached from native code, from the manifest, or by name through reflection.
# A missing rule of this kind builds cleanly and fails at runtime, so treat
# deletions here as behaviour changes rather than cleanup.

# ── Flutter embedding ──────────────────────────────────────────────────────
# Reached from the engine's native side. The Flutter Gradle plugin contributes
# most of this; kept explicit so a plugin upgrade cannot quietly drop it.
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.embedding.** { *; }

# Flutter's deferred-components code path references Play Core even in apps
# that never use deferred components. Without this R8 fails the build on
# missing classes rather than warning.
-dontwarn com.google.android.play.core.**

# ── flutter_local_notifications ────────────────────────────────────────────
# Scheduled notifications are serialised to disk with Gson and rehydrated after
# a reboot. If these classes are renamed, every scheduled reminder is silently
# lost — days after a build that looked fine.
-keep class com.dexterous.** { *; }
-dontwarn com.dexterous.**
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes InnerClasses
-keepattributes EnclosingMethod

# Gson resolves generic types reflectively, so the token classes and any
# @SerializedName field must survive.
-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# ── Firebase / Google Sign-In ──────────────────────────────────────────────
# The SDKs ship consumer rules, but documents read back from Firestore are
# constructed reflectively and annotations drive that mapping.
-keepattributes RuntimeVisibleAnnotations
-keepattributes RuntimeVisibleParameterAnnotations
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# ── home_widget ────────────────────────────────────────────────────────────
# The receiver and its layouts are named in the manifest and from Dart, never
# called from Java, so R8 sees no reference to them.
-keep class es.antonborri.home_widget.** { *; }

# ── local_auth ─────────────────────────────────────────────────────────────
-dontwarn androidx.biometric.**
