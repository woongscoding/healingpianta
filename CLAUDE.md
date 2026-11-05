# HealingPianta — Claude Code 작업 지침

이 파일은 이 프로젝트의 설계 기준이다. 작업을 시작하기 전에 항상 끝까지 읽고, 여기 적힌 규칙과 충돌하는 구현은 하지 않는다. 판단이 애매하면 임의로 정하지 말고 사용자에게 묻는다.

---

## 0. 프로젝트 개요

- **무엇:** 우울감이 있는 성인이 **실제 새싹채소를 키우면서** 아주 작은 행동을 하도록 돕는 셀프케어 앱.
- **원리:** 행동활성화(Behavioral Activation). 의욕을 기다리지 않고 작은 행동을 먼저 하면 기분이 따라온다. 큰 행동은 잘게 쪼개고(단계적 과제 부여), 행동 전후 기분을 기록해 "나를 살리는 행동"을 사용자 스스로 발견하게 한다.
- **핵심 루프:** 아침 에너지 체크 → 새싹 사진 체크인 → AI가 사진을 판독해 앱 속 새싹 모형 갱신 → 작은 행동 제안(새싹 돌봄 + 자기 돌봄 짝짓기) → 행동 후 기분 기록 → 일대기 앨범에 잎 하나 추가.
- **성격:** 의료기기가 아닌 **웰니스 앱**. 진단·치료를 하지 않는다.
- **우선순위:** 수익보다 실제 도움. 성공 기준은 앱 체류시간이 아니라 **"앱을 닫고 실제로 행동했는가 + 행동 전후 기분 변화"**다. 좋은 날은 30초 만에 앱을 닫고 행동하러 가는 게 가장 성공한 사용이다.
- **이름:** 앱 표시 이름 `HealingPianta`, 프로젝트 폴더·패키지 이름 `healingpianta`.
- **대상:** 만 19세 이상 성인만.
- **플랫폼:** Android 우선. 코드는 iOS 빌드가 가능하도록 플랫폼 의존 코드를 분리해 둔다.

---

## 1. 절대 규칙 (예외 없음)

1. **의료 표현 금지.** UI·알림·스토어 문구에 "치료", "진단", "처방", "우울증이 낫는다", "효과 보장" 같은 표현을 쓰지 않는다. 앱 안에 고지문(`safety.json`의 `disclaimer`)을 온보딩과 설정에 표시한다.
2. **연속 기록(streak) 금지.** "N일 연속", 0으로 리셋되는 카운터, 놓친 날을 강조하는 UI를 만들지 않는다. **누적 돌본 날**과 **이번 주 정원(주간 목표)**만 쓴다.
3. **죄책감·압박 문구 금지.** "왜 안 왔어요", "새싹이 죽었어요", "실망했어요", "해야 해요", "놓쳤어요" 같은 말을 어디에도 쓰지 않는다.
4. **문구는 콘텐츠 파일에서만.** 사용자에게 보이는 메시지·알림 문구는 `assets/content/*.json`에서 읽는다. 런타임에 AI로 위로·제안 문구를 생성하지 않는다. (AI는 사진 판독에만 쓴다. 판독 결과의 짧은 돌봄 팁도 화면에 그대로 띄우지 말고 2절의 필터를 통과시킨다.)
5. **광고 SDK, 체류시간을 늘리는 장치, 다크패턴 금지.**
6. **API 키는 앱에 절대 넣지 않는다.** OpenAI 키는 Cloud Functions의 Secret Manager(`OPENAI_API_KEY`)에만 둔다. `.env`, 키 파일, `google-services.json` 외 비밀 정보는 git에 올리지 않는다(`.gitignore` 먼저 작성).
7. **보안 규칙:** Firestore·Storage 모두 사용자 본인 데이터만 읽고 쓸 수 있다. AI 판독 결과(`analysis`)와 사용량 카운터(`usage`)는 서버(Admin SDK)만 쓴다.
8. **잠금화면 알림 문구에는** "우울", "기분", "위기", "상담", "자살", "힘들" 같은 단어를 쓰지 않는다. 새싹 이야기로만 쓴다. 알림 공개 범위는 기본 `private`로 설정한다.
9. **도움받기(109) 화면은 모든 화면에서 2번 탭 안에** 닿아야 한다. 홈 상단에 상시 아이콘을 둔다.
10. **지지 모드 중에는** 행동을 유도하는 알림과 제안을 멈춘다(6.5절).
11. **새싹 모형은 항상 귀엽고 건강해 보이게** 그린다. 판독 결과가 나빠도 시들거나 슬프게 그리지 않고, 작은 "도움 필요" 배지만 띄운다.
12. **성인 전용.** 만 19세 미만으로 확인되면 가입을 진행하지 않고 안내 화면(`safety.json`의 `ageGate`)을 보여준다.
13. **Phase 단위로 일한다.** 각 Phase가 끝나면 테스트를 통과시키고, 결과를 요약하고, git commit을 한 뒤 다음 Phase로 간다.

