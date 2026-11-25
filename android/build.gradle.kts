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
subprojects {
    project.evaluationDependsOn(":app")
}

// Kotlin-incrementele compilatie (IC) slaat bronpaden op relatief aan deze
// map. Plugins uit de pub-cache liggen erbuiten; op Windows faalt de build
// als de pub-cache op een ander station staat dan het project (KT-63983),
// bijv. cache op C: en project op E:. IC staat daarom uit voor subprojecten
// buiten de repo (in pub-cache-plugins verandert niets tussen builds); de
// eigen :app-module blijft gewoon incrementeel.
subprojects {
    if (!projectDir.canonicalPath.startsWith(rootDir.canonicalPath)) {
        extra["kotlin.incremental"] = "false"
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
