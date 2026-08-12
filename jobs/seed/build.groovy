pipelineJob('build') {
    definition {
        cpsScm {
            scm {
                git {
                    remote {
                        name('infra')
                        url('https://github.com/disrado/helium_infra.git')
                        credentials('helium_github_app')
                    }
                    remote {
                        name('game')
                        url('https://github.com/disrado/helium.git')
                        credentials('helium_github_app')
                    }
                    branch('infra/main')
                }
            }
            scriptPath('jobs/build/Jenkinsfile')
            lightweight(false)
        }
    }
}
