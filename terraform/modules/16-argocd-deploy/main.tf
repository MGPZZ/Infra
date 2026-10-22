terraform {
  required_providers {
    kubectl = { source = "alekc/kubectl" }
  }
}

# Argo CD 설치 직후 Application CRD가 등록될 시간을 확보하기 위해 30초 대기합니다.
resource "time_sleep" "wait_for_argocd_application_crd" {
  create_duration = "30s"

}

resource "kubectl_manifest" "prometheus_stack" {
  depends_on = [time_sleep.wait_for_argocd_application_crd]
  yaml_body = <<YAML
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: prometheus-stack
  namespace: argocd
  finalizers:
  - resources-finalizer.argocd.argoproj.io
spec:
  project: default
  source:
    repoURL: https://prometheus-community.github.io/helm-charts
    chart: kube-prometheus-stack
    targetRevision: 87.10.1
    helm:
      values: |
        ${indent(8, templatefile("${path.module}/prometheus/my-values.yaml.tpl", {
  grafana_admin_password = var.grafana_admin_password
  enable_krr_demo_seed   = var.enable_krr_demo_seed
  krr_demo_seed_image    = var.krr_demo_seed_image
}))}
  destination:
    server: https://kubernetes.default.svc
    namespace: monitoring
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - CreateNamespace=true
    - ServerSideApply=true
  ignoreDifferences:
  - group: admissionregistration.k8s.io
    kind: ValidatingWebhookConfiguration
    name: prometheus-stack-kube-prom-admission
    jsonPointers:
    - /webhooks/0/clientConfig/caBundle
  - group: admissionregistration.k8s.io
    kind: MutatingWebhookConfiguration
    name: prometheus-stack-kube-prom-admission
    jsonPointers:
    - /webhooks/0/clientConfig/caBundle
YAML
}

resource "kubectl_manifest" "keda" {
  yaml_body = <<YAML
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: keda
  namespace: argocd
  finalizers:
  - resources-finalizer.argocd.argoproj.io
spec:
  project: default
  source:
    repoURL: https://kedacore.github.io/charts
    chart: keda
    targetRevision: 2.20.1
    helm:
      releaseName: keda
      values: |
        nodeSelector:
          role: management
  destination:
    server: https://kubernetes.default.svc
    namespace: keda
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - CreateNamespace=true
    - ServerSideApply=true
YAML
}

# 1. Frontend 애플리케이션 (프론트엔드 관련 리소스 담당 네임스페이스)
resource "kubectl_manifest" "frontend" {
  yaml_body = <<YAML
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: frontend
  namespace: argocd
  finalizers:
  - resources-finalizer.argocd.argoproj.io
spec:
  project: default
  source:
    repoURL: https://github.com/MGPZZ/GitOps.git
    targetRevision: test_alb
    path: charts/app
    helm:
      values: |
        # 프론트엔드 전용 values 설정 (필요시)
        components:
          backend: false
          frontend: true
        secrets:
          existingSecret: ${var.bank_jwt_secret_name}
        redis:
          host: ${var.redis_host}
          port: ${var.redis_port}
  destination:
    server: https://kubernetes.default.svc
    namespace: frontend
  ignoreDifferences:
    - group: gateway.networking.k8s.io
      kind: HTTPRoute
      jsonPointers:
        - /spec/rules/0/backendRefs/0/weight
        - /spec/rules/0/backendRefs/1/weight
    - group: argoproj.io
      kind: Rollout
      name: frontend-rollout
      jsonPointers:
        - /spec/replicas
        - /spec/strategy/canary/activeService
        - /spec/strategy/canary/previewService
        - /spec/strategy/canary/trafficRouting
    - group: gateway.k8s.aws
      kind: TargetGroupConfiguration
      jqPathExpressions:
        - .spec.defaultConfiguration.healthCheck
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - CreateNamespace=true
    - RespectIgnoreDifferences=true
YAML
}

