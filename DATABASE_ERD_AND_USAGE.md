# MY9 데이터베이스 ERD 및 테이블 사용처

> DBMS: PostgreSQL 16
> 마이그레이션: Alembic
> 현행 head: `b63df91e2847`

## 1. 전체 ERD

가독성을 위해 `created_at`, `updated_at`과 일부 세부 지표 컬럼은 ERD에서 생략했다.
정확한 컬럼은 아래 테이블 설명과 SQLAlchemy 모델을 기준으로 한다.

```mermaid
erDiagram
    TEAMS ||--o{ USERS : "응원팀"
    USERS ||--o{ DEVICES : "로그인 기기"
    USERS ||--o{ ATTENDANCE_RECORDS : "직관 작성"
    TEAMS ||--o{ ATTENDANCE_RECORDS : "직관 응원팀"
    USERS ||--o{ ATTENDANCE_LEAGUES : "리그 소유"
    ATTENDANCE_LEAGUES ||--o{ ATTENDANCE_LEAGUE_MEMBERS : "멤버"
    USERS ||--o{ ATTENDANCE_LEAGUE_MEMBERS : "참가"

    TEAMS ||--o{ GAMES : "홈팀"
    TEAMS ||--o{ GAMES : "원정팀"
    STADIUMS ||--o{ GAMES : "개최"
    GAMES ||--o{ ATTENDANCE_RECORDS : "관람"
    GAMES ||--o| GAME_LIVE_STATES : "현재 상태"
    GAMES ||--o{ GAME_SCORES_BY_INNING : "이닝 점수"

    GAMES ||--o{ BATTING_GAME_STATS : "타자 기록"
    PLAYERS ||--o{ BATTING_GAME_STATS : "타자"
    TEAMS ||--o{ BATTING_GAME_STATS : "소속팀"
    GAMES ||--o{ PITCHING_GAME_STATS : "투수 기록"
    PLAYERS ||--o{ PITCHING_GAME_STATS : "투수"
    TEAMS ||--o{ PITCHING_GAME_STATS : "소속팀"

    GAMES ||--o{ GAME_EVENTS : "경기 이벤트"
    TEAMS ||--o{ GAME_EVENTS : "공격/수비팀"
    PLAYERS ||--o{ GAME_EVENTS : "타자/투수"
    GAME_EVENTS ||--o| WPA_EVENTS : "기대승률 변화"
    PLAYERS ||--o{ WPA_EVENTS : "타자/투수"
    GAMES ||--o{ PLAYER_GAME_WPA : "경기별 WPA"
    PLAYERS ||--o{ PLAYER_GAME_WPA : "선수"
    TEAMS ||--o{ PLAYER_GAME_WPA : "소속팀"

    PLAYERS ||--o{ PLAYER_SEASON_BATTING_METRICS : "시즌 타격"
    TEAMS ||--o{ PLAYER_SEASON_BATTING_METRICS : "시즌 팀"
    PLAYERS ||--o{ PLAYER_SEASON_PITCHING_METRICS : "시즌 투구"
    TEAMS ||--o{ PLAYER_SEASON_PITCHING_METRICS : "시즌 팀"
    PLAYERS ||--o{ PLAYER_SEASON_WPA_METRICS : "시즌 WPA"
    TEAMS ||--o{ PLAYER_SEASON_WPA_METRICS : "시즌 팀"

    TEAMS {
        int id PK
        string code UK
        string name UK
        string short_name
        string logo_url
    }
    USERS {
        int id PK
        string username UK
        string password_hash
        string nickname
        int my_team_id FK
        string device_login_key UK
        bool is_active
    }
    GAMES {
        int id PK
        int season_year
        date game_date
        time game_time
        int home_team_id FK
        int away_team_id FK
        int stadium_id FK
        string status
        int home_score
        int away_score
        string external_game_id
        datetime boxscore_finalized_at
    }
    PLAYERS {
        int id PK
        string name
        string external_player_id UK
    }
    ATTENDANCE_RECORDS {
        int id PK
        int user_id FK
        int game_id FK
        int my_team_id FK
        string result_for_my_team
        string seat_section
        string seat_row
        string seat_number
        text memo
    }
    BATTING_GAME_STATS {
        int id PK
        int game_id FK
        int player_id FK
        int team_id FK
        int batting_order
        string position
        int ab
        int h
        int hr
        int rbi
        int sb
    }
    PITCHING_GAME_STATS {
        int id PK
        int game_id FK
        int player_id FK
        int team_id FK
        decimal innings_pitched
        int strikeouts
        int earned_runs
        string decision
    }
    GAME_EVENTS {
        int id PK
        int game_id FK
        int sequence_no
        int inning
        string inning_half
        int batter_id FK
        int pitcher_id FK
        string event_type
        int runs_scored
    }
    WPA_EVENTS {
        int id PK
        int game_event_id FK
        int batter_id FK
        int pitcher_id FK
        decimal we_before
        decimal we_after
        decimal wpa
    }
    PLAYER_GAME_WPA {
        int id PK
        int game_id FK
        int player_id FK
        int team_id FK
        decimal batting_wpa
        decimal pitching_wpa
        decimal total_wpa
    }
```

