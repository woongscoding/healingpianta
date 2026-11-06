# 진행 상황

Phase가 끝날 때마다 이 파일을 갱신한다. (계획 전체는 [CLAUDE.md](../CLAUDE.md) 8절)

## 지금 위치

**Phase 1 완료 → 다음은 Phase 2 (로그인·연령·동의·온보딩)**

Phase 2를 시작하기 전에 사용자가 할 일: [SETUP.md](SETUP.md) 3단계 (Firebase 프로젝트 만들기).

## Phase 상태

| Phase | 내용 | 상태 |
|---|---|---|
| 1 | 기반 (프로젝트, 콘텐츠 로더, 조사 헬퍼, 보안 규칙) | ✅ 완료 (2026-11-05) |
| 2 | 로그인·연령·동의·온보딩 | ⏳ Firebase 프로젝트 대기 |
| 3 | 홈·체크인·행동 흐름 | |
| 4 | 새싹 모형 | |
| 5 | 카메라·업로드·AI 판독 | |
| 6 | 일대기 앨범 | |
| 7 | 수확·레시피·다시 시작 | |
| 8 | 알림 | |
| 9 | 안전장치 | |
| 10 | 키트 추천·리필 알림 | |
| 11 | 주간 리포트 | |
| 12 | 홈 화면 위젯 | |
| 13 | 레벨·도감·스킬 트리 | |
| 14 | 알림 문구 학습 | |
| 15 | 새싹 친구 | |
| 16 | 출시 준비 | |

## 정해진 것 (사용자 확인 완료)

| 항목 | 값 |
|---|---|
| Android applicationId / iOS bundle id | `com.healingpianta.app` |
| Firebase 프로젝트 | 아직 없음 → 이름 `HealingPianta`, ID `healingpianta` 권장 |
| GitHub | https://github.com/woongscoding/healingpianta (공개 저장소) |

## 아직 정하지 않은 것 (CLAUDE.md 11절)

- 이용약관·개인정보처리방침·웹 계정 삭제 안내 URL
- 쿠팡 파트너스 링크
- 지지 모드 기준과 `safety.json` 문구 최종본 (전문가 검토)
- OpenAI 모델명(`OPENAI_MODEL`)과 월 예산
- Blaze 요금제 전환과 예산 알림 (Phase 5 전)

## Phase 1 메모

- 테스트: `flutter test` 61개, 보안 규칙 에뮬레이터 27개, 금지 문구 검사 0건
- 보안 규칙 테스트는 `demo-healingpianta` 가짜 프로젝트로 오프라인 실행 (실제 Firebase 불필요)
- `firebase-tools` 15는 Java 21 이상 필요 → 휴대용 JDK `C:\src\jdk21`
- 다음에 고칠 것: 한국어 문장이 낱말 중간에서 줄바꿈됨 (Phase 3 홈 화면에서 처리)
