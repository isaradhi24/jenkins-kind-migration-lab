pipeline {
    agent {
        kubernetes {
            yaml '''
apiVersion: v1
kind: Pod
spec:

  volumes:
    - name: build-cache
      persistentVolumeClaim:
        claimName: jenkins-build-cache

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

      volumeMounts:
        - name: build-cache
          mountPath: /cache

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
    - name: aws
      image: public.ecr.aws/aws-cli/aws-cli:2.27.41
      command:
        - cat
      tty: true
      resources:
        requests:
          cpu: 100m
          memory: 128Mi
        limits:
          cpu: 500m
          memory: 512Mi

      volumeMounts:
        - name: build-cache
          mountPath: /cache
'''
        }
    }

    options {
        disableConcurrentBuilds()
    }
    parameters {
        choice(
            name: 'TARGET_ENV',
            choices: ['dev', 'qa', 'prod'],
            description: 'Select deployment environment'
        )
    }
    stages {
        stage('Verify AWS Access') {
            steps {
                container('aws') {
                    withCredentials([
                        usernamePassword(
                            credentialsId: 'aws-jenkins-ecr',
                            usernameVariable: 'AWS_ACCESS_KEY_ID',
                            passwordVariable: 'AWS_SECRET_ACCESS_KEY'
                        )
                    ]) {
                        sh '''
                            set +x
                            set -eu
                            export AWS_DEFAULT_REGION=us-east-1
                            export AWS_PAGER=""

                            aws sts get-caller-identity

                            account=$(aws sts get-caller-identity \
                              --query Account --output text)
                            test "$account" = "149703445367"

                            aws ecr describe-images \
                              --repository-name orders-service \
                              --query 'imageDetails[].imageTags' \
                              --output json

                            aws ecr get-login-password > /dev/null

                            echo "AWS identity and ECR access verified"
                        '''
                    }
                }
            }
        }
        stage( 'Show Environment' ) {
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
                        ./mvnw -B -ntp -Dmaven.repo.local=/cache/m2 clean verify
                        test -s target/orders-service-0.0.1-SNAPSHOT.jar
                        ls -lh target/orders-service-0.0.1-SNAPSHOT.jar
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
                            set -eu
                            trivy --version

                            test -s target/orders-service-0.0.1-SNAPSHOT.jar

                            # Scan packaged Java dependencies.
                            trivy rootfs \
                              --cache-dir /cache/trivy \
                              --scanners vuln \
                              --pkg-types library \
                              --offline-scan \
                              --severity HIGH,CRITICAL \
                              --exit-code 1 \
                              --timeout 15m \
                              target/

                            # Scan source/configuration for secrets.
                            trivy fs \
                              --cache-dir /cache/trivy \
                              --scanners secret \
                              --offline-scan \
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
    } // End of Dependency and Secret Scan stage

    post {
        success {
            echo 'Kubernetes agent pipeline succeeded'
        }

        failure {
            echo 'Kubernetes agent pipeline failed'
        }
    }
} // End of pipeline