1. s3 bucket을 init으로 만든 다음에 terraform.tfvars에 s3 버킷 id를 넣어야함
2. 현재 jwt token값을 사용하는 곳이 총 3곳이 존재함 현재는 등록해야지 돌아갑니다.

side-project/bank-of-anthos/jwt-v2	로그인 토큰 서명/검증용 RSA 키	성공  # bank of anthos에서 기본적으로 필요로 하는 값
side-project/krr-telegram	KRR 리소스 분석 결과를 텔레그램으로 보낼 봇 토큰  # '' 필요로는 하지 않지만 사용되어서 현재는 필요로 한 값
side-project/bank-loadgen-credentials	부하 테스트(k6) 자동 로그인용 계정/비번	# '' 필요하지는 않지만 사용되어서 현재는 필요로 한 값

openssl genrsa -out jwtRS256.key 2048
openssl rsa -in jwtRS256.key -pubout -out jwtRS256.key.pub

aws secretsmanager create-secret \
  --name side-project/bank-of-anthos/jwt-v2 \
  --secret-string "$(jq -n \
      --rawfile priv jwtRS256.key \
      --rawfile pub jwtRS256.key.pub \
      '{"jwtRS256.key": $priv, "jwtRS256.key.pub": $pub}')" \
  --region ap-northeast-2 \
  --profile 계정명

aws secretsmanager put-secret-value \
  --secret-id side-project/krr-telegram \
  --secret-string '{"TELEGRAM_BOT_TOKEN":"dummy","TELEGRAM_CHAT_ID":"dummy"}' \
  --region ap-northeast-2 \
  --profile 계정명

aws secretsmanager put-secret-value \
  --secret-id side-project/bank-loadgen-credentials \
  --secret-string '{"username":"testuser","password":"testpassword"}' \
  --region ap-northeast-2 \
  --profile 계정명