---

## 2. 기술 스택

| 영역 | 선택 |
|---|---|
| 앱 | Flutter 최신 stable, Dart |
| 상태관리 / 라우팅 | `flutter_riverpod` / `go_router` |
| 로그인 | Firebase Auth + Google 로그인 |
| DB | Cloud Firestore (오프라인 캐시 사용) |
| 사진 저장 | Cloud Storage for Firebase (앨범 원본 전부 저장, 기기에도 캐시) |
| 서버 로직 | Cloud Functions for Firebase, **Python, 2nd gen** |
| 리전 | `asia-northeast3`(서울) 우선. 서비스별 지원 여부를 확인하고 안 되면 사용자에게 알린다 |
| 푸시 | FCM(서버 이벤트: 판독 완료 등) + `flutter_local_notifications`(정해진 시간 알림은 기기에서 예약) |
| 설정 원격 변경 | Firebase Remote Config (상담 연락처, 쿠팡 링크, 기능 플래그) |
| 오류 수집 | Firebase Crashlytics |
| 카메라 | `camera` 패키지로 커스텀 프리뷰 (이전 사진 고스트 오버레이 때문) |
| 이미지 처리 | 업로드 전 긴 변 1280px, JPEG 품질 80. 서버에서 AI로 보낼 때 다시 긴 변 768px |
| 새싹 모형 | `CustomPainter`로 코드 렌더링. **Rive는 쓰지 않는다** |
| 홈 위젯 | `home_widget` |
| 공유 / 링크·전화 | `share_plus` / `url_launcher` |
| AI 사진 판독 | OpenAI 비전 지원 모델. 모델명은 환경변수 `OPENAI_MODEL`로 받고 하드코딩하지 않는다. **JSON Schema 구조화 출력** 사용 |

- 패키지를 추가하기 전에 유지보수 상태(최근 릴리스, 공식 지원 여부)를 확인하고, 중단·보관된 패키지는 쓰지 않는다.
- 분석 이벤트는 최소한으로 수집하고, 메모 원문이나 사진은 분석 도구로 보내지 않는다.

---

## 3. 폴더 구조

