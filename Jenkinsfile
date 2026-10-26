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
                // DB 통합테스트(MySQL/Postgres)는 Testcontainers로 노드 Docker에 DB를 띄우는데
                // Jenkins Pod에서는 그 포트에 접근할 수 없어 대기하다 실패하므로 제외
                sh "mvn -Dmaven.test.failure.ignore=true -Dtest='!MySqlIntegrationTests,!PostgresIntegrationTests' -Dsurefire.failIfNoSpecifiedTests=false clean package"
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
    }
}
