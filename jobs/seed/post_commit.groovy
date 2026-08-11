multibranchPipelineJob('post_commit') {
    branchSources {
        github {
            id('1')
            apiUri('https://api.github.com')
            scanCredentialsId('helium_github_app')
            repoOwner('disrado')
            repository('helium')
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
            interval('1d')
        }
    }
    factory {
        workflowBranchProjectFactory {
            scriptPath('Jenkinsfile')
        }
    }
    // GitHubBranchSourceContext (job-dsl-core) predates the traits API entirely (no plugin ships trait
    // support for Job DSL either) - traits must be patched into the generated XML directly.
    configure { node ->
        def source = node.sources[0].data[0].'jenkins.branch.BranchSource'[0].source[0]
        source.traits.each { source.remove(it) }
        def traits = source.appendNode('traits')
        traits.appendNode('org.jenkinsci.plugins.github__branch__source.BranchDiscoveryTrait')
              .appendNode('strategyId', 1)
    }
}
