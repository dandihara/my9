# Database 설계

## 주요 테이블

- users
- devices
- teams
- stadiums
- games
- game_live_states
- game_scores_by_inning
- players
- attendance_records
- batting_game_stats
- pitching_game_stats
- game_events
- win_expectancy_table
- wpa_events
- player_game_wpa
- sync_jobs
- source_mappings

## 설계 메모

- 외부 데이터 id는 source_mappings에 보관한다.
- 정정 가능성이 있는 데이터는 updated_at을 둔다.
- game_events는 WPA 계산의 핵심이다.
- 초기 MVP에서는 game_events 없이 경기 결과/박스스코어부터 저장한다.
