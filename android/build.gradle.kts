allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

subprojects {
    afterEvaluate {
        if (extensions.findByName("android") != null) {
            val androidExtension = extensions.findByName("android")
            val namespaceProperty = androidExtension?.javaClass?.getMethod("getNamespace")?.invoke(androidExtension)
            if (namespaceProperty == null) {
                val group = project.group.toString()
                androidExtension?.javaClass?.getMethod("setNamespace", String::class.java)
                    ?.invoke(androidExtension, group)
            }
        }
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
