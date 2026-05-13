# Flutter MainActivity NICHT entfernen
-keep class com.schuetzenradar.app.MainActivity { *; }

# Flutter core
-keep class io.flutter.** { *; }

# Firebase
-keep class com.google.firebase.** { *; }

# verhindern dass Reflection kaputt geht
-keepattributes *Annotation*

# keep all Activities (safe)
-keep class * extends android.app.Activity
