def call(platform) {
    if (platform == 'wsl') {
        runInContainer('ctest --preset linux-release')
    } else {
        bat 'ctest --preset win-debug'
    }
}
