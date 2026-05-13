import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()

if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.schuetzenradar.app"
    compileSdk = flutter.compileSdkVersion

    ndkVersion = "28.2.13676358"

    defaultConfig {
        applicationId = "com.schuetzenradar.app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // ✅ Stabilität
        multiDexEnabled = true
    }

    //--------------------------------------------------
    // ✅ SIGNING (DAS IST DER FIX 🔥)
    //--------------------------------------------------
    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = file("keystore.jks")
            storePassword = keystoreProperties["storePassword"] as String
        }
    }

    //--------------------------------------------------
    // ✅ AAB SPLIT FIX
    //--------------------------------------------------
    bundle {
        language {
            enableSplit = false
        }
        density {
            enableSplit = false
        }
        abi {
            enableSplit = false
        }
    }

    //--------------------------------------------------
    // ✅ JVM
    //--------------------------------------------------
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    //--------------------------------------------------
    // ✅ BUILD TYPES
    //--------------------------------------------------
    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("release")  // 🔥 wichtig!

            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

dependencies {
    implementation(platform("com.google.firebase:firebase-bom:34.12.0"))
    implementation("com.google.firebase:firebase-analytics")

    implementation("androidx.multidex:multidex:2.0.1")
}

flutter {
    source = "../.."
}