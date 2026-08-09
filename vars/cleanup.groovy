def call() {
    cleanWs(patterns: [
        [pattern: '.git/**', type: 'EXCLUDE'],
        [pattern: 'build/**', type: 'EXCLUDE'],
        [pattern: 'deps/godot/**', type: 'EXCLUDE'],
        [pattern: 'deps/godot_cpp/**', type: 'EXCLUDE']
    ])
}
