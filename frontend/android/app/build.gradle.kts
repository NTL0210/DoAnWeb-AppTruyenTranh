plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.demo"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.demo"  // ✅ QUAN TRỌNG: Phải khớp với Google Console
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // ✅ CƯỠNG CHẾ: Cả debug và release đều dùng debug keystore
    // SHA-1 sẽ GIỐNG NHAU: C0:9F:B6:E7:D1:A6:AD:4D:31:8C:10:84:62:A2:55:34:FA:86:1C:35
    signingConfigs {
        getByName("debug") {
            storeFile = file("${System.getProperty("user.home")}/.android/debug.keystore")
            storePassword = "android"
            keyAlias = "androiddebugkey"
            keyPassword = "android"
        }
    }

    buildTypes {
        getByName("debug") {
            signingConfig = signingConfigs.getByName("debug")
        }
        getByName("release") {
            // ✅ CƯỠNG CHẾ release dùng debug keystore
            signingConfig = signingConfigs.getByName("debug")
            
            // ❌ TẮT minify để tránh lỗi với Google Play Services
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // ✅ Google Play Services for Google Sign-In
    implementation("com.google.android.gms:play-services-auth:20.7.0")
}