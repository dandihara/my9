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
GET /v1/attendances/calendar?year=2026&month=6
GET /v1/attendances/{attendance_id}
PUT /v1/attendances/{attendance_id}
DELETE /v1/attendances/{attendance_id}
```

## WPA

```txt
GET /v1/games/{game_id}/wpa
GET /v1/games/{game_id}/wpa/events
GET /v1/games/{game_id}/wpa/players
POST /v1/admin/games/{game_id}/wpa/recalculate
```
