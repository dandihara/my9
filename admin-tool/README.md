# admin-tool

초기에는 FastAPI Swagger(`/docs`)를 관리자 대용으로 사용합니다.
나중에 아래 기능을 붙이면 됩니다.

- 오늘 경기 수집 상태
- 특정 경기 강제 동기화
- 선수 기록 확인
- WPA 재계산
- 실패한 sync job 재실행

추천 구현:

- FastAPI + Jinja2로 간단하게 시작
- 커지면 React/Next.js 분리
