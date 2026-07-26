# 아키텍처

```txt
Flutter App
  ↓ REST API
FastAPI Server
  ↓ SQLAlchemy
PostgreSQL
  ↑
Data Worker ← 외부 경기 데이터 소스
  ↓
WPA Engine
```

## 원칙

- Flutter 앱은 외부 경기 데이터 사이트를 직접 호출하지 않는다.
- 경기 일정, 결과, 선수 기록은 서버가 수집하고 DB에 저장한다.
- 앱은 FastAPI만 바라본다.
- WPA 계산은 별도 모듈로 분리한다.
- 외부 데이터 소스는 adapter 패턴으로 교체 가능하게 둔다.

## 서버를 내 PC/노트북으로 둘 때

개발 단계에서는 괜찮습니다.
공개 출시 전에는 아래를 준비하세요.

- HTTPS
- 도메인 또는 터널링 주소
- 절전모드 해제
- DB 백업
- 방화벽/포트포워딩
- 로그 관리
