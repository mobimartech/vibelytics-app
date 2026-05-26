import java.util.Properties
import java.io.FileInputStream
import java.io.File
import org.jetbrains.kotlin.gradle.dsl.JvmTarget

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Load key.properties file
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "play.store.vibelytics"
    compileSdk = 37
    ndkVersion = "30.0.14904198"
    buildToolsVersion = "37.0.0"

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_24
        targetCompatibility = JavaVersion.VERSION_24
    }

    defaultConfig {
        applicationId = "play.store.vibelytics"
        minSdk = 24
        targetSdk = 37
        versionCode = 11
        versionName = "1.0.6"

        vectorDrawables.useSupportLibrary = true
    }

    androidResources {
        localeFilters += listOf("en", "ar")
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
            storeFile = keystoreProperties["storeFile"]?.let { File(it as String) }
            storePassword = keystoreProperties["storePassword"] as String?
        }
    }

    buildTypes {
        debug {
            isMinifyEnabled = false
            isShrinkResources = false
            // Disable PNG crunching for faster debug builds
            isCrunchPngs = false
        }

        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }

    // Disable unused build features for faster builds.
    // renderScript is omitted — it's deprecated and being removed in AGP 10.
    buildFeatures {
        buildConfig = false
        aidl = false
        shaders = false
    }

    // Lint configuration for faster builds
    lint {
        checkReleaseBuilds = false
        abortOnError = false
    }
    
    bundle {
        language {
            enableSplit = true
        }
        density {
            enableSplit = true
        }
        abi {
            enableSplit = true
        }
    }
    
    packaging {
        resources {
            excludes += listOf(
                "META-INF/LICENSE.txt",
                "META-INF/NOTICE.txt",
                "META-INF/*.kotlin_module",
                "META-INF/AL2.0",
                "META-INF/LGPL2.1",
                "kotlin/**",
                "DebugProbesKt.bin"
            )
        }
        jniLibs {
            useLegacyPackaging = false
        }
    }

}

// Apply the new compilerOptions DSL at the project root (AGP 9 / Kotlin 2.3+).
// Replaces the deprecated `kotlinOptions { jvmTarget = "..." }` block.
tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
    compilerOptions {
        jvmTarget.set(JvmTarget.JVM_24)
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
    // Legacy Google Sign-In API (fallback for devices without CredentialManager UI)
    implementation("com.google.android.gms:play-services-auth:21.5.1")
}