def call() {
    parallel(
        wsl: {
            node('wsl') {
                runInContainer('build/linux-release/src/helium_test_suite')
            }
        },
        windows: {
            node('windows') {
                bat 'build\\win-debug\\src\\helium_test_suite.exe'
            }
        }
    )
}
