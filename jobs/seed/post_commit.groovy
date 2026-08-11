multibranchPipelineJob('post_commit') {
    branchSources {
        github {
            id('1')
            scanCredentialsId('helium_github_app')
            repoOwner('disrado')
            repository('helium')
            traits {
                gitHubBranchDiscovery {
                    strategyId(1)
                }
            }
        }
    }
    orphanedItemStrategy {
        discardOldItems {
            daysToKeep(-1)
            numToKeep(-1)
        }
    }
    triggers {
        periodicFolderTrigger {
            interval('4h')
        }
    }
    factory {
        workflowBranchProjectFactory {
            scriptPath('Jenkinsfile')
        }
    }
}
