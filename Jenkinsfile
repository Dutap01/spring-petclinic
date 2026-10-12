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
                git branch: 'main', url: 'https://github.com/Dutap01/spring-petclinic.git'
            }
        }

        stage('Maven Build') {
            steps {
                echo 'Maven Build'
                sh 'mvn -Dmaven.test.failure.ignore=true clean package'
            }
        }
        // Docker Image 생성
        stage('Docker Image Create'){
            steps{
                
                echo 'Docker Image Create'
                sh '''
                    docker build -t spring-petclinic:$(BUILD_NUMBER) .
                    docker tag spring-petclinic:$(BUILD_NUMBER) Dutap01/spring-petclinic:latest
                '''
            }
        }
        // Dockerhub Image Push
        stage('Dokcer Image push'){
            steps{
                echo 'Docker Image push'
                // Docker Login
                sh 'echo $(DOCKERHUM_CRED_PSW) | docker login -u $(DOCKERHUB_CRED_USR) --password-stdin

                // Docker Hub Push
                sh 'docker image push Dutap01/spring-petclinic:latest'
            }
            post{
                always{
                    sh '''
                        docker rmi -f spring-petclinic:$(BUILD_NUMBER)
                        docker rmi -f Dutap01/spring-petclinic:latest
                    '''
                }
            }
        }
        // Docker Image 삭제
        
        // SSH를 이용한 실행파일 전송
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
                                        docker rm -f $docker ps -aq)
                                        docker rmi -f $(docker images -q)
                                        docker run -itd -p 80:8080 --name=spring-petclinic Dutap01/spring-petclinic:latest
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