```
healingpianta/
├─ CLAUDE.md
├─ assets/
│  └─ content/            # 문구·데이터 (이미 작성됨, 코드에서 읽기만)
│     ├─ species.json     # 새싹 종류별 프로필·성장 단계·모형 색
│     ├─ missions.json    # 행동 사다리
│     ├─ messages.json    # 메시지 pool (홈·알림·행동 후·쉬기·지지 모드)
│     ├─ recipes.json     # 수확 레시피 (익혀 먹기 우선)
│     ├─ kits.json        # 추천 키트 (쿠팡 파트너스)
│     ├─ levels.json      # 레벨 경로
│     └─ safety.json      # 고지문, 위기 연락처, 지지 모드 기준, 키워드
├─ lib/
│  ├─ app/                # 라우터, 테마, 앱 진입점
│  ├─ core/               # 공용: 콘텐츠 로더, 조사(josa) 헬퍼, 날짜, 로깅
│  ├─ data/               # Firestore/Storage 리포지토리, 모델
│  ├─ features/
│  │  ├─ auth/            # 로그인, 연령 확인, 동의
│  │  ├─ onboarding/
│  │  ├─ home/            # 인사, 에너지 체크, 행동 제안
│  │  ├─ checkin/         # 기분 기록, 행동 전후
│  │  ├─ camera/          # 촬영 가이드, 업로드
│  │  ├─ sprout/          # 새싹 모형 painter, 단계 판정
│  │  ├─ album/           # 일대기 앨범, 챕터, 슬라이드쇼
│  │  ├─ harvest/         # 수확, 레시피
│  │  ├─ kits/            # 추천 키트
│  │  ├─ report/          # 주간 리포트
│  │  ├─ levels/          # 레벨, 도감, 스킬
│  │  ├─ friends/         # 새싹 친구 (Phase 15)
│  │  ├─ support/         # 도움받기, 지지 모드
│  │  ├─ notifications/   # 알림 규칙 엔진, 예약
│  │  └─ settings/        # 알림 설정, 계정, 데이터 내보내기·삭제
│  └─ main.dart
├─ functions/             # Python Cloud Functions
│  ├─ main.py
│  ├─ analyze.py          # 사진 판독 (Firebase와 무관한 순수 모듈로 분리)
│  ├─ prompts/
│  │  └─ analyze_sprout.md
│  └─ requirements.txt
├─ firestore.rules
├─ storage.rules
├─ firebase.json
├─ test/
└─ tool/
   └─ lint_copy.dart      # 금지 문구 검사
```

`functions/analyze.py`는 Firebase SDK에 의존하지 않는 순수 함수로 만든다(입력: 이미지 바이트·종류·날짜, 출력: 판독 dict). 나중에 AWS Lambda 등으로 옮길 때 껍데기만 바꾸면 되게 하기 위해서다.

---

## 4. 데이터 모델

### Firestore

```
users/{uid}
  birthYear: int
  ageVerifiedAt: timestamp
  consents: { terms: ts, privacy: ts, sensitive: ts }   # 민감정보는 별도 동의
  values: [string]                                      # 온보딩에서 고른 가치 3개
  settings: {
    notificationIntensity: "quiet" | "normal" | "detailed",   # 기본 normal
    quietStart: "23:00", quietEnd: "08:00",
    weeklyGoalDays: 3,
    timezone: "Asia/Seoul"
  }
  level: int                                            # 기본 1
  careDaysTotal: int                                    # 누적 돌본 날
  supportMode: { active: bool, since: ts, reason: string }
  lastOpenedAt: ts
  createdAt: ts

users/{uid}/plants/{plantId}
  kitId, speciesId, name (사용자가 지은 이름), level,
  chapterNo: int, startedAt: ts, status: "growing"|"harvested"|"restarted"|"archived",
  harvestedAt: ts?, placement: string

users/{uid}/plants/{plantId}/photos/{photoId}
  storagePath, takenAt, dayIndex,
  analysisStatus: "pending"|"done"|"skipped"|"failed",
  analysis: {...}        # 서버만 씀 (5절 스키마)
  displayStage: string   # 6.1 결합 규칙 결과 (서버가 씀)
  note: string?, moodAtTime: int?

users/{uid}/checkins/{yyyy-MM-dd}
  energy: 1|2|3, mood: 1..5, note: string?, createdAt

users/{uid}/actions/{actionId}
  missionId, ladderId, step, source: "home"|"notification"|"chain",
  notificationId?, moodBefore, moodAfter?, completedAt?, skipped: bool, rest: bool

users/{uid}/messageLog/{id}   messageId, shownAt, channel: "home"|"push"
users/{uid}/notifLog/{id}     messageId, type, sentAt, openedAt?, actionWithin2h: bool
users/{uid}/usage/{yyyy-MM-dd}  analysisCount   # 서버만 씀

groups/{groupId}              # Phase 15
  memberUids: [uid], inviteCode, createdAt
groups/{groupId}/feed/{id}    uid, sproutSnapshot{speciesId, stage, density, height}, dayIndex, createdAt
groups/{groupId}/reactions/{id}  fromUid, toFeedId, type: "water"|"sun"|"sprout"
```

