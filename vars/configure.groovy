def call(platform) {
    checkout([$class: 'GitSCM', branches: scm.branches, userRemoteConfigs: scm.userRemoteConfigs,
              extensions: [[$class: 'SubmoduleOption', recursiveSubmodules: true, parentCredentials: true]]])
    if (platform == 'linux') {
        runInContainer('cmake --preset linux-release')
    } else {
        bat 'cmake --preset win-debug'
    }
}
