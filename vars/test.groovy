def call() {
    parallel(
        wsl: {
            node('wsl') {
                runInContainer('ctest --preset linux-release')
            }
        },
        windows: {
            node('windows') {
                bat 'ctest --preset win-debug'
            }
        }
    )
}
