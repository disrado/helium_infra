def call(platform) {
    if (platform == 'linux') {
        runInContainer('ctest --preset linux-release')
    } else {
        bat 'ctest --preset win-debug'
    }
}
