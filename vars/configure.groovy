def call(platform, branch = null) {
    if (branch) {
        checkout([$class: 'GitSCM', branches: [[name: "*/${branch}"]],
                  userRemoteConfigs: [[url: 'https://github.com/disrado/helium.git', credentialsId: 'helium_github_app']],
                  extensions: [[$class: 'SubmoduleOption', recursiveSubmodules: true, parentCredentials: true]]])
    } else {
        checkout([$class: 'GitSCM', branches: scm.branches, userRemoteConfigs: scm.userRemoteConfigs,
                  extensions: [[$class: 'SubmoduleOption', recursiveSubmodules: true, parentCredentials: true]]])
    }
    if (platform == 'linux') {
        runInContainer('cmake --preset linux-release')
    } else {
        bat 'cmake --preset win-debug'
    }
}
