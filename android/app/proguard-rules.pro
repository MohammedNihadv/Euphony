# R8 keep rules for the release build.
#
# Most plugins ship their own consumer rules inside their AAR, so this file only
# covers what R8 cannot see: classes reached by reflection or from native code,
# which look unused to static analysis and get stripped.

# --- Playback -----------------------------------------------------------
# just_audio plays through ExoPlayer, which instantiates renderers, extractors
# and DRM components reflectively by class name. Stripping them turns into a
# ClassNotFoundException the first time a track loads in release — and only in
# release, which is the worst way to find out.
-keep class com.google.android.exoplayer2.** { *; }
-keep class androidx.media3.** { *; }
-dontwarn com.google.android.exoplayer2.**
-dontwarn androidx.media3.**

# audio_service's media session is declared in the manifest and started by the
# OS, so nothing in the compiled code references it.
-keep class com.ryanheise.audioservice.** { *; }
-keep class com.ryanheise.just_audio.** { *; }

# --- Database -----------------------------------------------------------
# sqlite3_flutter_libs loads the native library through JNI.
-keep class com.tekartik.sqflite.** { *; }
-dontwarn org.sqlite.**

# --- Flutter ------------------------------------------------------------
# Plugin registration resolves by name.
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-dontwarn io.flutter.embedding.engine.deferredcomponents.**
-dontwarn com.google.android.play.core.**

# Keep annotations that drive the above, and line numbers so release crash
# reports stay readable.
-keepattributes *Annotation*, InnerClasses, Signature, SourceFile, LineNumberTable
-renamesourcefileattribute SourceFile
