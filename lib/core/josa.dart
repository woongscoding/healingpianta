/// 한국어 조사 헬퍼와 문구 슬롯 치환.
///
/// 문구 파일(`assets/content/*.json`)은 `{name}`, `{name.이가}` 같은 슬롯을 쓴다.
/// 조사 표기는 받침이 있을 때 형태를 앞에 쓰는 규칙(`이가` → 받침 있으면 `이`, 없으면 `가`)을
/// 따르며, `와과`만 예외적으로 받침 없을 때 형태(`와`)가 앞에 온다.
library;

/// 지원하는 조사.
enum Josa {
  /// 이/가
  iGa('이가', '이', '가'),

  /// 은/는
  eunNeun('은는', '은', '는'),

  /// 을/를
  eulReul('을를', '을', '를'),

  /// 과/와 (받침 있으면 과, 없으면 와)
  waGwa('와과', '과', '와'),

  /// 아/야 (부르는 말)
  aYa('아야', '아', '야'),

  /// 이랑/랑
  irang('이랑', '이랑', '랑');

  const Josa(this.key, this.withBatchim, this.withoutBatchim);

  /// 문구 파일에서 쓰는 표기 (`{name.이가}`의 `이가`).
  final String key;

  /// 앞 글자에 받침이 있을 때 붙는 형태.
  final String withBatchim;

  /// 앞 글자에 받침이 없을 때 붙는 형태.
  final String withoutBatchim;

  /// 받침 여부를 알 수 없을 때 쓰는 형태. 예: `이(가)`, `(이)랑`.
  String get ambiguous {
    if (this == Josa.irang) return '(이)랑';
    return '$withBatchim($withoutBatchim)';
  }

  static Josa? fromKey(String key) {
    for (final j in Josa.values) {
      if (j.key == key) return j;
    }
    return null;
  }
}

/// [word] 뒤에 [josa]를 붙여 돌려준다. 예: `attachJosa('새싹', Josa.iGa)` → `새싹이`.
String attachJosa(String word, Josa josa) => '$word${josaFor(word, josa)}';

/// [word] 뒤에 올 조사 형태만 돌려준다.
String josaFor(String word, Josa josa) {
  final batchim = hasBatchim(word);
  if (batchim == null) return josa.ambiguous;
  return batchim ? josa.withBatchim : josa.withoutBatchim;
}

/// [word]의 마지막 발음에 받침이 있는지 판단한다.
///
/// - 한글: 마지막 음절의 종성으로 판단.
/// - 숫자: 한국어로 읽은 소리 기준(1 일, 3 삼, 10 십 …).
/// - 영문: 발음 근사 규칙(아래 [_englishHasBatchim]).
/// - 끝의 공백·문장부호·이모지·괄호는 건너뛴다.
/// - 판단할 수 없으면 null.
bool? hasBatchim(String word) {
  final runes = word.runes.toList();
  var i = runes.length - 1;
  while (i >= 0 && !_isMeaningful(runes[i])) {
    i--;
  }
  if (i < 0) return null;

  final last = runes[i];
  if (_isHangulSyllable(last)) {
    return (last - 0xAC00) % 28 != 0;
  }
  if (_isHangulJamo(last)) {
    // 'ㅋㅋ' 같은 자음 단독: 자음이면 받침 있는 것처럼 읽는 경우가 많다.
    return last <= 0x314E; // ㄱ(0x3131)~ㅎ(0x314E)는 자음, 그 뒤는 모음
  }
  if (_isDigit(last)) {
    return _digitHasBatchim(runes, i);
  }
  if (_isLatin(last)) {
    var start = i;
    while (start > 0 && _isLatin(runes[start - 1])) {
      start--;
    }
    return _englishHasBatchim(String.fromCharCodes(runes.sublist(start, i + 1)));
  }
  return null;
}

bool _isHangulSyllable(int r) => r >= 0xAC00 && r <= 0xD7A3;
bool _isHangulJamo(int r) => r >= 0x3131 && r <= 0x318E;
bool _isDigit(int r) => r >= 0x30 && r <= 0x39;
bool _isLatin(int r) => (r >= 0x41 && r <= 0x5A) || (r >= 0x61 && r <= 0x7A);
bool _isMeaningful(int r) =>
    _isHangulSyllable(r) || _isHangulJamo(r) || _isDigit(r) || _isLatin(r) || _isOtherLetter(r);

