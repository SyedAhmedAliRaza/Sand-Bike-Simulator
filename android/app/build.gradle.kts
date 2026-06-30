// android/app/build.gradle.kts
plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin") // Crucial for Flutter builds
}

android {
    compileSdk = 36
    namespace = "com.example.sand_bike_sim"

    defaultConfig {
        applicationId = "com.example.sand_bike_sim"
        minSdk = flutter.minSdkVersion
        targetSdk = 34
        versionCode = 1
        versionName = "1.0"
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlin {
        jvmToolchain(17)
    }

    buildTypes {
        getByName("debug") {
            isDebuggable = true
            // This forces the output to be predictable
        }
        getByName("release") {
            isMinifyEnabled = false
            isShrinkResources = false // Add this line!
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

dependencies {
    implementation("org.jetbrains.kotlin:kotlin-stdlib-jdk8")
}
