# Jenkins + Docker CLI + kubectl 이미지 (dutap/jenkins-docker:2.580.1)
# 빌드: docker build -t dutap/jenkins-docker:2.580.1 k8s/03-jenkins && docker push dutap/jenkins-docker:2.580.1
FROM jenkins/jenkins:2.580.1-lts-jdk21

USER root

# Docker CLI 설치를 위한 패키지 및 저장소 설정
RUN apt-get update && \
    apt-get install -y curl apt-transport-https ca-certificates gnupg lsb-release && \
    mkdir -p /etc/apt/keyrings && \
    curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list && \
    apt-get update && \
    apt-get install -y docker-ce-cli

# kubectl 설치 (클러스터 버전 v1.28에 맞춤) - Jenkinsfile Deploy stage에서 사용
RUN curl -fsSL -o /usr/local/bin/kubectl https://dl.k8s.io/release/v1.28.15/bin/linux/amd64/kubectl && \
    chmod +x /usr/local/bin/kubectl

USER jenkins