### Storage

```
users/{uid}/plants/{plantId}/{photoId}.jpg
```

- 업로드 허용: 본인 경로, `image/*`, 5MB 이하.
- 계정 삭제 시 Firestore와 Storage의 사용자 데이터를 모두 지운다(서버 함수).

---

## 5. AI 사진 판독

- 흐름: 앱이 사진을 Storage에 올린다 → Callable Function `analyzeSprout(plantId, photoId)` 호출 → 함수가 Storage에서 읽어 768px로 줄이고 OpenAI에 보낸다 → 결과를 검증해 `photos/{photoId}.analysis`와 `displayStage`에 쓴다 → 앱은 문서 변경을 구독해 모형을 갱신한다.
- 프롬프트와 JSON Schema는 `functions/prompts/analyze_sprout.md`에 있다. 그대로 쓴다.
- **요청에 반드시 넣을 것:** 종류(`speciesId`와 해당 종의 정상 모습 설명), 심은 지 며칠째(`dayIndex`), 직전 판독 단계.
- **사용량 제한:** 사용자당 하루 6회. 트랜잭션으로 `usage/{date}.analysisCount`를 올리고 넘으면 판독하지 않고 `analysisStatus: "skipped"`로 둔다. 앱은 "사진은 앨범에 저장됐어요. 오늘 확인은 여기까지예요"를 보여준다.
- **실패 처리:** 타임아웃·오류면 `failed`. 앱은 날짜 기대값(6.1)으로 모형을 그리고 오류를 사용자에게 길게 설명하지 않는다.
- **AI 팁 필터:** `coachTip`은 40자 이내, 금지어(`tool/lint_copy.dart`와 같은 목록)가 들어 있으면 버리고 `species.json`의 기본 팁을 쓴다.
- 사진은 판독 목적 외에 OpenAI로 보내지 않는다. 학습 데이터 활용은 별도 동의가 있을 때만(현재 미구현, 동의 항목만 설정에 자리 확보).

---

## 6. 핵심 로직 규칙

### 6.1 성장 단계 판정 (AI 결과 + 날짜 결합)
- 단계: `seed → root → sprout → cotyledon_open → harvest_ready → overgrown` (인덱스 0~5).
- `species.json`의 `stageDays`로 날짜 기대 단계를 구한다.
- `confidence < 0.5`이거나 `unclear_photo`면 날짜 기대 단계를 쓴다.
- AI 단계가 날짜 기대보다 2단계 이상 앞서면 기대+1로 제한한다. 뒤처지는 건 그대로 인정한다(발아가 늦는 경우).
- 이전 표시 단계보다 뒤로 가지 않는다(모형이 "퇴보"해 보이지 않게).

### 6.2 메시지 선택 엔진 (`messages.json`)
1. 지지 모드면 `support` 목록만 쓴다.
2. 아니면 현재 상황(`context`, 목록은 `messages.json`의 `contexts`)과 에너지로 `home` 후보를 거른다. 시간대는 `messages.json`의 `timeRanges`를 따른다. 이벤트 상황(발아·수확·새 챕터·복귀·다시 시작·레벨업 제안 등)이 시간대보다 우선한다. 복귀(`return_after_absence`)는 마지막 접속 후 3일 이상일 때.
3. 최근 14일 안에 보여준 `messageId`는 뺀다. 후보가 없으면 가장 오래전에 보여준 것을 쓴다.
4. 행동-기분 기록이 3건 이상 쌓이면 30% 확률로 `personal` 템플릿을 쓴다(필요한 슬롯 값이 있을 때만).
5. 슬롯 치환: `messages.json`의 `slotsDoc`에 정의된 슬롯(`{name}`, `{day}`, `{care_days}`, `{action}`, `{delta}`, `{count}`, `{next}`). 값이 없는 슬롯이 있는 문구는 후보에서 뺀다.
6. **조사 처리:** `{name.이가}`, `{name.은는}`, `{name.을를}`, `{name.와과}`, `{name.아야}`, `{name.이랑}` 형식을 지원하는 헬퍼를 `lib/core/josa.dart`에 만든다(받침 유무로 선택, 영문·숫자 이름도 처리). 슬롯에 들어가는 다른 값(`{action}` 등)도 같은 문법을 쓴다.

