# 새 노트북에서 시작하기

다른 PC에서 이 프로젝트를 이어서 작업할 때 이 순서대로 하면 된다.
지금까지 어디까지 했는지는 [PROGRESS.md](PROGRESS.md)를 본다.

---

## 1단계 — 프로그램 설치 (처음 한 번)

| 순서 | 설치할 것 | 방법 / 확인 |
|---|---|---|
| 1 | **Git** | https://git-scm.com 설치 → `git --version` |
| 2 | **Android Studio** | https://developer.android.com/studio 설치 후 실행 → 첫 화면 마법사에서 SDK 설치 |
| 3 | Android SDK 추가 항목 | Android Studio → Settings → Languages & Frameworks → Android SDK → **SDK Tools** 탭 → `Android SDK Command-line Tools` 체크 → Apply |
| 4 | **Flutter** | PowerShell에서 아래 "Flutter 설치" 명령 실행 |
| 5 | **Node.js 22** | https://nodejs.org (LTS) → `node --version` |
| 6 | **Firebase CLI** | `npm install -g firebase-tools` → `firebase --version` |
| 7 | **JDK 21** (보안 규칙 에뮬레이터용) | 아래 "JDK 21" 참고 |
| 8 | **Python 3.12** (Phase 5부터) | https://www.python.org → 설치 때 "Add to PATH" 체크 |
| 9 | **VS Code + Claude Code 확장** | VS Code 확장 탭에서 "Claude Code" 설치 |

### Flutter 설치 (PowerShell)

```powershell
mkdir C:\src -Force
git clone https://github.com/flutter/flutter.git -b stable --depth 1 C:\src\flutter
[Environment]::SetEnvironmentVariable('Path', [Environment]::GetEnvironmentVariable('Path','User') + ';C:\src\flutter\bin', 'User')
```

PowerShell을 **새로 열고**:

```powershell
flutter --version
flutter doctor --android-licenses   # 전부 y
flutter doctor                      # Android toolchain 에 ✓ 가 나오면 OK
```

### JDK 21

`firebase-tools`의 에뮬레이터는 Java 21 이상이 필요하다. 기존 Java를 건드리지 않으려면 휴대용으로 받는다.

1. https://adoptium.net/temurin/releases/?version=21 → Windows x64 **JDK .zip** 다운로드
2. 압축을 풀어서 폴더 이름을 `C:\src\jdk21` 로 바꾼다 (`C:\src\jdk21\bin\java.exe` 가 있어야 함)
3. `tool/check.sh` 가 이 위치를 자동으로 찾아 쓴다.

---

## 2단계 — 코드 받기

```powershell
cd C:\Users\<내 사용자 이름>
git clone https://github.com/woongscoding/healingpianta.git
cd healingpianta
flutter pub get
cd rules_test; npm ci; cd ..
```

검사가 다 통과하는지 확인 (Git Bash에서):

```bash
bash tool/check.sh
```

마지막에 `== 모두 통과` 가 나오면 준비 끝.
(에뮬레이터 테스트를 빼려면 `bash tool/check.sh --no-rules`)

---

## 3단계 — Firebase 프로젝트 만들기 (Phase 2 전에 한 번)

https://console.firebase.google.com 에서 진행한다. 화면에서 묻는 것과 입력할 값:

### 3-1. 프로젝트 만들기

| 화면에서 묻는 것 | 입력 / 선택 |
|---|---|
| 프로젝트 이름 | **`HealingPianta`** |
| 프로젝트 ID (이름 아래 작게 표시, 연필 아이콘으로 수정) | **`healingpianta`** — 이미 쓰이고 있으면 **`healingpianta-app`** |
| Gemini in Firebase | 사용 안 함 |
| Google 애널리틱스 | **사용 안 함** (분석 수집 최소화 원칙. 나중에 켤 수 있음) |

→ 만들어진 **프로젝트 ID**를 메모해 둔다. Claude에게 알려줄 값이다.

