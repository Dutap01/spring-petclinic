# k8s - Spring PetClinic CI/CD 쿠버네티스 구성

Jenkins가 이 저장소(main)를 5분마다 확인해 빌드 → Docker Hub 푸시 → `was-ns` 배포까지 자동으로 진행한다.

- 클러스터: k8s-master, k8s-node01, k8s-node02 (3노드)
- 접속: `www.tap.com/clinic` (PetClinic), `www.tap.com/jenkins` (Jenkins)
- Ingress IP: 192.168.56.200 (MetalLB), DNS/NFS 서버: 192.168.56.107

## 디렉토리 구조

```
Jenkinsfile                         # CI/CD 파이프라인 (저장소 루트)
k8s/
├── README.md                       # 이 문서
├── install.sh                      # 01 → 04 순서로 클러스터 구성 (마스터에서 1회 실행)
├── 01-namespace/
│   └── namespaces.yaml             # jenkins-ns (Jenkins), was-ns (PetClinic)
├── 02-metallb/
│   └── metallb-config.yaml         # LoadBalancer IP 대역 192.168.56.200~210
├── 03-jenkins/
│   ├── Dockerfile                  # Jenkins + Docker CLI + kubectl 이미지 (dutap/jenkins-docker)
│   ├── nfs-volume.yaml             # jenkins_home용 NFS PV/PVC (Retain - 자격증명/플러그인 보존)
│   ├── jenkins-rbac.yaml           # Jenkins ServiceAccount에 was-ns 배포/롤백 권한 부여
│   ├── jenkins-deployment.yaml     # Jenkins Deployment + NodePort(30000) Service
│   ├── jenkins-ingress.yaml        # /jenkins 경로 Ingress
│   └── spring-petclinic-job.xml    # Jenkins 'spring-petclinic' Pipeline 잡 정의 (install.sh가 등록)
├── 04-was/
│   ├── petclinic-deployment.yaml   # PetClinic Deployment(3개, __TAG__) + ClusterIP Service
│   └── petclinic-ingress.yaml      # /clinic 경로 Ingress
├── db.yml, petclinic.yml           # upstream spring-petclinic 예제 (이 구성에서는 사용 안 함)
```

## 파이프라인 (Jenkinsfile)

| Stage | 내용 |
|---|---|
| Git Clone | main 브랜치 체크아웃 |
| Maven Build | Testcontainers DB 통합테스트(MySQL/Postgres) 제외하고 `clean package` |
| Docker Image Create | `dutap/spring-petclinic:<빌드번호>` 빌드 |
| Docker Image Push | `dockerCredentials`로 Docker Hub 푸시, 로컬 이미지 정리 |
| Deploy | `petclinic-deployment.yaml`의 `__TAG__`를 빌드 번호로 `sed` 치환 → `kubectl apply` → `rollout status` 300초 대기 |

- 성공: `kubernetes.io/change-cause`를 `jenkins build #<번호>`로 기록 (`kubectl -n was-ns rollout history deploy/petclinic-deployment`)
- 실패: Deploy 단계까지 진행했으면 `kubectl rollout undo`로 직전 버전 자동 롤백 (그 전 단계 실패는 클러스터 변경이 없어 롤백 생략)
- readinessProbe(`/clinic/actuator/health/readiness`)가 통과해야 Ready → 배포 중 무중단, 기동 실패 시 롤백

## 주의

- spring-petclinic의 nohttp checkstyle 때문에 저장소 안 파일(주석 포함)에 https가 아닌 http 스킴의 URL을 쓰면 Maven Build가 실패한다. (https만 허용)
- PetClinic Ingress는 Jenkins 권한 밖이라 `install.sh`에서 한 번만 적용한다.
