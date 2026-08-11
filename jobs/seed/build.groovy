pipelineJob('build') {
    definition {
        cpsScm {
            scm {
                git {
                    remote {
                        url('https://github.com/disrado/helium_infra.git')
                        credentials('helium_github_app')
                    }
                    remote {
                        url('https://github.com/disrado/helium.git')
                        credentials('helium_github_app')
                    }
                }
            }
            scriptPath('jobs/build/Jenkinsfile')
            lightweight(false)
        }
    }
}
