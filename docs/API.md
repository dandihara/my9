# API 초안

## Health

```txt
GET /health
```

## Teams

```txt
GET /v1/teams
GET /v1/teams/{team_id}
GET /v1/teams/{team_id}/dashboard
```

`dashboard` 응답은 오늘 응원팀 경기가 있고 구장 위치를 확인할 수 있으면
`stadium_weather`를 포함한다. 날씨는 비영속 20분 캐시이며 실패해도 전광판 응답은 정상 반환한다.

## Stadiums

```txt
GET /v1/stadiums
```

## Games

```txt
GET /v1/games?date=2026-06-18
GET /v1/games?from_date=2026-06-01&to_date=2026-06-30
GET /v1/games/{game_id}
GET /v1/games/live/today
GET /v1/games/{game_id}/live
GET /v1/games/{game_id}/boxscore
```

## Attendance

```txt
POST /v1/attendances
GET /v1/attendances
GET /v1/attendances/summary
GET /v1/attendances/calendar?year=2026&month=6
GET /v1/attendances/{attendance_id}
PUT /v1/attendances/{attendance_id}
DELETE /v1/attendances/{attendance_id}
```

`GET /v1/attendances`는 각 기록의 홈/원정 팀 ID와 이름을 함께 내려준다. 앱은 이 값으로
과거 직관의 상대 팀을 계산한다.

`summary`는 직관 승률, 요일/구장별 승률, 누계형 타자/투수 TOP5, 결승타 순위를 반환한다.
직관 화면에서는 짧은 표본에서도 해석 가능한 홈런, 타점, 안타, 도루, 탈삼진, 홀드 같은 누계
기록을 우선 사용한다.

## WPA

```txt
GET /v1/games/{game_id}/wpa
GET /v1/games/{game_id}/wpa/events
GET /v1/games/{game_id}/wpa/players
POST /v1/admin/games/{game_id}/wpa/recalculate
```
