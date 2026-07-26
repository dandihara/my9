# MY9 mobile-app

Flutter 기반 MY9 Android/iOS 공용 앱 소스입니다.

## 실행

```bash
flutter pub get
flutter run --dart-define=API_BASE_URL=http://API_HOST:8000
```

## Debug APK

Windows에서는 루트 `.env`의 로컬/외부 API 주소를 읽어 3종을 생성한다.

```bat
build-debug-apks.bat
```

- `MY9-local-debug.apk`: 로컬 API, 두산 철웅이 섹션 아이콘
- `MY9-external-cheolwoong-debug.apk`: 외부 API, 두산 철웅이 섹션 아이콘
- `MY9-external-mangom-debug.apk`: 외부 API, 두산 망곰 섹션 아이콘

두산 섹션 아이콘은 런타임 토글 없이 `DOOSAN_SECTION_THEME=cheolwoong|mangom`
빌드 플래그로 고정한다.

iOS는 같은 Flutter 소스를 사용하지만 IPA 빌드·서명은 macOS, Xcode와 Apple Developer 인증서가 필요하다.

## 홈 배경

- 오늘 응원팀 경기가 있으면 해당 구장의 날씨 상태를 배경에만 반영
- 그 외에는 봄·여름·가을·겨울 계절별 기본 배경 사용
- 온도 등 세부 날씨 문구는 화면에 노출하지 않음

## 구조

```txt
lib
├─ main.dart
├─ app.dart
├─ core
│  ├─ config
│  └─ network
├─ features
│  ├─ home
│  ├─ schedule
│  ├─ attendance
│  ├─ live_game
│  ├─ game_record
│  ├─ stats
│  └─ wpa
└─ shared
```
