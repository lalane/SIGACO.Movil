import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Firma de la version release. En el pipeline llega por variables de entorno (SIGACO_KEYSTORE_*); en local, de
// android/key.properties (storeFile, storePassword, keyAlias, keyPassword), que no se versiona. Sin ninguna de las
// dos, release se firma con la llave de depuracion: sirve para probar en local, no para distribuir.
val keyProperties = Properties().apply {
    val file = rootProject.file("key.properties")
    if (file.exists()) file.inputStream().use { load(it) }
}
fun signingValue(env: String, property: String): String? =
    System.getenv(env)?.takeIf { it.isNotBlank() } ?: keyProperties.getProperty(property)?.takeIf { it.isNotBlank() }
val releaseKeystore = signingValue("SIGACO_KEYSTORE_PATH", "storeFile")

// Ambiente: la app de DEVIDARE se instala junto a la de QA con otro id y otro nombre
// (SIGACO_APP_ID_SUFFIX=.devidare, SIGACO_APP_LABEL="SIGACO DEV"). Sin variables queda la de siempre.
val appIdSuffix = System.getenv("SIGACO_APP_ID_SUFFIX")?.takeIf { it.isNotBlank() }
val appLabel = System.getenv("SIGACO_APP_LABEL")?.takeIf { it.isNotBlank() } ?: "SIGACO"

android {
    namespace = "com.idare.sigaco_movil"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    signingConfigs {
        if (releaseKeystore != null) {
            create("release") {
                storeFile = file(releaseKeystore)
                storePassword = signingValue("SIGACO_KEYSTORE_PASSWORD", "storePassword")
                keyAlias = signingValue("SIGACO_KEY_ALIAS", "keyAlias") ?: "sigaco"
                keyPassword = signingValue("SIGACO_KEY_PASSWORD", "keyPassword") ?: storePassword
            }
        }
    }

    defaultConfig {
        applicationId = "com.idare.sigaco_movil"
        applicationIdSuffix = appIdSuffix
        manifestPlaceholders["appLabel"] = appLabel
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        // minSdk: Android 10 (propuesta, pendiente de confirmar - DTF RNF-MOB-01). targetSdk: ultima estable.
        minSdk = 29
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.findByName("release") ?: signingConfigs.getByName("debug")
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
