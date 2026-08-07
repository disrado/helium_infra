def call() {
    parallel(
        wsl: {
            node('wsl') {
                checkout scm
                runInContainer('cmake --preset linux-release')
            }
        },
        windows: {
            node('windows') {
                checkout scm
                bat 'cmake --preset win-debug'
            }
        }
    )
}
