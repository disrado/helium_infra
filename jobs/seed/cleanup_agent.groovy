pipelineJob('cleanup_agent') {
    definition {
        cpsScm {
            scm {
                git {
                    remote {
                        url('https://github.com/disrado/helium_infra.git')
                        credentials('helium_github_app')
                    }
                }
            }
            scriptPath('jobs/cleanup_agent/Jenkinsfile')
        }
    }
}
