def call() {
    pipeline {
        agent none
        options {
            disableConcurrentBuilds(abortPrevious: true)
        }
        environment {
            IMAGE = 'helium-linux-build-env:latest'
        }
        stages {
            stage('Configure') {
                steps { script { configure() } }
            }
            stage('Build') {
                steps { script { build() } }
            }
            stage('Test') {
                steps { script { test() } }
            }
        }
        post {
            always {
                script { cleanup() }
            }
        }
    }
}
