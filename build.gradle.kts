plugins {
    id("com.neva.fork")
    id("com.cognifide.aem.common")
    id("org.sonarqube")
}

apply(from = "gradle/fork/fork.gradle.kts")
apply(from = "gradle/fork/props.gradle.kts")
apply(from = "gradle/common.gradle.kts")

description = "Example"
defaultTasks("develop")

aem {
    tasks {
        registerSequence("develop", {
            description = "Builds and deploys AEM application to instances, cleans environment then runs all tests"
        }) {
            if (!prop.flag("setup.skip")) {
                dependsOn(":aem:instanceSetup")
            }
            dependsOn(":aem:assembly:full:packageDeploy")
            dependsOn(
                    ":aem:environmentReload",
                    ":aem:environmentAwait"
            )
        }
    }
}

sonarqube {
    properties {
        property("sonar.projectKey", "aem.mit.poc")
        property("sonar.projectName", "AEM MIT POC")
        property("sonar.exclusions", "test/**")
    }
}