### 6.3 행동 제안 (`missions.json`)
- 홈에서 에너지(1~3)를 받으면 `minEnergy <= 에너지`인 미션 중 **2개 + "오늘은 쉬기"**를 보여준다.
- 2개 중 하나는 가능한 한 `plantPair`(새싹 돌봄과 짝지은 행동)에서 고른다.
- 같은 사다리에서는 사용자가 마지막으로 완료한 단계 또는 그 다음 단계를 제안한다. 건너뛰지 않는다.
- 행동 후 "하나 더" 제안은 에너지 3이고 `moodAfter >= moodBefore`일 때만, 같은 사다리의 다음 칸으로, 하루 최대 1번.
- 기분 변화가 음수면 그 미션은 7일 동안 추천 가중치를 낮춘다.

### 6.4 알림 규칙 (`lib/features/notifications/`)
- 하루 상한(새싹 이벤트 포함): quiet 1, normal 2, detailed 3.
- 기본 슬롯: 아침 돌봄(사용자가 평소 체크인하는 시간 ±30분, 기록 없으면 08:30), 저녁(20:30). 새싹 이벤트(발아, 수확 적기)는 상한 안에서 슬롯을 대체한다.
- 조용한 시간(기본 23:00~08:00)에는 보내지 않는다. 23시 이후 활동 제안은 어떤 경우에도 보내지 않는다.
- **감쇠:** 연속 3번 알림 후 6시간 안에 앱을 안 열면 하루 상한을 1로 낮춘다. 7일 동안 앱을 안 열면 `gentle_return` 알림을 **한 번만** 보내고, 사용자가 다시 올 때까지 정기 알림을 멈춘다. 복귀하면 원래 설정으로 돌린다.
- 지지 모드: 행동 유도 알림 중단, 하루 1번 `support_checkin`만.
- 알림 문구는 `messages.json`의 `notifications`에서 같은 14일 중복 금지 규칙으로 고른다.
- `notifLog`에 기록하고, 알림 후 2시간 안에 "해봤어요"가 눌리면 `actionWithin2h: true`.
- Android 13+ 알림 권한은 온보딩의 알림 단계에서 이유를 설명한 뒤 요청한다.

### 6.5 지지 모드 (`safety.json`의 `supportMode`)
- **진입(기본값, 전문가 검토 전 임시값):** 기분 1이 연속 3번 체크인 / 최근 5번 중 4번이 2 이하 / 메모에 위기 키워드 감지.
- **위기 키워드 감지는 기기 안에서만** 한다. 감지되면 바로 도움받기 화면을 부드럽게 띄우고(경고·알람 톤 금지), 메모 원문을 서버 분석이나 로그로 보내지 않는다.
- **해제:** 사용자가 "조금 괜찮아졌어요"를 누르거나, 기분 3 이상이 연속 2번.
- 지지 모드 동안: 홈 메시지는 `support`만, 행동 제안 카드 숨김(쉬기·새싹 보기만 남김), 도움받기 카드를 홈 가운데에 표시.
- 기준값은 Remote Config로 덮어쓸 수 있게 한다.

### 6.6 주간 정원 & 누적
- 돌본 날 = 그날 체크인·사진·행동 중 하나라도 있으면 1일.
- "이번 주 정원": 월~일 중 돌본 날 수 / `weeklyGoalDays`(기본 3). 채우면 `weekly_goal_met` 메시지. 못 채워도 아무 표시 안 함.
- 누적 돌본 날은 줄어들지 않는다.

### 6.7 챕터·수확·다시 시작
- 식물 하나를 심어서 수확(또는 다시 시작)할 때까지가 한 챕터.
- `harvest_ready`가 되면 수확 버튼 활성화. 수확하면 수확 카드(요리 사진 선택)로 챕터 마무리 → 새 챕터 시작 제안(이름 유지 또는 새 이름).
- 곰팡이 의심이 확인되면 "다시 시작하기"로 챕터를 `restarted`로 닫는다. 실패 표현 없이 기록을 그대로 남긴다.
- 두 번째 챕터부터는 이전 챕터와 같은 날짜의 사진을 나란히 보여주는 비교 카드를 제공한다.

