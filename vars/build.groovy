def call(platform) {
    if (platform == 'linux') {
        runInContainer('cmake --build --preset linux-release')
        runInContainer('cmake --build --preset editor-linux')
    } else {
        bat 'cmake --build --preset win-debug'
        bat 'cmake --build --preset editor-windows'
    }
}
