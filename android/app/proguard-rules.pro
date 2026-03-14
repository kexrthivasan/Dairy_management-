# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# Workmanager plugin
-keep class dev.fluttercommunity.workmanager.** { *; }

# Google Play Core (required by Flutter's deferred components — suppress missing class warnings)
-dontwarn com.google.android.play.core.splitcompat.SplitCompatApplication
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**

# Google Sign-In
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# Hive
-keep class com.google.gson.** { *; }
-keep class * extends com.google.gson.TypeAdapter
-keep class * extends com.google.gson.TypeAdapterFactory
-keep class * extends com.google.gson.JsonDeserializer
-keep class * extends com.google.gson.JsonSerializer

# Keep generated Hive adapter classes
-keep class **HiveAdapter { *; }
-keep @com.hive.* class * { *; }

# General
-keepattributes *Annotation*
-keepattributes SourceFile,LineNumberTable
