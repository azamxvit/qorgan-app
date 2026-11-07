import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val uploadProperties = Properties()
val uploadPropertiesFile = rootProject.file("key.properties")
if (uploadPropertiesFile.exists()) {
    uploadPropertiesFile.inputStream().use { uploadProperties.load(it) }
}
fun uploadValue(property: String, environment: String): String? =
    System.getenv(environment)?.takeIf { it.isNotBlank() }
        ?: uploadProperties.getProperty(property)?.takeIf { it.isNotBlank() }

val uploadStore = uploadValue("storeFile", "QORGAN_KEYSTORE_PATH")
val uploadAlias = uploadValue("keyAlias", "QORGAN_KEY_ALIAS")
val uploadStorePassword = uploadValue("storePassword", "QORGAN_KEYSTORE_PASSWORD")
val uploadKeyPassword = uploadValue("keyPassword", "QORGAN_KEY_PASSWORD")
// Only the CI APK smoke job may explicitly opt into a disposable debug key.
// App bundles never accept this option, even if a real upload key is present.
val smokeSigning = providers.gradleProperty("qorganSmokeSigning").orNull == "true"

gradle.taskGraph.whenReady {
    val appReleaseTasks = allTasks.filter {
        it.project.path == ":app" && it.name.contains("Release", ignoreCase = true)
    }
    val buildsAppBundle = allTasks.any {
        it.project.path == ":app" &&
            (it.name.matches(Regex("bundle(Debug|Profile|Release)")) ||
                it.name.matches(Regex("(sign|package)(Debug|Profile|Release)Bundle")))
    }
    if (smokeSigning && buildsAppBundle) {
        throw GradleException("Smoke signing is APK-only. A Play App Bundle requires the private upload key.")
    }
    if (appReleaseTasks.isNotEmpty() && !smokeSigning &&
        (uploadStore == null || uploadAlias == null || uploadStorePassword == null ||
            uploadKeyPassword == null || !rootProject.file(uploadStore).isFile)) {
        throw GradleException(
            "Release signing is not configured. Use android/key.properties or QORGAN_KEYSTORE_* " +
                "environment variables; see docs/google-play/build-and-upload.md. Debug signing is never implicit."
        )
    }
}

android {
    namespace = "kz.qorgan.qorgan_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "kz.qorgan.qorgan_app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (uploadStore != null) storeFile = rootProject.file(uploadStore)
            keyAlias = uploadAlias
            storePassword = uploadStorePassword
            keyPassword = uploadKeyPassword
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName(if (smokeSigning) "debug" else "release")
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
