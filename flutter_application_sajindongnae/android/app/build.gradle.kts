plugins {
    id("com.android.application")
    id("kotlin-android")
    // Flutter Gradle Plugin은 반드시 Android/Kotlin 뒤에
    id("dev.flutter.flutter-gradle-plugin")
    // ✅ Google services 플러그인: 여기서 바로 적용 (apply false 쓰지 말기)
    id("com.google.gms.google-services") version "4.4.2"
}

android {
    namespace = "com.example.flutter_application_sajindongnae"

    // Flutter가 관리하는 compileSdk를 그대로 사용
    compileSdk = flutter.compileSdkVersion

    // 권장: minSdk 23 이상 (전화 인증/Play Integrity 경로)
    defaultConfig {
        applicationId = "com.example.flutter_application_sajindongnae"
        minSdk = flutter.minSdkVersion           // ← 24여도 되지만 23 권장
        targetSdk = 35
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions {
        jvmTarget = "17"
    }


    // (선택) NDK가 필요 없다면 명시 제거 가능
    // ndkVersion = "27.0.12077973"
    // min-branch에 있었어서 남겨놨는데 
    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.flutter_application_sajindongnae"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        // minSdk = flutter.minSdkVersion
        minSdk = 24                      
        targetSdk = 35
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }
    // 여기까지

    buildTypes {
        release {
            // 실제 배포 땐 release 서명키로 교체
            signingConfig = signingConfigs.getByName("debug")
            // minifyEnabled = false
            // proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // ⛔️ FlutterFire가 알아서 의존성을 주입하므로
    // ⛔️ Firebase BoM / 개별 firebase-* 의존성은 추가하지 마세요.
    //
    // implementation(platform("com.google.firebase:firebase-bom:34.2.0"))  // 삭제
    // implementation("com.google.firebase:firebase-auth")                   // 삭제
}

// ⛔️ Groovy 문법의 apply plugin은 삭제!
// apply plugin: 'com.google.gms.google-services'
