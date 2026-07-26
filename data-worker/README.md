# KBO data worker

KBO 공식 일정 페이지를 설치된 Google Chrome으로 열어 일정과 경기 결과를 PostgreSQL에 적재합니다. Chrome은 headless 모드를 사용하지 않으므로 수집 중 실제 창이 표시됩니다.

## 한 번 실행

```powershell
cd C:\Users\dandi\Desktop\seungyo-app-starter\data-worker
.\.venv\Scripts\Activate.ps1
python -m worker.scrape_schedule --from-date 2026-07-01 --to-date 2026-07-31
```

DB에 쓰지 않고 파싱 결과만 확인하려면 `--dry-run`을 추가합니다.

```powershell
python -m worker.scrape_schedule --from-date 2026-07-01 --dry-run
```

수집이 끝난 뒤에도 Chrome을 열어두려면 `--keep-browser-open`을 추가합니다. 기본 동작은 작업 종료 후 Chrome을 닫는 것입니다.

## 상시 실행

```powershell
python -m worker.main
```

상시 실행 모드는 오늘 일정과 결과를 1분마다 갱신합니다. 같은 KBO 경기 ID는 새 행을 만들지 않고 기존 행을 업데이트합니다.

## 타자·투수 기록

```powershell
python -m worker.scrape_boxscores --from-date 2026-03-28 --to-date 2026-12-31
```

기본적으로 이미 타자 기록이 있는 경기는 건너뛰므로 중단 후 같은 명령으로 재개할 수 있습니다. 다시 수집하려면 `--force`를 추가합니다.

## DB 준비

API 모델의 초기 마이그레이션은 다음 명령으로 적용합니다.

```powershell
cd C:\Users\dandi\Desktop\seungyo-app-starter\api-server
.\.venv313\Scripts\Activate.ps1
python -m alembic upgrade head
```