## 2. 계정과 커뮤니티

### `users`

- 용도: 인증 주체, 닉네임, 기본 응원팀
- 주요 키:
  - `username`: 로그인 ID, unique
  - `password_hash`: 해시된 비밀번호
  - `my_team_id`: 홈·직관·구단 테마의 기본 팀
- 사용처:
  - `/v1/auth/register`, `/login`, `/me`
  - 모든 직관/직관 리그 인증
  - 앱 홈의 응원팀 선택

### `devices`

- 용도: 사용자별 앱 기기, 플랫폼, FCM 토큰, 앱 버전
- 현행 사용: 스키마 준비 상태
- 향후 사용: 경기 시작, 우천, 직관 리그 알림

### `attendance_leagues`

- 용도: 직관 대결 그룹
- `owner_id`: 생성자
- `invite_code`: 참가 코드, unique
- 사용처: 리그 생성, 목록, 초대 참가, 상세 조회

### `attendance_league_members`

- 용도: 리그와 사용자의 N:M 연결
- unique: `(league_id, user_id)`
- `role`: `owner` 또는 `member`
- 리그 삭제 시 멤버 행은 cascade 삭제

## 3. 기준 정보

### `teams`

- 용도: KBO 구단 마스터
- `code`: 내부/수집 매핑 코드, unique
- 모든 경기, 선수 경기 기록, 시즌 기록, 응원팀의 기준

### `stadiums`

- 용도: 구장명, 주소, 도시, 좌표
- 일정 수집 시 구장명이 없으면 자동 생성
- 직관 구장별 승률과 경기 상세에서 사용

### `players`

- 용도: 선수 마스터
- `external_player_id`: 외부 소스와 선수를 안정적으로 연결
- 타자/투수 경기 기록, 경기 이벤트, WPA, 시즌 집계의 중심 키

## 4. 경기

### `games`

- 용도: 일정, 진행 상태, 최종 결과의 원본
- unique: `(external_source, external_game_id)`
- 상태:
  - `scheduled`
  - `in_progress`
  - `completed`
  - `cancelled`
- `boxscore_finalized_at`:
  - 완료 박스스코어 저장 시각
  - null인 완료 경기는 재수집 대상
- 사용처:
  - 일정 달력
  - 홈 최근 5경기/다음 경기
  - 구단 순위
  - 직관 기록과 승요
  - 모든 경기 기록의 상위 엔터티

### `game_live_states`

- 용도: 한 경기의 최신 이닝, 초/말, 아웃, 주자 상태, 설명
- `game_id` unique이므로 경기당 1행
- 10초 실시간 폴링 결과를 upsert

### `game_scores_by_inning`

- 용도: 이닝별 홈/원정 점수
- 현행 모델/API 구조는 준비되어 있으나 워커의 기본 일정 수집은 총점 중심

## 5. 직관

### `attendance_records`

- 용도: 사용자가 실제로 관람한 경기와 좌석/메모
- `my_team_id`가 null이면 중립 관람
- `result_for_my_team`은 생성 시 저장하며 조회 시 경기 결과로 보완 계산
- `rating`은 레거시 컬럼으로 DB에는 남아 있지만 앱 입력/표시에서는 제거
- 사용처:
  - 직관 목록/상세/수정/삭제
  - 전체 승요
  - 요일별·구장별 승률
  - 직관 경기 타자/투수 TOP 3
  - 직관 경기 결승타 순위

## 6. 경기별 선수 기록

### `batting_game_stats`

