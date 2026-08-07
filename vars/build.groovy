def call() {
    parallel(
        wsl: {
            node('wsl') {
                runInContainer('cmake --build build/linux-release')
            }
        },
        windows: {
            node('windows') {
                bat 'cmake --build build/win-debug'
            }
        }
    )
}
