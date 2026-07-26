# API 초안

## Health

```txt
GET /health
```

## Teams

```txt
GET /v1/teams
GET /v1/teams/{team_id}
```

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
