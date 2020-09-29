plugins {
    id("org.jetbrains.kotlin.jvm")
    id("com.cognifide.aem.bundle")
}

apply(from = rootProject.file("gradle/common.gradle.kts"))

group = "com.cognifide.example"
description = "Example - AEM Sites"

aem {
    tasks {
        packageCompose {
            vaultDefinition {
                property("installhook.actool.class", "biz.netcentric.cq.tools.actool.installhook.AcToolInstallHook")
            }
            // required by APM bundle
            fromJar("com.cognifide.cq.actions:com.cognifide.cq.actions.api:4.0.0")
        }

        bundleCompose {
            javaPackage = "com.cognifide.example"
        }
    }
}
