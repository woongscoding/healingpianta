#!/usr/bin/env bash
# 매 Phase 끝에 돌리는 전체 검사 (CLAUDE.md 9절).
#   bash tool/check.sh            # 전부
#   bash tool/check.sh --no-rules # 에뮬레이터 규칙 테스트 빼고
set -euo pipefail
cd "$(dirname "$0")/.."

RUN_RULES=1
[[ "${1:-}" == "--no-rules" ]] && RUN_RULES=0

# Windows 개발 PC 기본 설치 위치 (없으면 PATH 그대로 사용)
[[ -d /c/src/flutter/bin ]] && export PATH="/c/src/flutter/bin:$PATH"

echo "== flutter analyze"
flutter analyze

echo "== flutter test"
flutter test

echo "== lint_copy (금지 문구)"
dart run tool/lint_copy.dart

if [[ -d functions/tests ]]; then
  echo "== pytest (functions)"
  (cd functions && python -m pytest -q)
fi

if [[ $RUN_RULES == 1 ]]; then
  echo "== 보안 규칙 (Firebase 에뮬레이터, Java 21 필요)"
  # firebase-tools 는 Java 21 이상이 필요하다. 휴대용 JDK 가 있으면 그것을 쓴다.
  if [[ -d /c/src/jdk21 ]]; then
    export JAVA_HOME='C:\src\jdk21'
    export PATH="/c/src/jdk21/bin:$PATH"
  fi
  (cd rules_test && { [[ -d node_modules ]] || npm ci; } && npm run emulator)
fi

echo "== 모두 통과"
