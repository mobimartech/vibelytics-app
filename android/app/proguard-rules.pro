# ============================================================================
# MAIN ACTIVITY - CRITICAL
# ============================================================================
-keep class play.store.vibelytics.MainActivity { *; }
-keep class play.store.vibelytics.** { *; }
-keep class com.google.android.gms.auth.api.signin.** { *; }

# ============================================================================
# FLUTTER CORE RULES
# ============================================================================
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }

# ============================================================================
# GOOGLE PLAY CORE - FIX FOR MISSING CLASSES
# Flutter references these classes but they're optional
# ============================================================================
-dontwarn com.google.android.play.core.splitcompat.SplitCompatApplication
-dontwarn com.google.android.play.core.splitinstall.SplitInstallException
-dontwarn com.google.android.play.core.splitinstall.SplitInstallManager
-dontwarn com.google.android.play.core.splitinstall.SplitInstallManagerFactory
-dontwarn com.google.android.play.core.splitinstall.SplitInstallRequest$Builder
-dontwarn com.google.android.play.core.splitinstall.SplitInstallRequest
-dontwarn com.google.android.play.core.splitinstall.SplitInstallSessionState
-dontwarn com.google.android.play.core.splitinstall.SplitInstallStateUpdatedListener
-dontwarn com.google.android.play.core.tasks.OnFailureListener
-dontwarn com.google.android.play.core.tasks.OnSuccessListener
-dontwarn com.google.android.play.core.tasks.Task
-dontwarn com.google.android.play.core.**

# ============================================================================
# NATIVE METHODS
# ============================================================================
-keepclasseswithmembernames class * {
    native <methods>;
}

# ============================================================================
# PARCELABLE & SERIALIZABLE
# ============================================================================
-keepclassmembers class * implements android.os.Parcelable {
    static ** CREATOR;
}

-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# ============================================================================
# PLUGINS
# ============================================================================
# open_filex plugin
-keep class com.crazecoder.openfile.** { *; }

# flutter_contacts plugin
-keep class com.alexmob.flutter_contacts.** { *; }

# permission_handler plugin
-keep class com.baseflow.permissionhandler.** { *; }

# url_launcher plugin
-keep class io.flutter.plugins.urllauncher.** { *; }

# shared_preferences plugin
-keep class io.flutter.plugins.sharedpreferences.** { *; }

# path_provider plugin
-keep class io.flutter.plugins.pathprovider.** { *; }

# ============================================================================
# PERFORMANCE OPTIMIZATIONS
# ============================================================================
# Enable aggressive optimizations
-optimizationpasses 5
-allowaccessmodification
-repackageclasses ''

# Remove logging in release builds
-assumenosideeffects class android.util.Log {
    public static *** d(...);
    public static *** v(...);
    public static *** i(...);
    public static *** w(...);
}

# ============================================================================
# ATTRIBUTES TO KEEP
# ============================================================================
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes SourceFile,LineNumberTable
-keepattributes InnerClasses,EnclosingMethod
-keepattributes Exceptions

# ============================================================================
# KOTLIN
# ============================================================================
-dontwarn kotlin.**
-keep class kotlin.** { *; }
-keep class kotlin.Metadata { *; }
-keepclassmembers class kotlin.Metadata {
    public <methods>;
}

# ============================================================================
# OKHTTP & OKIO (used by http package)
# ============================================================================
-dontwarn okhttp3.**
-dontwarn okio.**
-keep class okhttp3.** { *; }
-keep interface okhttp3.** { *; }

# ============================================================================
# GSON (if using JSON serialization)
# ============================================================================
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn sun.misc.**
-keep class com.google.gson.** { *; }
-keep class * extends com.google.gson.TypeAdapter
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer
-keepclassmembers,allowobfuscation class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# ============================================================================
# GENERAL ANDROID
# ============================================================================
-keep public class * extends android.app.Activity
-keep public class * extends android.app.Application
-keep public class * extends android.app.Service
-keep public class * extends android.content.BroadcastReceiver
-keep public class * extends android.content.ContentProvider
-keep public class * extends android.view.View

# Keep custom views
-keep public class * extends android.view.View {
    public <init>(android.content.Context);
    public <init>(android.content.Context, android.util.AttributeSet);
    public <init>(android.content.Context, android.util.AttributeSet, int);
}

# Keep onClick handlers
-keepclassmembers class * extends android.app.Activity {
    public void *(android.view.View);
}

# ============================================================================
# ENUMS
# ============================================================================
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# ============================================================================
# R8 SPECIFIC RULES
# ============================================================================
# Only ignore specific warnings, not all warnings
-dontwarn com.google.android.play.core.**
-dontwarn org.jetbrains.annotations.**
