multibranchPipelineJob('pre_commit') {
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
        def sourcesNode = node.children().find { it.name() == 'sources' }
        def dataNode = sourcesNode.children().find { it.name() == 'data' }
        def branchSourceNode = dataNode.children().find { it.name() == 'jenkins.branch.BranchSource' }
        def sourceNode = branchSourceNode.children().find { it.name() == 'source' }
        sourceNode.children().findAll { it.name() == 'traits' }.each { sourceNode.remove(it) }
        def traits = sourceNode.appendNode('traits')
        traits.appendNode('org.jenkinsci.plugins.github__branch__source.OriginPullRequestDiscoveryTrait')
              .appendNode('strategyId', 2)
        def forkTrait = traits.appendNode('org.jenkinsci.plugins.github__branch__source.ForkPullRequestDiscoveryTrait')
        forkTrait.appendNode('strategyId', 2)
        forkTrait.appendNode('trust', [class: 'org.jenkinsci.plugins.github_branch_source.ForkPullRequestDiscoveryTrait$TrustPermission'])
    }
}
