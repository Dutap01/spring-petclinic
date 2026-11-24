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
                dir("${env.WORKSPACE}") {
                    sh 'zip -r deploy.zip ./scripts appspec.yml'
                    withAWS(region: "ap-northeast-2", credentials: "${AWS_CREDENTIAL_NAME}") {
                        s3Upload(file: "deploy.zip", bucket: "aws10-s3-bucket")
                    }
                }
            }
            post {
                always {
                    sh 'rm -rf deploy.zip'
                }
            }
        }

        stage('Code Deploy Workload') {
            steps {
                echo 'Code Deploy Workload'
                withAWS(region: "ap-northeast-2", credentials: "${AWS_CREDENTIAL_NAME}") {
                    sh '''
                    aws deploy create-deployment-group \
                    --application-name aws10-spring-petclinic \
                    --auto-scaling-group aws10-asg \
                    --deployment-group-name aws10-code-deploy-${BUILD_NUMBER} \
                    --deployment-config-name CodeDeployDefault.OneAtATime \
                    --service-role-arn arn:aws:iam::491085389788:role/aws10-code-deploy-service-role
                    '''

                    sh '''
                    aws deploy create-deployment \
                    --application-name aws10-spring-petclinic \
                    --deployment-config-name CodeDeployDefault.OneAtATime \
                    --deployment-group-name aws10-code-deploy-${BUILD_NUMBER} \
                    --s3-location bucket=aws10-s3-bucket,bundleType=zip,key=deploy.zip
                    '''
                }
            }
        }
    }
}
