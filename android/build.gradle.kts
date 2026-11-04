plugins {
    id("com.android.library")
}

group = "com.epicdarkgalaxy.bellflow"
version = "1.1.0"

android {
    namespace = "com.epicdarkgalaxy.bellflow"
    compileSdk = 36

    defaultConfig {
        minSdk = 24
        manifestPlaceholders["ENABLE_SCHEDULED_NOTIFICATIONS"] =
            (rootProject.findProperty("ENABLE_SCHEDULED_NOTIFICATIONS")?.toString()?.toBoolean() ?: true).toString()
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

}