### 6.8 레벨업 (`levels.json`)
- 조건을 채우면 **제안**만 한다. 사용자가 수락해야 올라간다. 지금 단계에 머물 수 있다.
- 레벨 다운 없음. 이전 식물은 정원에 계속 남는다.
- 고레벨 식물이 죽어도 레벨 유지, 도감에 "도전 기록"으로 남긴다.
- 계절 제한이 있는 레벨은 해당 계절에만 열린다.

### 6.9 알림 문구 학습 (Phase 14)
- 메시지 `category`별 Beta(α, β) 분포로 사용자별 Thompson Sampling. 보상 = 알림 후 2시간 안의 "해봤어요". `event` 카테고리(발아·수확·리포트 등 사건 알림)는 학습 대상에서 뺀다.
- 14일 중복 금지, 지지 모드, 상한 규칙이 항상 먼저 적용되고 학습은 그 안에서만 고른다.

---

## 7. 화면 목록과 흐름

1. **스플래시**
2. **Google 로그인**
3. **연령 확인:** 출생 연도 입력. 만 19세 미만이면 `ageGate` 안내 후 종료.
4. **동의:** 이용약관·개인정보처리방침(필수), 민감정보 처리(별도 필수). 링크는 Remote Config 값.
5. **고지문:** `disclaimer` 표시 후 확인.
6. **온보딩:** 소중한 가치 3개 선택 → 받은 키트 선택(`kits.json` 카드, "아직 없어요"면 키트 추천 페이지로) → 이번에 심을 종류 선택(4종 세트일 때) → 새싹 이름 짓기 → 두는 위치 안내(매일 눈에 띄는 곳) → 알림 강도·조용한 시간 → 알림 권한 → 첫 메시지(`first_open`).
7. **홈:** 상단 도움받기 아이콘 · 인사 메시지 · 새싹 모형(탭하면 카메라) · 에너지 3단계 · 행동 제안 2개 + 쉬기 · 이번 주 정원 · 누적 돌본 날.
8. **행동 흐름:** 하기 전 기분(5점) → "해봤어요"/"오늘은 패스" → 하고 난 뒤 기분 → 전후 비교 + `afterAction` 메시지 → 잎 추가 애니메이션 → (조건 충족 시) 하나 더.
9. **카메라:** 직전 사진 반투명 겹쳐 보기, "사진 없이 체크" 버튼, 촬영 후 한 줄 메모(선택).
10. **판독 결과:** 모형 갱신 애니메이션, 단계 이름, 문제 있으면 도움 카드(곰팡이 vs 뿌리털 구분법 → 다시 시작).
11. **앨범:** 식물별 챕터 목록 → 챕터 상세(날짜별 사진 + 기분 + 메모) → 슬라이드쇼 재생 → 공유 카드 이미지.
12. **수확:** 수확 안내 → 레시피(익혀 먹기 우선) → 요리 사진 → 챕터 마무리.
13. **키트 추천:** 카드 + 쿠팡 링크 + 대가성 문구. 리필 알림 설정.
14. **주간 리포트:** 돌본 날, 행동별 평균 기분 변화, "나를 살리는 행동 Top 3".
15. **레벨·도감·스킬 트리**
16. **새싹 친구** (Phase 15)
17. **도움받기:** 109 전화, 마들랜 링크, 긴급 119. 짧고 따뜻한 문구.
18. **설정:** 알림 강도·조용한 시간, 주간 목표, 고지문, 개인정보처리방침, 데이터 내보내기(JSON + 사진 zip), 계정 삭제(앱 안에서 즉시 + 웹 삭제 안내 URL), 앱 정보.

디자인 톤: 부드러운 초록·크림 계열, 둥근 모서리, 큰 글씨, 한 화면에 결정 하나. 다크 모드 지원. 텍스트 크기 확대(접근성 글꼴 크기)에서도 깨지지 않게.

---

