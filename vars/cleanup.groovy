def call() {
    parallel(
        wsl: {
            node('wsl') {
                cleanWs(patterns: [
                    [pattern: '.git/**', type: 'EXCLUDE'],
                    [pattern: 'build/**', type: 'EXCLUDE'],
                    [pattern: 'deps/godot/**', type: 'EXCLUDE'],
                    [pattern: 'deps/godot_cpp/**', type: 'EXCLUDE']
                ])
            }
        },
        windows: {
            node('windows') {
                cleanWs(patterns: [
                    [pattern: '.git/**', type: 'EXCLUDE'],
                    [pattern: 'build/**', type: 'EXCLUDE'],
                    [pattern: 'deps/godot/**', type: 'EXCLUDE'],
                    [pattern: 'deps/godot_cpp/**', type: 'EXCLUDE']
                ])
            }
        }
    )
}
