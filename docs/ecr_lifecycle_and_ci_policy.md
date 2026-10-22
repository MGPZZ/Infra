# 📦 ECR 리포지토리 및 수명 주기(Lifecycle) 정책 명세서

이 문서는 프로젝트의 컨테이너 이미지 저장소(Amazon ECR) 표준 네이밍, 이미지 태깅(Tagging) 규약, 그리고 스토리지 비용 최적화 및 안정적 배포를 위한 ECR 수명 주기(Lifecycle) 정책을 정의합니다.

---

## 1. ECR 리포지토리 표준 네이밍

모든 마이크로서비스 및 핵심 워크로드는 서비스별로 독립된 1:1 전용 ECR 리포지토리를 사용합니다.

| 서비스 구분 | 리포지토리 이름 (`repository_name`) | 용도 및 설명 |
| :--- | :--- | :--- |
| **Frontend** | `frontend` | Bank of Anthos 프론트엔드 웹 애플리케이션 |
| **UserService** | `userservice` | 회원 정보 및 인증 처리 서비스 |
| **Contacts** | `contacts` | 연락처 및 수취인 관리 서비스 |
| **BalanceReader** | `balancereader` | 계좌 잔액 조회 서비스 |
| **LedgerWriter** | `ledgerwriter` | 계좌 원장 입출금 기록 서비스 |
| **TransactionHistory** | `transactionhistory` | 거래 내역 조회 서비스 |

| **Notification Gateway** | `notification-gateway` | 텔레그램/슬랙/디스코드 등 범용 메신저 알림 중계 서비스 |
| **TG Gateway** | `tg-gateway` | 텔레그램/슬랙/디스코드 등 범용 메신저 알림 중계 서비스 |

> **URI 형식**: `<AWS_ACCOUNT_ID>.dkr.ecr.ap-northeast-2.amazonaws.com/<리포지토리이름>:<태그>`

---

## 2. 이미지 태깅(Tagging) 규약

CI/CD 파이프라인에서 이미지를 빌드하고 ECR로 푸시할 때, 배포 성격에 따라 아래 태그 접두사(Prefix) 규칙을 준수해야 합니다.

```
[태그 구분]
├── 정식 릴리스 버전 (Release)     : v로 시작 (예: v1.0.0, v2.1.3) ➡️ 영구 보존
├── 개발/CI 빌드 버전 (Dev/CI)     : 접두사 사용 (예: dev-1, sha-a1b2c3d) ➡️ 최신 10개만 유지
└── 태그 없음 (Untagged)           : 덮어쓰기로 태그가 유실된 찌꺼기 ➡️ 1일 후 자동 삭제
```

### ① 정식 배포 버전 (Production Release)
* **태그 형식**: `v`로 시작하는 시맨틱 버저닝 (Semantic Versioning)
  - 예: `v1.0.0`, `v1.2.3`, `v2.0.0`
* **보관 정책**: **영구 보존 (Permanent Retention)**
* **용도**: 프로덕션/스테이징 배포에 사용되는 검증된 안정 버전. 롤백 대비를 위해 자동 삭제 규칙이 일체 적용되지 않습니다.

### ② 개발 / CI 테스트 버전 (Development & CI Build)
* **태그 형식**: 아래 접두사(Prefix) 중 하나를 사용
  - `dev-<빌드번호>` (예: `dev-42`)
  - `sha-<커밋해시>` (예: `sha-7f8a9b1`)
  - `ci-<PR번호>` (예: `ci-pr12`)
  - `test-<날짜>` (예: `test-20261016`)
* **보관 정책**: **최신 10개만 유지 (Keep Last 10)**
* **용도**: PR 검증 및 개발 환경 테스트용 빌드. 11번째 빌드가 들어오면 가장 오래된 이미지가 자동으로 삭제됩니다.

---

## 3. ECR 수명 주기(Lifecycle) 정책 상세

각 ECR 리포지토리에는 다음 수명 주기 규칙이 우선순위 순서대로 자동 적용되어 있습니다:

```json
{
  "rules": [
    {
      "rulePriority": 1,
      "description": "Delete untagged dangling images after 1 day",
      "selection": {
        "tagStatus": "untagged",
        "countType": "sinceImagePushed",
        "countUnit": "days",
        "countNumber": 1
      },
      "action": {
        "type": "expire"
      }
    },
    {
      "rulePriority": 2,
      "description": "Keep only last 10 development/CI images",
      "selection": {
        "tagStatus": "tagged",
        "tagPrefixList": ["dev-", "sha-", "ci-", "test-", "pr-"],
        "countType": "imageCountMoreThan",
        "countNumber": 10
      },
      "action": {
        "type": "expire"
      }
    }
  ]
}
```

* **우선순위 1 (`untagged`)**: 새 이미지 푸시로 인해 기존 태그를 잃어버린 찌꺼기(Dangling) 이미지는 **1일 뒤 즉시 만료(삭제)**됩니다.
* **우선순위 2 (`dev-`, `sha-`, ...)**: 개발용 태그가 붙은 이미지는 **최신 10개만 보관**하고 초과분은 자동으로 만료됩니다.
* **정식 릴리스 (`v*`)**: 위 1, 2순위 규칙 어디에도 매칭되지 않으므로 AWS ECR 정책상 **절대 삭제되지 않고 영구 보존**됩니다.

---

## 4. CI/CD 빌드 및 푸시 예시

### GitHub Actions 워크플로우 예시
```yaml
name: Build and Push to ECR

on:
  push:
    tags:
      - 'v*'       # 정식 릴리스: v로 시작하는 태그 푸시 시
    branches:
      - develop    # 개발 빌드: develop 브랜치 푸시 시

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Set Image Tag
        id: vars
        run: |
          if [[ "${{ github.ref }}" == refs/tags/v* ]]; then
            # 정식 릴리스 버전: v1.0.0
            echo "IMAGE_TAG=${GITHUB_REF#refs/tags/}" >> $GITHUB_OUTPUT
          else
            # 개발용 CI 빌드: sha-단축해시
            echo "IMAGE_TAG=sha-${GITHUB_SHA::7}" >> $GITHUB_OUTPUT
          fi

      - name: Build & Push
        run: |
          IMAGE_URI="${{ steps.login-ecr.outputs.registry }}/userservice_ecr:${{ steps.vars.outputs.IMAGE_TAG }}"
          docker build -t "$IMAGE_URI" .
          docker push "$IMAGE_URI"
```
