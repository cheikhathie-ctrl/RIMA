import java.util.Properties

plugins {
    id("com.android.application")

    // Firebase / Google Services
    id("com.google.gms.google-services")

    // Flutter Gradle Plugin must be applied
    // after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val localProperties = Properties()

val localPropertiesFile =
    rootProject.file("local.properties")

if (localPropertiesFile.exists()) {
    localPropertiesFile.inputStream().use { input ->
        localProperties.load(input)
    }
}

val googleMapsApiKey =
    localProperties.getProperty(
        "GOOGLE_MAPS_API_KEY",
        "",
    )

android {
    namespace = "mr.rima.rima_customer"

    // Android API level used to compile RIMA.
    // Moosyl dependencies now require API 36 or later.
    compileSdk = 36

    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "mr.rima.rima_customer"

        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion

        versionCode = flutter.versionCode
        versionName = flutter.versionName

        manifestPlaceholders[
            "GOOGLE_MAPS_API_KEY"
        ] = googleMapsApiKey
    }

    buildTypes {
        release {
            // Development signing only.
            // We will create the production RIMA
            // signing key before release.
            signingConfig =
                signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget =
            org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}