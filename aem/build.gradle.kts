plugins {
    id("com.cognifide.aem.instance")
    id("com.cognifide.aem.environment")
    id("com.cognifide.aem.package.sync")
}

subprojects {
    apply(plugin = "com.cognifide.aem.package.sync")
}

apply(from = rootProject.file("gradle/common.gradle.kts"))

aem {
    environment {
        docker {
            containers {
                "httpd" {
                    resolve {
                        resolveFiles {
                            download("http://download.macromedia.com/dispatcher/download/dispatcher-apache2.4-linux-x86_64-4.3.3.tar.gz").use {
                                copyArchiveFile(it, "**/dispatcher-apache*.so", file("modules/mod_dispatcher.so"))
                            }
                        }
                        ensureDir("cache", "logs")
                    }
                    up {
                        ensureDir("/usr/local/apache2/logs", "/opt/aem/dispatcher/cache/content/example/demo", "/opt/aem/dispatcher/cache/content/example/live")
                        execShell("Starting HTTPD server", "/usr/local/apache2/bin/httpd -k start")
                    }
                    reload {
                        cleanDir("/opt/aem/dispatcher/cache/content/example/demo", "/opt/aem/dispatcher/cache/content/example/live")
                        execShell("Restarting HTTPD server", "/usr/local/apache2/bin/httpd -k restart")
                    }
                    dev {
                        watchConfigDir("conf")
                    }
                }
            }
        }
        hosts {
            author("http://author.example.com")
            publish("http://demo.example.com") { tag("test") }
            publish("http://example.com") { tag("live") }
            other("http://dispatcher.example.com")
        }
        healthChecks {
            url("Live site", "http://www.example.com/content/wknd/us/en.html") { containsText("WKND") }
            url("Author module 'Sites'", "http://www.author.example.com/sites.html") {
                options { basicCredentials = authorInstance.credentials }
                containsText("Sites")
            }
        }
    }

    localInstance {
        install {
            files {
                // https://github.com/Cognifide/gradle-aem-plugin#pre-installed-osgi-bundles-and-crx-packages
            }
        }
    }

    tasks {
        registerOrConfigure<Task>("setup", "resetup") {
            dependsOn(":develop")
        }

        localInstance {
            install {
                files {
                    download("https://repo1.maven.org/maven2/com/icfolson/aem/groovy/console/aem-groovy-console/13.0.0/aem-groovy-console-13.0.0.zip")
                }
            }
        }
        instanceSatisfy {
            packages {
                // "dep.vanity-urls"("pkg/vanityurls-components-1.0.2.zip")
                "dep.kotlin"("org.jetbrains.kotlin:kotlin-osgi-bundle:${Build.KOTLIN_VERSION}")
                "dep.core-components-all"("com.adobe.cq:core.wcm.components.all:2.7.0@zip")
                // "dep.core-components-examples"("com.adobe.cq:core.wcm.components.examples:2.7.0@zip")
                "tool.ac-tool"("https://repo1.maven.org/maven2/biz/netcentric/cq/tools/accesscontroltool", "accesscontroltool-package/2.3.2/accesscontroltool-package-2.3.2.zip", "accesscontroltool-oakindex-package/2.3.2/accesscontroltool-oakindex-package-2.3.2.zip")
                "tool.search-webconsole-plugin"("com.neva.felix:search-webconsole-plugin:1.2.0")

                //APM
                "tool.cq.actions.api"("com.cognifide.cq.actions:com.cognifide.cq.actions.api:6.4.0")
                "tool.cq.actions.core"("com.cognifide.cq.actions:com.cognifide.cq.actions.core:6.4.0")
                "tool.cq.actions.replication.message"("com.cognifide.cq.actions:com.cognifide.cq.actions.msg.replication:6.4.0")
                "tool.apm.cognifide"("com.cognifide.aem:apm:4.2.2")

                //WKND project
                "dep.wknd.tutorial"("https://github.com/adobe/aem-guides-wknd/releases/download/aem-guides-wknd-0.0.2/aem-guides-wknd.all-0.0.2.zip")
            }
        }
        instanceProvision {
            step("enable-crxde") {
                description = "Enables CRX DE"
                condition { once() && instance.environment != "prod" }
                action {
                    sync {
                        osgiFramework.configure("org.apache.sling.jcr.davex.impl.servlets.SlingDavExServlet", mapOf(
                                "alias" to "/crx/server"
                        ))
                    }
                }
            }
        }

        instanceProvision {
            // https://github.com/Cognifide/gradle-aem-plugin#task-instanceprovision
        }
    }
}
