# HealingPianta

실제 새싹채소를 키우며 아주 작은 행동을 돕는 셀프케어 앱(웰니스 앱, 의료기기 아님).
설계 기준은 [CLAUDE.md](CLAUDE.md)에 있다. 작업 전에 반드시 읽는다.

- 새 PC에서 시작하기 / Firebase 만들기: [docs/SETUP.md](docs/SETUP.md)
- 진행 상황: [docs/PROGRESS.md](docs/PROGRESS.md)

## 개발 환경

| 도구 | 버전 / 위치 |
|---|---|
| Flutter | stable (3.47.x), `C:\src\flutter` |
| Android applicationId | `com.healingpianta.app` |
| Firebase CLI | `npm i -g firebase-tools` |
| Java (에뮬레이터용) | 21 이상. Windows 개발 PC는 휴대용 JDK `C:\src\jdk21` |
| Node | 22 (보안 규칙 테스트) |

## 검사

```bash
bash tool/check.sh            # analyze + test + 금지 문구 + 보안 규칙
bash tool/check.sh --no-rules # 에뮬레이터 없이
```

- `flutter test` — 단위·위젯 테스트 (`test/`)
- `dart run tool/lint_copy.dart` — 금지 문구 검사 (`safety.json`의 `forbiddenCopy`)
- `rules_test/` — Firestore·Storage 보안 규칙 에뮬레이터 테스트 (`demo-healingpianta`, 오프라인)

## 폴더

- `assets/content/` — 사용자에게 보이는 모든 문구와 데이터. 코드에서는 읽기만 한다.
- `lib/core/content/` — 콘텐츠 로더와 스키마 검증
- `lib/core/josa.dart` — 조사 헬퍼(`{name.이가}` 등)와 슬롯 치환
- `functions/` — Python Cloud Functions (Phase 5)
- `firestore.rules`, `storage.rules` — 보안 규칙
