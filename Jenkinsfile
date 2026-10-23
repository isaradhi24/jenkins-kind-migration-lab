pipeline {
    agent {
        kubernetes {
            yaml '''
apiVersion: v1
kind: Pod
spec:
  nodeSelector:
    workload: jenkins

  containers:
    - name: shell
      image: alpine:3.20
      command:
        - cat
      tty: true

      resources:
        requests:
          cpu: 100m
          memory: 128Mi
        limits:
          cpu: 250m
          memory: 256Mi
'''
        }
    }
    parameters {
        choice(
            name: 'TARGET_ENV',
            choices: ['dev', 'qa', 'prod'],
            description: 'Select deployment environment'
        )
    }
    stages {
        stage( 'Showw Environment' ) {
            steps {
                echo "Selected environment: ${params.TARGET_ENV}"
            }
        }

        stage('Deployment Approval') {
            when {
                expression ${ params.TARGET_ENV }
            }
            steps {
                timeout(time: 5, unit: MINUTES) {
                    input (
                        message: "Approve practice deployment to ${params.TARGET_ENV}?",
                        ok: 'Approve',
                        submitter: 'admin'
                        )
                        }
                    }
                }


        stage('Agent Test') {
            steps {
                container('shell') {
                    sh '''
                        echo "Dynamic Jenkins agent is running"
                        echo "Pod hostname: $(hostname)"
                        echo "Current user: $(whoami)"
                        echo "Workspace: $(pwd)"
                        cat /etc/os-release
                    '''
                }
            }
        }

        stage('Groovy Test') {
            steps {
                script {
                    def applications = [
                        'java-service',
                        'python-service',
                        'node-service'
                    ]

                    applications.each { app ->
                        echo "Discovered application: ${app}"
                    }

                    echo "Total applications: ${applications.size()}"
                }
            }
        }
    }

    post {
        success {
            echo 'Kubernetes agent pipeline succeeded'
        }

        failure {
            echo 'Kubernetes agent pipeline failed'
        }
    }
}