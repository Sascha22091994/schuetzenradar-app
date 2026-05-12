plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.schuetzenradar.app"
    compileSdk = flutter.compileSdkVersion

    // ✅ NDK FIX
    ndkVersion = "28.2.13676358"

    defaultConfig {
        applicationId = "com.schuetzenradar.app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    //--------------------------------------------------
    // ✅ JVM FIX (DEIN HAUPTPROBLEM)
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
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

dependencies {
    implementation(platform("com.google.firebase:firebase-bom:34.12.0"))
    implementation("com.google.firebase:firebase-analytics")
}

flutter {
    source = "../.."
}