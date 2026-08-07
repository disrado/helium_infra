def call(command) {
    sh """docker run --rm -v \$WORKSPACE:/workspace -v vcpkg_cache:/root/.cache/vcpkg -w /workspace ${env.IMAGE} bash -c '
        dump_logs_on_failure() {
            if [ "\$1" -ne 0 ]; then
                find /opt/vcpkg/buildtrees -name \"*.log\" -exec echo ==={}=== \\; -exec cat {} \\;
            fi
        }

        ${command}
        code=\$?
        dump_logs_on_failure \$code
        exit \$code
    '"""
}
