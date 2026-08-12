def call(platform, buildType = 'debug', kind = 'editor') {
    def preset = platform == 'linux' ? "linux-${buildType}" : "win-${buildType}"
    def godotPreset = platform == 'linux' ? "${kind}-linux-${buildType}" : "${kind}-windows-${buildType}"
    if (platform == 'linux') {
        runInContainer("cmake --build --preset ${preset}")
        runInContainer("cmake --build --preset ${godotPreset}")
    } else {
        bat "cmake --build --preset ${preset}"
        bat "cmake --build --preset ${godotPreset}"
    }
}
