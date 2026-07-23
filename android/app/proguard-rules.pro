# Flutter's default rules are added automatically by the Flutter Gradle plugin.

# --- flutter_local_notifications -------------------------------------------
# The plugin (de)serialises scheduled notifications with Gson via reflection.
-keep class com.dexterous.** { *; }
-keep class com.google.gson.** { *; }
-keep class * extends com.google.gson.reflect.TypeToken { *; }
-keepattributes Signature, *Annotation*, EnclosingMethod, InnerClasses

# Keep generic signatures for Gson TypeToken usage.
-keep,allowobfuscation,allowshrinking class com.google.gson.reflect.TypeToken
-keep,allowobfuscation,allowshrinking class * extends com.google.gson.reflect.TypeToken
