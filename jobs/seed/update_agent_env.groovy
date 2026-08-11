pipelineJob('update_agent_env') {
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
            scriptPath('jobs/update_agent_env/Jenkinsfile')
        }
    }
}
