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

    - name: maven
      image: maven:3.9-eclipse-temurin-21
      command:
        - cat
      tty: true
      resources:
        requests:
          cpu: 250m
          memory: 512Mi
        limits:
          cpu: "2"
          memory: 1536Mi

    - name: trivy
      image: aquasec/trivy:0.76.1
      command:
        - cat
      tty: true
      resources:
        requests:
          cpu: 250m
          memory: 256Mi
        limits:
          cpu: "1"
          memory: 1Gi
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
                expression { params.TARGET_ENV != 'dev' }
            }
            steps {
                timeout(time: 15, unit: 'MINUTES') {
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

        stage('Checkout Java Application') {
            steps {
                dir('app') {
                    git(
                        branch: 'main',
                        url: 'https://github.com/isaradhi24/orders-service.git'
                    )
                }
            }
        }

        stage('Build and Test Java Application') {
            steps {
                container('maven') {
                    dir('app') {
                        sh  '''
                        java -version
                        chmod +x mvnw
                        ./mvnw -B -ntp clean verify
                        '''
                    }
                }
            }
            post {
                always {
                    junit (
                        testResults: 'app/target/surefire-reports/*.xml',
                        allowEmptyResults: false
                    )
                }
                success {
                    archiveArtifacts(
                        artifacts: 'app/target/orders-service-*.jar',
                        fingerprint: true
                    )
                }
            }
        }

        stage('Dependency and Secret Scan') {
            steps {
                container('trivy') {
                    dir('app') {
                        sh '''
                            trivy --version

                            # Scan dependencies packaged in the application.
                            trivy fs \
                              --scanners vuln \
                              --offline-scan \
                              --severity HIGH,CRITICAL \
                              --exit-code 1 \
                              --timeout 10m \
                              target/

                            # Scan source and configuration for secrets.
                            trivy fs \
                              --scanners secret \
                              --exit-code 1 \
                              --timeout 5m \
                              --skip-dirs .git \
                              --skip-dirs target \
                              .
                        '''
                    }
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