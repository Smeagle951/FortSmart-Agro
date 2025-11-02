buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.android.tools.build:gradle:8.7.0")
        // classpath("com.google.gms:google-services:4.3.15") // Removido - Firebase não está sendo usado
    }
    
    // Desabilitar verificação de namespace para todos os plugins
    System.setProperty("android.enableNamespaceCheck", "false")
}

// Plugins são definidos no settings.gradle.kts

// Aplicar o fix de namespace para o plugin mapbox_gl
apply(from = "mapbox_namespace_fix.gradle")

// Aplicar o fix específico para o plugin qr_code_scanner
apply(from = "qr_code_scanner_fix.gradle")

// Aplicar o fix específico para o plugin background_location
apply(from = "background_location_namespace_fix.gradle")

// Correção de namespace simplificada

allprojects {
    repositories {
        google()
        mavenCentral()
    }
    

}

subprojects {
    tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
        kotlinOptions {
            jvmTarget = "17"
        }
    }
    afterEvaluate {
        extensions.findByName("android")?.let {
            (it as com.android.build.gradle.BaseExtension).compileOptions.apply {
                sourceCompatibility = JavaVersion.VERSION_17
                targetCompatibility = JavaVersion.VERSION_17
            }
        }
    }
}


// Organização de diretórios de build (opcional, mas limpo)
val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
