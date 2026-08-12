def call(platform, buildType = 'debug') {
    def preset = platform == 'linux' ? "linux-${buildType}" : "win-${buildType}"
    if (platform == 'linux') {
        runInContainer("ctest --preset ${preset}")
    } else {
        bat "ctest --preset ${preset}"
    }
}
