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

    stages {
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