plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Signing (audit RL-02 / R4):
// - Production APKs (the "Release APK" workflow, RELEASE_BUILD=true) are signed with the owner's
//   release keystore (docs/runbooks/release-apk.md). Without it the build stops: never the debug key.
// - Test builds are signed with a dedicated test keystore passed in by CI (docs/runbooks/test-apk.md);
//   without it the test build falls back to the debug key so it still installs.
// The two keys differ, so a test APK and a release APK cannot be installed over each other.
val releaseKeystorePath: String? = System.getenv("RELEASE_KEYSTORE_PATH")?.takeIf { it.isNotBlank() }
val productionBuild: Boolean = System.getenv("RELEASE_BUILD") == "true"
val testKeystorePath: String? = System.getenv("TEST_KEYSTORE_PATH")

if (productionBuild) {
    val missing = listOf(
        "RELEASE_KEYSTORE_PATH",
        "RELEASE_KEYSTORE_PASSWORD",
        "RELEASE_KEY_ALIAS",
        "RELEASE_KEY_PASSWORD",
    ).filter { System.getenv(it).isNullOrBlank() }
    if (missing.isNotEmpty()) {
        throw GradleException("Production build without the release key: set ${missing.joinToString()}")
    }
}

android {
    namespace = "app.bagmitra.bagmitra"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // flutter_local_notifications needs java.time on older Android versions.
        isCoreLibraryDesugaringEnabled = true
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
        // CI passes the run number so every build installs over the previous one. The Release APK
        // workflow also passes -P force-version-code-ignoring-abi=true, so its arm64-v8a and
        // armeabi-v7a APKs carry the same, ever-rising code (audit R5) that /v1/app/version compares.
        versionCode = System.getenv("BUILD_NUMBER")?.toIntOrNull() ?: flutter.versionCode
        versionName = System.getenv("BUILD_NAME") ?: flutter.versionName
    }

    signingConfigs {
        if (releaseKeystorePath != null) {
            create("release") {
                storeFile = file(releaseKeystorePath)
                storePassword = System.getenv("RELEASE_KEYSTORE_PASSWORD")
                keyAlias = System.getenv("RELEASE_KEY_ALIAS")
                keyPassword = System.getenv("RELEASE_KEY_PASSWORD")
            }
        }
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
                when {
                    releaseKeystorePath != null -> "release"
                    productionBuild -> throw GradleException("Production build without the release key")
                    testKeystorePath != null -> "test"
                    else -> "debug"
                },
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

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
}
