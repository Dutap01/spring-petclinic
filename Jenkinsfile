pipeline {
    agent any

    tools {
        jdk 'JDK21'
        maven 'M3'
    }

    // GitHub Webhook이 내부망(192.168.56.x)에 닿지 않으므로 5분마다 저장소 변경을 확인해 자동 빌드
    // (Jenkinsfile의 triggers는 이 파일로 빌드가 한 번 실행된 뒤부터 잡에 등록됨)
    triggers {
        pollSCM('H/5 * * * *')
    }

    environment {
        DOCKERHUB_CRED = credentials('dockerCredentials')
        IMAGE = 'dutap/spring-petclinic'
        // latest 대신 빌드 번호 태그로 배포해야 이미지가 바뀌어 롤링 업데이트가 일어나고, rollout undo로 롤백할 수 있음
        TAG = "${BUILD_NUMBER}"
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
                sh 'docker build -t ${IMAGE}:${TAG} .'
            }
        }

        stage('Docker Image Push') {
            steps {
                echo 'Docker Image Push'
                sh 'echo ${DOCKERHUB_CRED_PSW} | docker login -u ${DOCKERHUB_CRED_USR} --password-stdin'
                sh 'docker image push ${IMAGE}:${TAG}'
            }

            post {
                always {
                    sh 'docker rmi -f ${IMAGE}:${TAG} || true'
                }
            }
        }

        stage('Deploy') {
            steps {
                echo 'Deploy to Kubernetes (was-ns)'
                // Jenkins Pod의 ServiceAccount(jenkins) 권한으로 실행 - jenkins-rbac.yaml 참고
                // 저장소의 k8s/petclinic-deployment.yaml에서 __TAG__를 빌드 번호로 바꿔 apply (없으면 생성, 있으면 갱신)
                sh '''
                    sed "s|__TAG__|${TAG}|g" k8s/petclinic-deployment.yaml | kubectl apply -f -
                    kubectl -n was-ns rollout status deployment/petclinic-deployment --timeout=300s
                '''
            }

            post {
                failure {
                    // 새 버전이 Ready 되지 않으면 직전 버전으로 자동 롤백
                    sh 'kubectl -n was-ns rollout undo deployment/petclinic-deployment || true'
                }
            }
        }
    }
}
