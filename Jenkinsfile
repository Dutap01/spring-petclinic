pipeline {
    agent any

    tools {
        jdk 'JDK21'
        maven 'M3'
    }

    environment {
        DOCKERHUB_CRED = credentials('dockerCredentials')
    }

    stages {
        stage('Git Clone') {
            steps {
                git branch: 'main', url: 'https://github.com/dutap01/spring-petclinic.git'
            }
        }

        stage('Maven Build') {
            steps {
                echo 'Maven Build'
                sh 'mvn -Dmaven.test.failure.ignore=true clean package'
            }
        }

        stage('Docker Image Create') {
            steps {
                echo 'Docker Image Create'
                sh '''
                    docker build -t spring-petclinic:${BUILD_NUMBER} .
                    docker tag spring-petclinic:${BUILD_NUMBER} dutap/spring-petclinic:latest
                '''
            }
        }

        stage('Docker Image Push') {
            steps {
                echo 'Docker Image Push'
                sh 'echo ${DOCKERHUB_CRED_PSW} | docker login -u ${DOCKERHUB_CRED_USR} --password-stdin'
                sh 'docker image push dutap/spring-petclinic:latest'
            }

            post {
                always {
                    sh '''
                        docker rmi -f spring-petclinic:${BUILD_NUMBER} || true
                        docker rmi -f dutap/spring-petclinic:latest || true
                    '''
                }
            }
        }

        stage('SSH Publish') {
            steps {
                echo 'SSH Publish'
                sshPublisher(
                    publishers: [
                        sshPublisherDesc(
                            configName: 'target',
                            transfers: [
                                sshTransfer(
                                    cleanRemote: false,
                                    excludes: '',
                                    execCommand: '''
                                        docker rm -f $(docker ps -aq) || true
                                        docker rmi -f $(docker images -q) || true
                                        docker run -itd -p 80:8080 --name=spring-petclinic dutap/spring-petclinic:latest
                                    ''',
                                    execTimeout: 120000,
                                    flatten: false,
                                    makeEmptyDirs: false,
                                    noDefaultExcludes: false,
                                    patternSeparator: '[, ]+',
                                    remoteDirectory: '',
                                    remoteDirectorySDF: false,
                                    removePrefix: 'target',
                                    sourceFiles: 'target/*.jar'
                                )
                            ],
                            usePromotionTimestamp: false,
                            useWorkspaceInPromotion: false,
                            verbose: false
                        )
                    ]
                )
            }
        }
    }
}
