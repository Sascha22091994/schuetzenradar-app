import org.gradle.api.tasks.Delete
import org.gradle.api.file.Directory

//--------------------------------------------------
// ✅ REPOSITORIES
//--------------------------------------------------
allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

//--------------------------------------------------
// ✅ GOOGLE SERVICES PLUGIN
//--------------------------------------------------
plugins {
    id("com.google.gms.google-services") version "4.4.2" apply false
}

buildscript {
    dependencies {
        classpath("com.google.gms:google-services:4.4.2")
    }
}

//--------------------------------------------------
// ✅ BUILD DIR RELOCATION (optional aber ok)
//--------------------------------------------------
val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()

rootProject.layout.buildDirectory.value(newBuildDir)

//--------------------------------------------------
// ✅ SUBPROJECT BUILD DIR
//--------------------------------------------------
subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

subprojects {
    project.evaluationDependsOn(":app")
}

//--------------------------------------------------
// ✅ CLEAN TASK
//--------------------------------------------------
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}