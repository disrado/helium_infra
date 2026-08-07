def call() {
    parallel(
        wsl: {
            node('wsl') {
                runInContainer('build/linux-release/engine/helium_test_suite')
                runInContainer('build/linux-release/game/game_test_suite')
            }
        },
        windows: {
            node('windows') {
                bat 'build\\win-debug\\engine\\helium_test_suite.exe'
                bat 'build\\win-debug\\game\\game_test_suite.exe'
            }
        }
    )
}
