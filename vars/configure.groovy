def call(platform, branch = null, buildType = 'debug') {
    if (branch) {
        checkout([$class: 'GitSCM', branches: [[name: "*/${branch}"]],
                  userRemoteConfigs: [[url: 'https://github.com/disrado/helium.git', credentialsId: 'helium_github_app']],
                  extensions: [[$class: 'SubmoduleOption', recursiveSubmodules: true, parentCredentials: true]]])
    } else {
        checkout([$class: 'GitSCM', branches: scm.branches, userRemoteConfigs: scm.userRemoteConfigs,
                  extensions: [[$class: 'SubmoduleOption', recursiveSubmodules: true, parentCredentials: true]]])
    }
    def preset = platform == 'linux' ? "linux-${buildType}" : "win-${buildType}"
    if (platform == 'linux') {
        runInContainer("cmake --preset ${preset}")
    } else {
        bat "cmake --preset ${preset}"
    }
}
