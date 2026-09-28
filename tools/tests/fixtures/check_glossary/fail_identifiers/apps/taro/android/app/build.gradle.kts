plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.vshyrochuk.taro"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // Required by flutter_local_notifications.
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        applicationId = "com.vshyrochuk.taro"
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        // Google's sample AdMob app ID until Phase 10 creates the real AdMob
        // app (prod only). Ad unit IDs come from config/<flavor>.json.
        manifestPlaceholders["admobAppId"] = "ca-app-pub-3940256099942544~3347511713"
        manifestPlaceholders["usesCleartextTraffic"] = "false"
    }

    // Flavors (02 AR17, §15): bundle suffix and launcher name per environment.
    flavorDimensions += "env"
    productFlavors {
        create("dev") {
            dimension = "env"
            applicationIdSuffix = ".debug"
            manifestPlaceholders["appName"] = "Taro Dev"
            // Local `wrangler dev` Worker over http (02 §16); see
            // src/dev/res/xml/network_security_config.xml.
            manifestPlaceholders["usesCleartextTraffic"] = "true"
        }
        create("staging") {
            dimension = "env"
            applicationIdSuffix = ".stg"
            manifestPlaceholders["appName"] = "Taro Beta"
        }
        create("prod") {
            dimension = "env"
            manifestPlaceholders["appName"] = "Taro"
        }
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
}