# 2. Backend 애플리케이션 (마이크로서비스 및 DB 연동 서비스 담당)
resource "kubectl_manifest" "backend" {
  yaml_body = <<YAML
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: backend
  namespace: argocd
  finalizers:
  - resources-finalizer.argocd.argoproj.io
spec:
  project: default
  source:
    repoURL: https://github.com/MGPZZ/GitOps.git
    targetRevision: test_alb
    path: charts/app
    helm:
      values: |
        components:
          backend: true
          frontend: false
        secrets:
          existingSecret: ${var.bank_jwt_secret_name}
        redis:
          host: ${var.redis_host}
          port: ${var.redis_port}
  destination:
    server: https://kubernetes.default.svc
    namespace: backend
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - CreateNamespace=true
YAML
}


resource "kubectl_manifest" "grafana_finops_dashboard" {
  yaml_body = <<YAML
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: grafana-finops-dashboard
  namespace: argocd
  finalizers:
  - resources-finalizer.argocd.argoproj.io
spec:
  project: default
  source:
    repoURL: https://github.com/MGPZZ/GitOps.git
    targetRevision: test_alb
    path: charts/grafana-finops-dashboard
    helm:
      valueFiles:
      - values.yaml
  destination:
    server: https://kubernetes.default.svc
    namespace: monitoring
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - CreateNamespace=true
YAML
}

resource "kubectl_manifest" "finops_analyzer" {
  yaml_body = <<YAML
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: finops-analyzer
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/MGPZZ/GitOps.git
    targetRevision: test_alb
    path: charts/finops
    helm:
      values: |
        image:
          repository: ${var.krr_analyzer_image_repository}
  destination:
    server: https://kubernetes.default.svc
    namespace: finops
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - CreateNamespace=true
YAML
}

resource "kubectl_manifest" "argocd_config" {
  yaml_body = <<YAML
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: argocd-config
  namespace: argocd
  finalizers:
  - resources-finalizer.argocd.argoproj.io
spec:
  project: default
  source:
    repoURL: https://github.com/MGPZZ/GitOps.git
    targetRevision: test_alb
    path: charts/argocd-config
  destination:
    server: https://kubernetes.default.svc
    namespace: argocd
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - CreateNamespace=true
YAML
}

# ----------------------------------------------------------------
# CNPG(CloudNativePG) Database 클러스터 배포 (GitOps 연동)
# - GitOps 저장소의 cnpg-db 폴더(차트)를 읽어와서
#   EKS 내부에 DB 인스턴스와 백업 설정을 자동으로 띄웁니다.
# ----------------------------------------------------------------
resource "kubectl_manifest" "cnpg_db" {
  yaml_body = <<YAML
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: cnpg-db
  namespace: argocd
  finalizers:
  - resources-finalizer.argocd.argoproj.io
spec:
  project: default
  source:
    repoURL: https://github.com/MGPZZ/GitOps.git
    targetRevision: test_alb
    path: charts/cnpg-db
  destination:
    server: https://kubernetes.default.svc
    namespace: backend
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - CreateNamespace=true
YAML
}

# ----------------------------------------------------------------
# FinOps KRR Logs 전용 CNPG Database 클러스터 배포 (GitOps 연동)
# ----------------------------------------------------------------
resource "kubectl_manifest" "krr_data_db" {
  yaml_body = <<YAML
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: krr-data-db
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/MGPZZ/GitOps.git
    targetRevision: test_alb
    path: charts/krr-data-db
  destination:
    server: https://kubernetes.default.svc
    namespace: finops
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - CreateNamespace=true
YAML
}

# ----------------------------------------------------------------
# Reflector: krr-data-db-app Secret(finops 네임스페이스)을 Grafana가 있는
# prometheus 네임스페이스로 복제하기 위한 컨트롤러. CNPG가 비밀번호를 재발급해도
# 자동으로 따라가도록, Terraform이 값을 한 번 읽어 복사하는 대신 클러스터 안에서
# 지속적으로 동기화되는 방식을 씁니다.
# ----------------------------------------------------------------
resource "kubectl_manifest" "reflector" {
  yaml_body = <<YAML
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: reflector
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://emberstack.github.io/helm-charts
    chart: reflector
    targetRevision: "10.0.65"
    helm:
      values: |
        nodeSelector:
          role: management
  destination:
    server: https://kubernetes.default.svc
    namespace: kube-system
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - CreateNamespace=true
YAML
}

