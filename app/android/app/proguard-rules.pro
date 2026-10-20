# R8 keep rules for release builds. Flutter's own rules ship with the Flutter Gradle plugin; these
# cover the plugins that reach native or reflective code. Add the Play Billing library here in M6b.

# geolocator (Google Play services location + platform channel handlers)
-keep class com.baseflow.geolocator.** { *; }
-keep class com.google.android.gms.location.** { *; }

# drift / sqlite3 (native library loaded through FFI, plus the Android helper classes)
-keep class eu.simonbinder.sqlite3_flutter_libs.** { *; }
-keep class org.sqlite.** { *; }

# share_plus (file provider and share intents)
-keep class dev.fluttercommunity.plus.share.** { *; }

# speech_to_text and flutter_tts (platform channels reach their classes by name)
-keep class com.csdcorp.speech_to_text.** { *; }
-keep class com.tundralabs.fluttertts.** { *; }

# Plugin registrants are looked up by name
-keep class io.flutter.plugins.GeneratedPluginRegistrant { *; }
-dontwarn com.google.android.play.core.**

# flutter_local_notifications serialises scheduled notifications with Gson.
-keep class com.dexterous.** { *; }
-keepattributes *Annotation*, Signature
