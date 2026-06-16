plugins {
    id("com.android.application")
    id("kotlin-android") // أضفنا هذا السطر ليتعرف على أوامر كوتلن
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.my_new_app"
    compileSdk = 36 

    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }

    // تصحيح طريقة كتابة جافا وكوتلن داخل بلوك أندرويد
    kotlinOptions {
        jvmTarget = "1.8"
    }

        defaultConfig {
        applicationId = "com.example.my_new_app"
        minSdk = flutter.minSdkVersion 
        targetSdk = 36
        
        // أضفنا الأقواس هنا لحل مشكلة Function invocation
        versionCode = flutter.versionCode()
        versionName = flutter.versionName()
    }


    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}

flutter {
    source = "../.."
}
