pipeline {
    agent any

    tools {
        jdk 'JDK21'
        maven 'M3'
    }

    environment {
        DOCKERHUB_CRED = credentials('dockerCredentials')
        AWS_CREDENTIAL_NAME = 'awsCredentials'

        DOCKER_IMAGE_NAME = "spring-petclinic"
        DOCKER_IMAGE_VERSION = "latest"
    }

    stages {
        stage('Git Clone') {
            steps {
                echo 'Git Clone'
                git url: 'git@github.com:Dutap01/spring-petclinic.git',
                    branch: 'main',
                    credentialsId: 'gitCredentials'
            }
        }

        stage('Maven Build') {
            steps {
                echo 'Maven Build'
                sh 'mvn clean package -DskipTests'
            }
        }

        stage('Docker Build && Push') {
            steps {
                echo 'Docker Build && Push'
                sh '''
                    docker build -t ${DOCKER_IMAGE_NAME}:${BUILD_NUMBER} .
                    docker tag ${DOCKER_IMAGE_NAME}:${BUILD_NUMBER} dutap/${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_VERSION}
                    echo ${DOCKERHUB_CRED_PSW} | docker login -u ${DOCKERHUB_CRED_USR} --password-stdin
                    docker push dutap/${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_VERSION}
                '''
            }
            post {
                always {
                    sh '''
                        docker rmi -f ${DOCKER_IMAGE_NAME}:${BUILD_NUMBER}
                        docker rmi -f dutap/${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_VERSION}
                    '''
                }
            }
        }

        stage('Upload S3') {
            steps {
                echo 'Upload S3'
                dir("${env.WORKSPACE}"){
                    sh 'zip -r deploy.zip ./scripts appspec.yml'
                    withAWS(region:"ap-northeast-2"m credentials: "${AWSCredentials}"){
                        s3Upload(file:"deploy.zip", bucket:"aws10-s3-bucket")
                    }
                }
            }
        }

        stage('Code Deploy Workload') {
            steps {
                echo 'Code Deploy Workload'
            }
        }
    }
}
