// setup_agent job: rebuilds the build-env and agent images on an already-registered agent
pipeline {
    agent { label 'linux' }
    stages {
        stage('Build build-env image') {
            steps {
                sh 'docker build -t helium-linux-build-env:latest build_env/linux'
            }
        }
        stage('Build agent image') {
            steps {
                sh 'docker build -t helium-linux-jenkins-agent:latest jenkins_agent/linux'
            }
        }
    }
    post {
        always { cleanWs() }
    }
}
