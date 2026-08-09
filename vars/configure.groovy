def call() {
    parallel(
        wsl: {
            node('wsl') {
                checkout([$class: 'GitSCM', branches: scm.branches, userRemoteConfigs: scm.userRemoteConfigs,
                          extensions: [[$class: 'SubmoduleOption', recursiveSubmodules: true, parentCredentials: true]]])
                runInContainer('cmake --preset linux-release')
            }
        },
        windows: {
            node('windows') {
                checkout([$class: 'GitSCM', branches: scm.branches, userRemoteConfigs: scm.userRemoteConfigs,
                          extensions: [[$class: 'SubmoduleOption', recursiveSubmodules: true, parentCredentials: true]]])
                bat 'cmake --preset win-debug'
            }
        }
    )
}