### 3-2. 로그인(Authentication)

| 메뉴 | 입력 / 선택 |
|---|---|
| 빌드 → Authentication → 시작하기 | |
| 로그인 방법 → **Google** | 사용 설정 켜기 |
| 프로젝트의 공개용 이름 | **`HealingPianta`** |
| 프로젝트 지원 이메일 | 본인 이메일 |

### 3-3. 데이터베이스(Firestore)

| 메뉴 | 입력 / 선택 |
|---|---|
| 빌드 → Firestore Database → 데이터베이스 만들기 | |
| 버전 | Standard |
| 데이터베이스 ID | `(default)` 그대로 |
| 위치 | **`asia-northeast3 (Seoul)`** — 나중에 못 바꾼다 |
| 보안 규칙 | **프로덕션 모드** (실제 규칙은 Claude가 `firestore.rules`로 배포) |

### 3-4. Android 앱 등록

| 화면에서 묻는 것 | 입력 |
|---|---|
| 프로젝트 개요 → 앱 추가 → Android | |
| Android 패키지 이름 | **`com.healingpianta.app`** (정확히 이대로) |
| 앱 닉네임 | **`HealingPianta Android`** |
| 디버그 서명 인증서 SHA-1 | 아래 명령으로 나온 값 (노트북마다 다름) |

SHA-1 확인 (PowerShell, Android Studio 설치 후 한 번이라도 빌드한 PC):

```powershell
& "C:\src\jdk21\bin\keytool.exe" -list -v -keystore "$env:USERPROFILE\.android\debug.keystore" -alias androiddebugkey -storepass android | Select-String SHA1
```

- **노트북을 바꿀 때마다 그 노트북의 SHA-1을 추가로 등록**해야 Google 로그인이 된다
  (프로젝트 설정 → 내 앱 → SHA 인증서 지문 추가).
- 처음 작업한 PC의 SHA-1: `41:5D:B2:85:EE:BE:30:07:08:83:9C:9F:18:60:2A:81:57:37:13:29`
- `debug.keystore` 가 없으면 먼저 `flutter build apk --debug` 를 한 번 실행하면 생긴다.

`google-services.json` 다운로드 화면이 나오면 받아서 **`android/app/google-services.json`** 에 넣는다.
(나머지 "SDK 추가" 단계는 Claude가 코드로 하므로 다음 → 다음으로 넘긴다.)

### 3-5. 지금은 하지 않는 것

| 항목 | 언제 | 이유 |
|---|---|---|
| Storage (사진 저장) | Phase 5 전 | 새 프로젝트는 **Blaze(종량제) 요금제**여야 Storage를 만들 수 있다 |
| Cloud Functions (AI 사진 판독) | Phase 5 전 | Blaze 필요. OpenAI 키·모델명·월 예산도 그때 정한다 |
| 예산 알림 | Blaze 전환할 때 | Google Cloud 콘솔 → 결제 → 예산 및 알림 (예: 월 1만 원) |

### 3-6. 터미널에서 Firebase 로그인

```powershell
firebase login
firebase projects:list   # 방금 만든 프로젝트가 보이면 OK
```

---

## 4단계 — Claude Code로 이어서 작업

1. VS Code에서 `healingpianta` 폴더 열기
2. Claude Code 패널에 이렇게 말한다:

   > CLAUDE.md 랑 docs/PROGRESS.md 읽고 Phase 2 시작해줘. Firebase 프로젝트 ID는 `healingpianta` 야.

3. Claude가 물어보는 것(이용약관·개인정보처리방침 URL 등)에 답한다. 아직 없으면 "임시로 해줘"라고 하면 된다.

각 Phase가 끝나면 Claude가 테스트 → 요약 → 커밋을 한다. 다른 PC로 옮기기 전에는 `git push`, 옮긴 PC에서는 `git pull` 부터.
