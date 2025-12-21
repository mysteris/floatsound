# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep custom classes
-keep class com.mysteris.floatsound.** { *; }

# Keep reflection
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses
-keepattributes EnclosingMethod

# Keep serialization
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# Remove logging
-assumenosideeffects class android.util.Log {
    public static boolean isLoggable(java.lang.String, int);
    public static int v(...);
    public static int i(...);
    public static int w(...);
    public static int d(...);
    public static int e(...);
}

# Suppress warnings for missing Play Core classes
-dontwarn com.google.android.play.core.splitcompat.SplitCompatApplication

# FilePicker ProGuard rules
-keep class com.mr.flutter.plugin.filepicker.** { *; }
-dontwarn com.mr.flutter.plugin.filepicker.**
-keep class miguelruivo.flutter.plugins.filepicker.** { *; }
-dontwarn miguelruivo.flutter.plugins.filepicker.**

# Permission Handler ProGuard rules
-keep class com.baseflow.permissionhandler.** { *; }
-dontwarn com.baseflow.permissionhandler.**

# Keep all Flutter plugins
-keep class io.flutter.plugins.** { *; }

# Keep all plugin classes
-keep class **.Plugin { *; }
-keep class **.Plugin$* { *; }

# Keep FilePicker specifically
-keep class com.mr.flutter.plugin.filepicker.FilePickerPlugin { *; }
-keep class com.mr.flutter.plugin.filepicker.FilePickerDelegate { *; }
-keep class com.mr.flutter.plugin.filepicker.FilePickerUtils { *; }
-keep class com.mr.flutter.plugin.filepicker.** { *; }

# Keep permission handler specifically
-keep class com.baseflow.permissionhandler.PermissionHandlerPlugin { *; }
-keep class com.baseflow.permissionhandler.MethodCallHandlerImpl { *; }
-keep class com.baseflow.permissionhandler.PermissionManager { *; }
-keep class com.baseflow.permissionhandler.PermissionConstants { *; }
-keep class com.baseflow.permissionhandler.PermissionUtils { *; }
-keep class com.baseflow.permissionhandler.** { *; }

# Keep permission handler implementation
-keep class com.baseflow.permissionhandler.PermissionHandlerPlugin { *; }
-keep class com.baseflow.permissionhandler.** { *; }

# Keep shared preferences
-keep class io.flutter.plugins.sharedpreferences.** { *; }

# Keep all plugin registrants
-keep class **.PluginRegistrant { *; }
-keep class **.PluginRegistrant.** { *; }

# Keep generated plugin registrant
-keep class io.flutter.plugins.GeneratedPluginRegistrant { *; }
-keep class io.flutter.plugins.GeneratedPluginRegistrant.** { *; }