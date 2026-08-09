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
            stage('Platforms') {
                parallel {
                    stage('wsl') {
                        agent { label 'wsl' }
                        stages {
                            stage('Configure') { steps { script { configure('wsl') } } }
                            stage('Build')     { steps { script { build('wsl') } } }
                            stage('Test')      { steps { script { test('wsl') } } }
                        }
                        post { always { script { cleanup() } } }
                    }
                    stage('windows') {
                        agent { label 'windows' }
                        stages {
                            stage('Configure') { steps { script { configure('windows') } } }
                            stage('Build')     { steps { script { build('windows') } } }
                            stage('Test')      { steps { script { test('windows') } } }
                        }
                        post { always { script { cleanup() } } }
                    }
                }
            }
        }
    }
}