/// 한자·가나 등 판단할 수 없는 문자도 "마지막 글자"로 인정한다(→ null 반환).
bool _isOtherLetter(int r) =>
    (r >= 0x3040 && r <= 0x30FF) || // 가나
    (r >= 0x4E00 && r <= 0x9FFF); // 한자

/// 숫자는 끝자리 소리로 판단한다.
/// 끝자리가 0이면 영·십·백·천·만 모두 받침이 있다.
bool _digitHasBatchim(List<int> runes, int lastIndex) {
  final d = runes[lastIndex] - 0x30;
  // 0 영, 1 일, 2 이, 3 삼, 4 사, 5 오, 6 육, 7 칠, 8 팔, 9 구
  const batchim = [true, true, false, true, false, false, true, true, true, false];
  return batchim[d];
}

/// 영어 단어 끝소리 근사 규칙.
///
/// 완벽할 수 없으므로 흔한 이름·단어에서 자연스러운 쪽을 고른다.
/// - 대문자 약어(2~4자, 예: ABC, SNS)는 알파벳 이름으로 읽는다 (L 엘, M 엠, N 엔, R 알).
/// - 'ng', 'ck' → 받침 (킹, 락)
/// - 끝이 me/ne → 받침 (타임, 제인)
/// - 끝 글자가 l, m, n, k, p, t, b, c, q → 받침 (빌, 톰, 앤, 북, 팝, 캣, 잡, 픽)
/// - 그 밖(모음, r, s, d, g, f, v, x, z, h, w 등) → 받침 없음 (스타, 버스, 베드, 도그)
bool _englishHasBatchim(String word) {
  final isAcronym = word.length <= 4 && word == word.toUpperCase() && word.length > 1;
  if (isAcronym) {
    return 'LMNR'.contains(word[word.length - 1]);
  }
  final w = word.toLowerCase();
  if (w.length == 1) {
    return 'lmnr'.contains(w);
  }
  if (w.endsWith('ng') || w.endsWith('ck')) return true;
  if (w.endsWith('me') || w.endsWith('ne')) return true;
  return 'lmnkptbcq'.contains(w[w.length - 1]);
}

// ---------------------------------------------------------------------------
// 슬롯 치환
// ---------------------------------------------------------------------------

/// `{slot}` 또는 `{slot.조사}` 형식.
final RegExp slotPattern = RegExp(r'\{([a-z_]+)(?:\.([^{}]+))?\}');

/// 문구 안에 쓰인 슬롯 이름 목록(중복 제거, 등장 순서).
List<String> slotsIn(String template) {
  final seen = <String>{};
  for (final m in slotPattern.allMatches(template)) {
    seen.add(m.group(1)!);
  }
  return seen.toList();
}

/// 문구 안에 쓰인 조사 표기 중 지원하지 않는 것 목록. (콘텐츠 검증용)
List<String> unsupportedJosaIn(String template) {
  return [
    for (final m in slotPattern.allMatches(template))
      if (m.group(2) != null && Josa.fromKey(m.group(2)!) == null) m.group(2)!,
  ];
}

/// 슬롯을 값으로 치환한다.
///
/// 값이 없거나 빈 문자열인 슬롯이 하나라도 있으면 null을 돌려준다.
/// (메시지 엔진은 null인 문구를 후보에서 뺀다 — CLAUDE.md 6.2-5)
String? fillTemplate(String template, Map<String, String> values) {
  var missing = false;
  final out = template.replaceAllMapped(slotPattern, (m) {
    final value = values[m.group(1)!];
    if (value == null || value.isEmpty) {
      missing = true;
      return '';
    }
    final josaKey = m.group(2);
    if (josaKey == null) return value;
    final josa = Josa.fromKey(josaKey);
    if (josa == null) {
      missing = true;
      return '';
    }
    return attachJosa(value, josa);
  });
  return missing ? null : out;
}
