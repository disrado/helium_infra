def call() {
    parallel(
        wsl: {
            node('wsl') {
                runInContainer('cmake --build --preset linux-release')
                runInContainer('cmake --build --preset editor-linux')
            }
        },
        windows: {
            node('windows') {
                bat 'cmake --build --preset win-debug'
                bat 'cmake --build --preset editor-windows'
            }
        }
    )
}