## 8. 구현 순서 (전부 구현한다. 순서대로)

각 Phase의 "완료 기준"을 모두 만족해야 다음으로 간다.

**Phase 1 — 기반**
Flutter 프로젝트 생성, 폴더 구조, `.gitignore`, Firebase 연결(사용자에게 프로젝트 ID·`google-services.json` 받기), Riverpod·go_router, 테마, 콘텐츠 로더(`assets/content` 전부 파싱 + 스키마 검증), 조사 헬퍼, Firestore·Storage 보안 규칙 초안.
완료 기준: 앱 실행, 콘텐츠 7개 파일 파싱 테스트 통과, 조사 헬퍼 테스트 통과, 에뮬레이터 보안 규칙 테스트(타인 데이터 거부, `analysis` 클라이언트 쓰기 거부) 통과.

**Phase 2 — 로그인·연령·동의·온보딩**
7절 1~6. 사용자 문서 생성.
완료 기준: 신규 사용자가 끝까지 온보딩하고 홈 도착. 19세 미만 차단 확인.

**Phase 3 — 홈·체크인·행동 흐름**
인사 메시지 엔진(6.2), 에너지 체크, 행동 제안(6.3), 행동 전후 기분, `afterAction`, 쉬기, 누적·주간 정원(6.6).
완료 기준: 메시지 엔진 단위 테스트(14일 중복 금지, 상황 우선순위, 조사), 행동 제안 단위 테스트.

**Phase 4 — 새싹 모형**
`CustomPainter` 모형: 입력 `stage(0~5), height(0~1), density(0~1), lean(-1~1), stemColor, leafColor, potColor, hasIssue`. 6단계 모두 귀엽게, 단계 전환 애니메이션, 잎 추가 애니메이션. 디버그 화면에서 슬라이더로 모든 입력 확인 가능하게.
완료 기준: `species.json`의 모든 스킨 × 6단계 골든 테스트(스냅샷).

**Phase 5 — 카메라·업로드·AI 판독**
고스트 오버레이 카메라, 압축, Storage 업로드, `analyzeSprout` 함수(Python), 사용량 제한, 6.1 결합 규칙, 결과 구독·모형 갱신, 곰팡이/뿌리털 도움 카드, 사진 없이 체크.
완료 기준: 함수 단위 테스트(OpenAI 응답 목업으로 스키마 검증·결합 규칙·제한), 실제 기기에서 사진 1장 왕복.

**Phase 6 — 일대기 앨범**
챕터 목록·상세, 사진별 기분·메모, 슬라이드쇼, 공유 카드 이미지 생성, 두 번째 챕터 비교 카드.
완료 기준: 사진 20장 챕터에서 스크롤·슬라이드쇼 버벅임 없음.

**Phase 7 — 수확·레시피·다시 시작**
6.7 전부, `recipes.json`.

**Phase 8 — 알림**
6.4 전부. 로컬 예약 + FCM 수신. 알림 탭 시 해당 화면으로 이동.
완료 기준: 스케줄러 단위 테스트(상한, 조용한 시간, 23시 차단, 감쇠, 7일 1회, 지지 모드).

**Phase 9 — 안전장치**
도움받기 화면, 상시 아이콘, 지지 모드(6.5), 기기 내 키워드 감지, Remote Config 연동, 잠금화면 문구 점검.
완료 기준: 지지 모드 진입·해제 단위 테스트, 모든 화면에서 도움받기까지 2탭 이하 확인(위젯 테스트).

**Phase 10 — 키트 추천·리필 알림**
`kits.json` + Remote Config 링크, 대가성 문구, "아직 키트 없어요" 흐름, 씨앗 소진 예상 시점 리필 알림(알림 상한 안에서).

**Phase 11 — 주간 리포트**
행동별 평균 기분 변화, Top 3, 일요일 저녁 리포트 알림(상한 안에서).

**Phase 12 — 홈 화면 위젯 (Android)**
`home_widget`으로 새싹 모형 이미지 + 한 줄 상태(문구는 `notifications`의 잠금화면 규칙 적용). 탭하면 앱 홈.

