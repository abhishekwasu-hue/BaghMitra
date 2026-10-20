plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Test builds are signed with a dedicated test keystore passed in by CI (docs/runbooks/test-apk.md);
// without it the release build falls back to the debug key so it still installs. The Play upload
// key is a different key, handled by Play App Signing.
val testKeystorePath: String? = System.getenv("TEST_KEYSTORE_PATH")

android {
    namespace = "app.bagmitra.bagmitra"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "app.bagmitra.bagmitra"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        // CI passes the run number so every test build installs over the previous one.
        versionCode = System.getenv("BUILD_NUMBER")?.toIntOrNull() ?: flutter.versionCode
        versionName = System.getenv("BUILD_NAME") ?: flutter.versionName
    }

    signingConfigs {
        if (testKeystorePath != null) {
            create("test") {
                storeFile = file(testKeystorePath)
                storePassword = System.getenv("TEST_KEYSTORE_PASSWORD")
                keyAlias = System.getenv("TEST_KEY_ALIAS")
                keyPassword = System.getenv("TEST_KEY_PASSWORD")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName(
                if (testKeystorePath != null) "test" else "debug",
            )
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
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