- 용도: 경기 한 건의 선수 타격 기록
- 타순과 포지션이 같아도 교체 선수를 보존할 수 있도록 선수별 행 저장
- 주요 지표:
  - `ab`, `r`, `h`, `doubles`, `triples`, `hr`, `rbi`
  - `bb`, `hbp`, `sf`, `so`, `sb`
  - `avg_after_game`
- 사용처:
  - 경기 선수 기록
  - 직관 TOP 3
  - 팀 타율/안타/홈런
  - 시즌 타자 집계

### `pitching_game_stats`

- 용도: 경기 한 건의 선수 투구 기록
- 주요 지표:
  - `innings_pitched`, `hits`, `home_runs`, `batters_faced`
  - `runs`, `earned_runs`, `walks`, `strikeouts`, `pitches`
  - `decision`, `era_after_game`
- 사용처:
  - 경기 선수 기록
  - 직관 투수 TOP 3와 승수
  - 팀 ERA/WHIP/탈삼진
  - 시즌 투수 집계

## 7. 시즌 집계

### `player_season_batting_metrics`

- unique: `(season_year, player_id, team_id)`
- 경기별 타격 기록을 합산한 조회 전용 집계
- AVG/OBP/SLG/OPS, 추정 wOBA/wRC/wRC+, 안타/도루 등의 정렬에 사용
- `qualification_pa`, `is_qualified`로 규정 타석 구분

### `player_season_pitching_metrics`

- unique: `(season_year, player_id, team_id)`
- ERA/WHIP/K9/BB9/KBB/FIP/K-BB% 계산 결과
- `qualification_innings`, `is_qualified`로 규정 이닝 구분

### `player_season_wpa_metrics`

- unique: `(season_year, player_id, team_id)`
- `player_game_wpa`를 시즌 단위로 합산
- 시즌 기록 화면의 타격/투구/합계 WPA에 사용

## 8. WPA

### `game_events`

- 용도: 타석/주루 등 경기 이벤트의 전후 상태
- 상태 필드:
  - 이닝/초말
  - 아웃 전후
  - 루상 전후(`000`~`111`)
  - 점수 차 전후
  - 득점 수
- 사용처:
  - 결승타 판정
  - 이벤트별 WPA 계산의 입력

### `win_expectancy_table`

- 용도: 시즌, 이닝, 초말, 아웃, 루상, 점수 차에 따른 기대승률 기준표
- 현행 데이터 공급원이 해당 상태값을 제공할 때 WPA 계산에서 조회

### `wpa_events`

- `game_event_id` unique
- 이벤트 전 기대승률, 이벤트 후 기대승률, 차이(WPA)
- 경기 WPA 흐름 그래프 API의 원본

### `player_game_wpa`

- 용도: 이벤트 WPA를 선수·경기 단위로 합산
- 타격 WPA, 투구 WPA, 합계 WPA 저장
- 경기별 선수 기여도와 시즌 WPA 집계의 원본

## 9. 동기화 지원

### `sync_jobs`

- 용도: 시즌 지표 집계 및 시즌 전체 백필 실행 이력
- `job_type`: 예 `season_metrics:2026`
- `job_type`: 전체 백필 성공 시 예 `season_backfill:2026`
- `target_date`: 집계에 반영된 최종 경기일
- API가 시즌 기록의 `as_of_date`를 표시하고, 워커가 다음 시작 날짜를 결정할 때 사용

### `source_mappings`

- 용도: 외부 소스 ID와 내부 엔터티 ID의 일반 매핑
- unique: `(source, source_type, external_id)`
- 현행 KBO 핵심 경로는 팀 코드와 `external_player_id`를 직접 사용하며,
  이 테이블은 다른 데이터 공급원 추가 시 확장 지점

## 10. 삭제 및 데이터 보존 주의

- 대부분의 경기/선수 FK에는 자동 cascade가 없다.
- 운영에서 경기나 선수를 직접 삭제하려면 하위 기록을 먼저 확인해야 한다.
- 직관 리그 멤버만 `league_id` 삭제 cascade가 설정되어 있다.
- 시즌 집계는 원본 경기 기록으로 재생성되므로 직접 수정하지 않는 것이 원칙이다.
- `games.boxscore_finalized_at`을 null로 바꾸면 워커가 해당 완료 경기의 박스스코어를 다시 수집할 수 있다.
