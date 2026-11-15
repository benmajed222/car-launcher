# Proguard rules for BenMajed Cockpit Car Launcher

-keep class com.aam.carlauncher.** { *; }
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}
