#!/usr/bin/env bash
# 마스터에서 실행: 네임스페이스 → MetalLB → ingress-nginx → Jenkins → PetClinic Ingress 순서로 구성
# PetClinic Deployment/Service(04-was/petclinic-deployment.yaml)는 Jenkins 파이프라인이 배포
set -euo pipefail
cd "$(dirname "$0")"

METALLB_URL=https://raw.githubusercontent.com/metallb/metallb/v0.13.12/config/manifests/metallb-native.yaml
INGRESS_URL=https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.2/deploy/static/provider/cloud/deploy.yaml

# webhook Pod가 막 떠서 아직 응답하지 않을 때 apply가 실패하므로 재시도
retry_apply() { for i in $(seq 1 12); do kubectl apply -f "$1" && return 0; sleep 10; done; return 1; }

echo "== 1) Namespace"
kubectl apply -f 01-namespace/namespaces.yaml

echo "== 2) MetalLB"
kubectl apply -f "$METALLB_URL"
kubectl -n metallb-system rollout status deploy/controller --timeout=300s
kubectl -n metallb-system rollout status ds/speaker --timeout=300s
retry_apply 02-metallb/metallb-config.yaml

echo "== 3) ingress-nginx (LoadBalancer → 192.168.56.200)"
kubectl apply -f "$INGRESS_URL"
kubectl -n ingress-nginx wait --for=condition=complete job --all --timeout=300s
kubectl -n ingress-nginx rollout status deploy/ingress-nginx-controller --timeout=300s

echo "== 4) Jenkins"
kubectl apply -f 03-jenkins/nfs-volume.yaml
kubectl apply -f 03-jenkins/jenkins-rbac.yaml
kubectl apply -f 03-jenkins/jenkins-deployment.yaml
retry_apply 03-jenkins/jenkins-ingress.yaml
kubectl -n jenkins-ns rollout status deploy/jenkins --timeout=600s

# 파이프라인 잡이 없으면 등록 후 Jenkins 재시작 (Jenkins는 시작할 때 jobs/를 읽음)
if ! kubectl -n jenkins-ns exec deploy/jenkins -- test -f /var/jenkins_home/jobs/spring-petclinic/config.xml; then
  kubectl -n jenkins-ns exec -i deploy/jenkins -- sh -c \
    'mkdir -p /var/jenkins_home/jobs/spring-petclinic && cat > /var/jenkins_home/jobs/spring-petclinic/config.xml' \
    < 03-jenkins/spring-petclinic-job.xml
  kubectl -n jenkins-ns rollout restart deploy/jenkins
  kubectl -n jenkins-ns rollout status deploy/jenkins --timeout=600s
fi

echo "== 5) PetClinic Ingress (Deployment/Service는 Jenkins가 배포)"
retry_apply 04-was/petclinic-ingress.yaml

echo "== 확인"
kubectl get svc -n ingress-nginx ingress-nginx-controller
kubectl get ingress -A
