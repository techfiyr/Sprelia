allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
// Some audio plugins (e.g. flutter_pcm_sound) pin an old compileSdk that their
// AndroidX dependencies reject. Raise library modules to the app's compileSdk.
subprojects {
    val forceCompileSdk: Project.() -> Unit = {
        extensions.findByType(com.android.build.gradle.LibraryExtension::class.java)?.let {
            if ((it.compileSdk ?: 0) < 36) it.compileSdk = 36
        }
    }
    if (state.executed) forceCompileSdk() else afterEvaluate { forceCompileSdk() }
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