# Reflector annotations are inherited from the CNPG Cluster spec.inheritedMetadata.

resource "kubectl_manifest" "karpenter_resources" {
  yaml_body = <<YAML
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: karpenter
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/MGPZZ/GitOps.git
    targetRevision: test_alb
    path: charts/karpenter
  destination:
    server: https://kubernetes.default.svc
    namespace: kube-system
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - ServerSideApply=true
YAML
}

resource "kubectl_manifest" "tg_gateway" {
  yaml_body = <<YAML
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: tg-gateway
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/MGPZZ/GitOps.git
    targetRevision: test_alb
    path: charts/tg-gateway
  destination:
    server: https://kubernetes.default.svc
    namespace: monitoring
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - CreateNamespace=true
YAML
}

resource "kubectl_manifest" "thanos" {
  yaml_body = <<YAML
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: thanos
  namespace: argocd
  finalizers:
  - resources-finalizer.argocd.argoproj.io
spec:
  project: default
  source:
    repoURL: https://charts.bitnami.com/bitnami
    chart: thanos
    targetRevision: 15.7.0
    helm:
      values: |
        image:
          registry: quay.io
          repository: thanos/thanos
          tag: v0.35.1
        query:
          enabled: true
          replicaCount: 1
          nodeSelector:
            role: management
          # Thanos Query 메모리 증설 (2Gi)
          resources:
            requests:
              cpu: 200m
              memory: 512Mi
            limits:
              cpu: 1000m
              memory: 2Gi
          # Prometheus Sidecar와 Thanos Store를 연결
          stores:
            - "prometheus-operated.monitoring.svc.cluster.local:10901"
            - "thanos-storegateway.monitoring.svc.cluster.local:10901"
          serviceAccount:
            create: true
            name: thanos-query
            annotations:
              eks.amazonaws.com/role-arn: "arn:aws:iam::372666940978:role/side-project-thanos-s3-role"
        storegateway:
          enabled: true
          replicaCount: 1
          nodeSelector:
            role: management
          # StoreGateway 메모리 증설 (2Gi) 
          resources:
            requests:
              cpu: 500m
              memory: 1Gi
            limits:
              cpu: 1000m
              memory: 2Gi
          # -----------------------------------------------------
          persistence:
            storageClass: "ebs-gp3"
          serviceAccount:
            create: true
            name: thanos-store
            # 파드에 IRSA IAM 토큰을 자동으로 마운트하도록 설정
            automountServiceAccountToken: true
            annotations:
              eks.amazonaws.com/role-arn: "arn:aws:iam::372666940978:role/side-project-thanos-s3-role"
        objstoreConfig: |-
          type: s3
          config:
            bucket: side-project-thanos-metrics-83154bf5
            endpoint: s3.ap-northeast-2.amazonaws.com
            region: ap-northeast-2
        compactor:
          # enabled: false
          enabled: true
          nodeSelector:
            role: management
          retentionResolutionRaw: 30d   # 원본(상세) 데이터 30일 보존 후 삭제
          retentionResolution5m: 30d    # 5분 축소 데이터 30일 보존
          retentionResolution1h: 30d   # 1시간 축소 데이터 30일 보존
          persistence:
            enabled: true
            storageClass: "ebs-gp3"
            size: 10Gi                  # 작업용 로컬 EBS 볼륨 생성
          # Compactor가 S3 접근 시 사용할 ServiceAccount 및 IRSA 권한 추가
          serviceAccount:
            create: true
            name: thanos-compactor
            annotations:
              eks.amazonaws.com/role-arn: "arn:aws:iam::372666940978:role/side-project-thanos-s3-role"
        bucketweb:
          enabled: false
        receive:
          enabled: false
  destination:
    server: https://kubernetes.default.svc
    namespace: monitoring
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - CreateNamespace=true
YAML
}
