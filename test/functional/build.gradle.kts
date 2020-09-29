import com.moowork.gradle.node.yarn.YarnTask

plugins {
    id("com.cognifide.aem.common")
    id("com.github.node-gradle.node")
}

apply(from = rootProject.file("gradle/common.gradle.kts"))

description = "Example - Protractor Tests"

tasks {

    register<YarnTask>("runTests") {
        dependsOn("yarn")
        setWorkingDir(projectDir)
        setYarnCommand("runtests")
    }
}
