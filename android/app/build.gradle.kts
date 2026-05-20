plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.ind.classifieds"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "28.2.13676358"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    signingConfigs {
        create("release") {
            keyAlias = "upload"
            keyPassword = "indclassifieds"
            storePassword = "indclassifieds"
            storeFile = file("upload-keystore.jks")
        }
    }

    defaultConfig {
        applicationId = "com.ind.classifieds"
        minSdkVersion(24)
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        getByName("release") {
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            // Signing config: upload keystore (release).
            //
            // The upload keystore's SHA-1 (18:70:2C:71:63:AB:3B:32:...)
            // is registered in Google Cloud Console under the
            // `com.ind.classifieds` Android OAuth client, so Google
            // Sign-In works on release-signed APKs without needing the
            // debug-keystore workaround we used during the migration.
            //
            // If Sign-In ever breaks again with ApiException 10/12500,
            // first verify: keytool -list -v -keystore upload-keystore.jks
            // -alias upload  →  the SHA-1 there should match the one
            // registered in Firebase Console + Google Cloud OAuth.
            // Once you upload to Play Store, also register the
            // Play App Signing SHA-1 (Play re-signs with its own key).
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

dependencies {
        coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    implementation("com.facebook.android:facebook-android-sdk:17.0.1")
}

flutter {
    source = "../.."
}
