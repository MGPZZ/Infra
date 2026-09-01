# 📝 팀원 온보딩 및 변수 설정 가이드

이 문서는 팀원들이 본인의 AWS 계정에서 이 인프라 프로젝트를 안전하게 배포하고 실행하기 위한 가이드입니다. 
인프라(Infra)와 쿠버네티스(K8s) 스테이트가 어떻게 분리되어 안전하게 관리되는지도 설명합니다.

---

## 1. 초기 환경 변수 설정 (`terraform.tfvars`)

각 팀원은 자신의 로컬 환경이나 계정 정보에 맞게 `terraform.tfvars` 파일을 생성해야 합니다. 
절대 **하드코딩된 개인 정보를 Git에 바로 푸시하지 마세요!**

### ✅ 설정 방법
`infra/terraform/envs/dev/infra` 및 `infra/terraform/envs/dev/k8s` 폴더 내에 있는 `terraform.tfvars.example`을 참고하여 `terraform.tfvars` 파일을 생성하세요.

```hcl
# 예시: terraform.tfvars
aws_profile = "본인의_AWS_CLI_프로필명"
acm_certificate_arn = "arn:aws:acm:ap-northeast-2:본인계정ID:certificate/발급받은인증서ID"
```
*(참고: `terraform.tfvars`는 `.gitignore`에 등록되어 있어 Git에 푸시되지 않습니다.)*

---

## 2. 스테이트 파일(S3 Backend) 설정 가이드

Terraform이 인프라 상태를 저장하는 곳을 **Backend(백엔드)**라고 부릅니다. 
우리는 팀원 각자의 계정 충돌을 막기 위해 고정된 S3 버킷 이름 대신 **동적 버킷 이름**을 사용합니다.

### ✅ 설정 방법
1. **버킷 프로비저닝**: `infra/setup.sh` 스크립트를 실행하세요. 현재 로그인된 AWS 계정 ID를 기반으로 고유한 S3 버킷과 DynamoDB 테이블이 생성됩니다.
2. **backend.hcl 생성**: 스크립트가 성공적으로 끝나면 `backend.hcl` 파일이 생성됩니다.
3. **Terraform 초기화**: 
   Terraform 명령어를 실행할 때마다 반드시 이 `backend.hcl`을 주입해야 합니다.
   ```bash
   terraform init -backend-config=backend.hcl
   ```

---

## 3. 🧠 (참고) 아키텍처: 스테이트 파일은 어떻게 분리되어 있나요?

우리 프로젝트는 **Infra** 리소스와 **Kubernetes(K8s)** 리소스를 분리하여 관리합니다.
현재 이 레포지토리의 구조는 이 분리를 가장 잘 반영한 **디렉토리 기반 스테이트 분리(Directory-based State Separation)** 구조입니다.

- 🏗️ **Infra State (`envs/dev/infra`)**
  - **포함 내용**: VPC, Subnets, EKS Cluster, Node Groups, IAM Role 등
  - **S3 Key**: `dev-infra/terraform.tfstate`
- ☸️ **K8s State (`envs/dev/k8s`)**
  - **포함 내용**: ArgoCD, Gateway API, Karpenter Helm, 각종 Kubernetes Secret 등
  - **S3 Key**: `dev-k8s/terraform.tfstate`

**분리함으로써 얻는 이점:**
1. **안전성 (Blast Radius 최소화)**: K8s 리소스를 변경하다 실수해도 EKS 클러스터나 VPC가 통째로 삭제되는 대참사를 막을 수 있습니다.
2. **속도 (Plan/Apply 속도 향상)**: K8s 서비스 하나를 추가할 때 전체 인프라(VPC 50개 리소스 등)를 조회하지 않아 속도가 매우 빠릅니다.
3. **Lock 충돌 방지**: 인프라 담당자와 앱(배포) 담당자가 동시에 작업하더라도 서로 다른 `tfstate` 파일을 수정하므로 충돌이 발생하지 않습니다.