**Phase 13 — 레벨·도감·스킬 트리**
`levels.json`. Lv.1(새싹채소) 완성 + Lv.2(스킨답서스 물꽂이) 모형·프로필·판독까지 구현. Lv.3 이상은 잠긴 미리보기 카드. "내 식물 등록"(사진 + 종류 직접 선택).

**Phase 14 — 알림 문구 학습**
6.9.

**Phase 15 — 새싹 친구**
초대 코드로만 만드는 3~5명 그룹(공개 매칭 없음). 서로의 **새싹 모형과 날짜만** 보이고 원본 사진은 보이지 않는다. 텍스트 없이 반응 3종(💧☀️🌱)만. 그룹 나가기·차단. 지지 모드 중에는 그룹 알림 끔.

**Phase 16 — 출시 준비**
계정 삭제(앱 내 + 웹 URL), 데이터 내보내기, 개인정보처리방침 링크(Play Console과 앱 안 모두), Play Console 건강 앱 신고서(정신·행동 건강 항목)와 데이터 보안 섹션 작성용 체크리스트 문서(`docs/release_checklist.md`), 비공개 테스트 안내 문구, 앱 아이콘·스플래시, 릴리스 빌드 서명 안내.

**이번 범위에서 만들지 않는 것:** 자체 키트 판매·결제, 기관용 대시보드(별도 웹 프로젝트), 자체 ML 모델 학습, 날씨 연동, 자가점검 설문(문항은 공식 한국어판 확보 후 — 설정에 기능 플래그 `selfCheckEnabled=false`로 자리만).

---

## 9. 테스트

- **단위:** 메시지 엔진, 조사 헬퍼, 행동 제안, 단계 결합(6.1), 알림 스케줄러(6.4), 지지 모드(6.5), 주간 정원(6.6), 레벨 조건(6.8), Thompson Sampling(6.9).
- **보안 규칙:** Firebase Emulator로 Firestore·Storage 규칙 테스트.
- **함수:** pytest, OpenAI 호출은 목업.
- **골든:** 새싹 모형 스킨 × 단계.
- **문구 검사:** `tool/lint_copy.dart`가 `assets/content/*.json`의 `forbiddenCopy.scanFields` 값과 `lib/` 안의 한국어 문자열에서 `forbiddenCopy.words`를 찾으면 실패. `lintExempt: true`인 객체(고지문)는 건너뛴다. 알림 문구와 홈 위젯 문구는 `lockScreenWords`도 검사한다.
- 매 Phase 끝에 `flutter analyze`, `flutter test`, `pytest` 모두 통과.

---

## 10. 고정 문구

`safety.json`에 있다: 고지문, 연령 안내, 위기 연락처, 쿠팡 대가성 문구, 도움받기 화면 문구. 코드에 복사하지 말고 읽어서 쓴다. 연락처는 Remote Config로 덮어쓸 수 있게 한다.

---

## 11. 사용자에게 꼭 확인할 것 (임의로 정하지 말 것)

- Android `applicationId`(예: `com.xxx.healingpianta`)와 Firebase 프로젝트 ID
- 이용약관·개인정보처리방침·웹 계정 삭제 안내 URL
- 쿠팡 파트너스 링크(`kits.json`의 `partnerUrl`) — 사용자가 직접 발급
- 지지 모드 기준과 `safety.json` 문구 최종본 — 정신건강 전문가 검토 후 확정
- OpenAI 모델명(`OPENAI_MODEL`)과 월 예산 상한
- Cloud Functions 배포 전 Blaze 요금제 전환과 예산 알림 설정 여부

---

## 12. 일하는 방식

- 사용자와는 한국어로 대화한다.
- Phase 시작 전에 무엇을 만들지 3~5줄로 요약하고, 끝나면 만든 것·테스트 결과·사용자가 확인할 것·다음 Phase를 요약한다.
- 실제 기기에서 확인이 필요한 부분은 사용자에게 구체적으로 무엇을 눌러보면 되는지 알려준다.
- 콘텐츠 파일의 문구를 바꿔야 할 것 같으면 직접 바꾸지 말고 제안한다(문구는 전문가 검토 대상).
