pipeline {
    agent any

    tools {
        jdk 'JDK21'
        maven 'M3'
    }

    // GitHub Webhook이 내부망(192.168.56.x)에 닿지 않으므로 5분마다 저장소 변경을 확인해 자동 빌드
    triggers {
        pollSCM('H/5 * * * *')
    }

    environment {
        IMAGE      = 'dutap/spring-petclinic'
        K8S_NS     = 'was-ns'
        DEPLOYMENT = 'petclinic-deployment'
        MANIFEST   = 'k8s/04-was/petclinic-deployment.yaml'
    }

    stages {
        stage('Git Clone') {
            steps {
                git branch: 'main', url: 'https://github.com/dutap01/spring-petclinic.git'
            }
        }

        stage('Maven Build') {
            steps {
                // DB 통합테스트(MySQL/Postgres)는 Testcontainers가 노드 Docker에 DB를 띄우는데
                // Jenkins Pod에서는 그 포트에 접근할 수 없어 대기하다 실패하므로 제외
                sh "mvn -Dmaven.test.failure.ignore=true -Dtest='!MySqlIntegrationTests,!PostgresIntegrationTests' -Dsurefire.failIfNoSpecifiedTests=false clean package"
            }
        }

        stage('Docker Image Create') {
            steps {
                sh 'docker build -t ${IMAGE}:${BUILD_NUMBER} .'
            }
        }

        stage('Docker Image Push') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'dockerCredentials',
                                                  usernameVariable: 'DOCKER_USER',
                                                  passwordVariable: 'DOCKER_PASS')]) {
                    sh '''
                        echo "${DOCKER_PASS}" | docker login -u "${DOCKER_USER}" --password-stdin
                        docker push ${IMAGE}:${BUILD_NUMBER}
                    '''
                }
            }
            post {
                always {
                    // 노드 디스크가 차지 않도록 푸시 후 로컬 이미지 정리 (Pod는 Docker Hub에서 pull)
                    sh 'docker rmi -f ${IMAGE}:${BUILD_NUMBER} || true'
                    sh 'docker logout || true'
                }
            }
        }

        stage('Deploy') {
            steps {
                script { env.DEPLOY_STARTED = 'true' }   // 이 단계 이후 실패할 때만 롤백
                // Jenkins Pod의 ServiceAccount(jenkins) 권한으로 실행 - k8s/03-jenkins/jenkins-rbac.yaml
                sh '''
                    sed "s|__TAG__|${BUILD_NUMBER}|g" ${MANIFEST} | kubectl apply -f -
                    kubectl -n ${K8S_NS} rollout status deployment/${DEPLOYMENT} --timeout=300s
                '''
            }
        }
    }

    post {
        success {
            sh 'kubectl -n ${K8S_NS} annotate deployment/${DEPLOYMENT} kubernetes.io/change-cause="jenkins build #${BUILD_NUMBER}" --overwrite'
            sh 'kubectl -n ${K8S_NS} rollout history deployment/${DEPLOYMENT}'
        }
        failure {
            script {
                if (env.DEPLOY_STARTED == 'true') {
                    // 새 버전이 300초 안에 Ready 되지 않으면 직전 버전으로 자동 롤백
                    sh 'kubectl -n ${K8S_NS} rollout undo deployment/${DEPLOYMENT} || true'
                } else {
                    echo 'Deploy 이전 단계에서 실패 - 클러스터 변경 없음, 롤백 생략'
                }
            }
        }
    }
}
