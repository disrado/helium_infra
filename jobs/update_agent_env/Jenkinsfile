// update_agent_env job: updates the chosen platform's agent environment (Docker images on WSL, toolchain on
// Windows) - never touches the running container/registration.
pipeline {
    agent none
    parameters {
        choice(name: 'PLATFORM', choices: ['wsl', 'windows'], description: 'Which agent to update')
    }
    stages {
        stage('Update') {
            agent { label params.PLATFORM }
            steps {
                script {
                    if (params.PLATFORM == 'wsl') {
                        sh 'bash build_env/linux/build_images.sh'
                    } else {
                        bat 'powershell -ExecutionPolicy Bypass -File build_env/windows/bootstrap_toolchain.ps1'
                    }
                }
            }
            post { always { cleanWs() } }
        }
    }
}
