# Preserve Flutter framework and plugins
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Preserve your app's classes
-keep class com.idtrack.hotel.** { *; }
# Gson
-keep class com.google.gson.** { *; }
-dontwarn com.google.gson.**

# Retrofit/OkHttp (optional)
-dontwarn retrofit2.**
-dontwarn okhttp3.**
-dontwarn okio.**
-keep class retrofit2.** { *; }
-keep class okhttp3.** { *; }

# Fix for missing Play Core classes used in deferred components
-keep class com.google.android.play.** { *; }
-dontwarn com.google.android.play.**
-keep class com.google.android.play.core.tasks.** { *; }
-dontwarn com.google.android.play.core.tasks.**
-keep class io.flutter.embedding.engine.deferredcomponents.** { *; }

# Razorpay fix
-dontwarn proguard.annotation.Keep
-dontwarn proguard.annotation.KeepClassMembers
-keep class com.razorpay.** { *; }
-dontwarn com.razorpay.**
