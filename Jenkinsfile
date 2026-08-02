pipeline {
    agent { label 'linux' }
    stages {
        stage('Build images') {
            steps {
                sh 'docker build -t helium-linux-build-env:latest build_env/linux'
                sh 'docker build -t helium-linux-jenkins-agent:latest jenkins_agent/linux'
            }
        }
    }
}
