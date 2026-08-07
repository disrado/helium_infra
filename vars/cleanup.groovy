def call() {
    parallel(
        wsl: {
            node('wsl') {
                cleanWs()
            }
        },
        windows: {
            node('windows') {
                cleanWs()
            }
        }
    )
}
