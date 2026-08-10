def call() {
    pipeline {
        agent none
        options {
            disableConcurrentBuilds(abortPrevious: true)
            buildDiscarder(logRotator(numToKeepStr: '10'))
        }
        environment {
            IMAGE = 'helium-linux-build-env:latest'
        }
        stages {
            stage('Platforms') {
                parallel {
                    stage('linux') {
                        agent { label 'wsl' }
                        stages {
                            stage('Configure') {
                                steps { script { catchError(stageResult: 'FAILURE') { configure('linux') } } }
                            }
                            stage('Build') {
                                when { expression { currentBuild.currentResult != 'FAILURE' } }
                                steps { script { catchError(stageResult: 'FAILURE') { build('linux') } } }
                            }
                            stage('Test') {
                                when { expression { currentBuild.currentResult != 'FAILURE' } }
                                steps { script { catchError(stageResult: 'FAILURE') { test('linux') } } }
                            }
                            stage('Cleanup') { steps { script { cleanup() } } }
                        }
                    }
                    stage('windows') {
                        agent { label 'windows' }
                        stages {
                            stage('Configure') {
                                steps { script { catchError(stageResult: 'FAILURE') { configure('windows') } } }
                            }
                            stage('Build') {
                                when { expression { currentBuild.currentResult != 'FAILURE' } }
                                steps { script { catchError(stageResult: 'FAILURE') { build('windows') } } }
                            }
                            stage('Test') {
                                when { expression { currentBuild.currentResult != 'FAILURE' } }
                                steps { script { catchError(stageResult: 'FAILURE') { test('windows') } } }
                            }
                            stage('Cleanup') { steps { script { cleanup() } } }
                        }
                    }
                }
            }
        }
    }
}
