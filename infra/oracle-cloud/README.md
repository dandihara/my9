# Oracle Cloud Always Free 배포

이 구성은 Oracle Cloud Always Free VM에서 API와 data-worker를 Docker Compose로 실행하는 배포안이다.

## 권장 OCI 설정

- Shape: Ampere A1 Flex, 가능하면 4 OCPU / 24 GB RAM
- OS: Ubuntu 22.04 또는 24.04
- Public IPv4: 예약(Reserved) 공인 IP 사용
- OCI VCN Ingress: TCP 22는 관리자 IP만, TCP 80/443은 외부 허용
- 인스턴스 내부 방화벽: TCP 80/443 허용
- TCP 8000, 5432, 6379는 외부에 열지 않음

Ampere A1은 ARM64지만 현재 사용하는 Python, PostgreSQL, Redis, Caddy 기본 이미지는 ARM64를 지원한다. data-worker의 Chromium은 Dockerfile에서 Debian 패키지로 설치한다.

## 최초 설치

```bash
sudo apt-get update
sudo apt-get install -y git docker.io docker-compose-plugin curl
sudo systemctl enable --now docker
sudo usermod -aG docker "$USER"
```

그룹 권한을 적용하려면 SSH를 다시 접속한다.

```bash
git clone <repository-url> my9
cd my9
cp infra/oracle-cloud/oracle.env.example .env
nano .env
```

`.env`에서 반드시 `POSTGRES_PASSWORD`, `DATABASE_URL`, `SYNC_DATABASE_URL`, `SECRET_KEY`를 같은 실제 비밀값으로 바꾼다. `MY9_DOMAIN`에는 HTTPS를 사용할 도메인을 넣는다. DNS의 A 레코드는 OCI 예약 공인 IP를 가리켜야 한다.

도메인 없이 1차 접속 테스트만 할 때는 `MY9_DOMAIN=:80`으로 둔다. 이 경우 HTTP만 사용하므로 운영용 APK에는 도메인 기반 HTTPS 주소를 사용한다.

## 배포 및 갱신

```bash
bash infra/oracle-cloud/deploy-oracle-cloud.sh
```

로그 확인:

```bash
docker compose --env-file .env -f docker-compose.oracle.yml logs -f api-server data-worker caddy
```

코드 갱신 후에도 같은 명령을 다시 실행하면 API 이미지와 worker 이미지가 재빌드되고, API 컨테이너 시작 시 Alembic migration이 자동 적용된다. PostgreSQL과 Redis 데이터는 Docker named volume에 남는다.

## 백업

```bash
mkdir -p infra/backups
docker compose --env-file .env -f docker-compose.oracle.yml exec -T postgres \
  pg_dump -U "$POSTGRES_USER" -d "$POSTGRES_DB" > "infra/backups/seungyo-$(date +%Y%m%d-%H%M%S).sql"
```

백업 파일은 저장소에 커밋하지 않는다. OCI Block Volume 또는 별도 오브젝트 스토리지로 복사하는 것을 권장한다.

## 모바일 앱 연결

앱에는 OCI의 실제 IP를 코드에 직접 넣지 않는다. HTTPS 도메인을 `API_BASE_URL` 또는 빌드용 `.env`에 주입해 external APK를 만든다.

```text
Flutter APK -> https://api.example.com -> Caddy:443 -> api-server:8000
                                      -> PostgreSQL/Redis (Docker 내부망)
data-worker --------------------------^
```

## 문제 확인 순서

1. OCI VCN Security List 또는 NSG에서 80/443이 열렸는지 확인
2. Ubuntu 방화벽에서 `sudo ufw allow 80/tcp` 및 `sudo ufw allow 443/tcp` 확인
3. `docker compose ... ps`에서 postgres healthy, api/caddy running 확인
4. `docker compose ... logs --tail=100 api-server caddy data-worker` 확인
5. API 컨테이너 내부에서 `curl http://127.0.0.1:8000/health` 확인

무료 VM의 용량 부족으로 A1 인스턴스 생성이 실패하면 다른 Availability Domain 또는 AMD 무료 shape로 시도한다. AMD shape에서도 worker Chromium의 동작 방식은 동일하다.
