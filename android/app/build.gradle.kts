import java.util.Properties
import java.io.FileInputStream


plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties ()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream (keystorePropertiesFile));
}

android {
    namespace = "com.techwings.fmiscup"
    compileSdk = 35
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.techwings.fmiscup"
        minSdk = 26
        targetSdk = 35
        versionCode = 7
        versionName = "1.0.7"
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties ["keyAlias"] as String?
            keyPassword = keystoreProperties ["keyPassword"]  as String?
            storeFile = file(keystoreProperties["storeFile"] as String)
            storePassword = keystoreProperties ["storePassword"] as String?
        }

    }


    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("release")
            isShrinkResources = true
            isMinifyEnabled = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
}

flutter {
    source = "../.."
}
