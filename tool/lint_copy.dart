// 금지 문구 검사 (CLAUDE.md 9절).
//
// 사용법: dart run tool/lint_copy.dart   (프로젝트 루트에서)
// 문제가 있으면 목록을 출력하고 종료 코드 1로 끝난다.
//
// 검사 범위
// - assets/content/*.json: safety.json forbiddenCopy.scanFields 에 해당하는 키의 값
//   (lintExempt: true 인 객체와 그 아래는 건너뜀)에서 forbiddenCopy.words.
// - messages.json 의 notifications 전체(title, body)는 lockScreenWords 도 검사.
// - lib/ 의 Dart 문자열 리터럴 중 한글이 들어간 것에서 forbiddenCopy.words.
//   (주석은 검사하지 않는다.)
// - lib/features/widget/ 아래 문자열(홈 위젯 문구)은 lockScreenWords 도 검사.

import 'dart:convert';
import 'dart:io';

class CopyIssue {
  CopyIssue(this.location, this.word, this.text);

  final String location;
  final String word;
  final String text;

  @override
  String toString() => '$location: "$word" → $text';
}

class CopyRules {
  CopyRules({required this.scanFields, required this.words, required this.lockScreenWords});

  factory CopyRules.fromSafetyJson(Map<String, dynamic> safety) {
    final f = safety['forbiddenCopy'] as Map<String, dynamic>;
    List<String> list(String k) => (f[k] as List).cast<String>();
    return CopyRules(
      scanFields: list('scanFields').toSet(),
      words: list('words'),
      lockScreenWords: list('lockScreenWords'),
    );
  }

  final Set<String> scanFields;
  final List<String> words;
  final List<String> lockScreenWords;
}

/// [root] 프로젝트 전체를 검사한다.
List<CopyIssue> lintCopy(Directory root) {
  final contentDir = Directory('${root.path}/assets/content');
  final safety = jsonDecode(File('${contentDir.path}/safety.json').readAsStringSync()) as Map<String, dynamic>;
  final rules = CopyRules.fromSafetyJson(safety);

  final issues = <CopyIssue>[];
  final jsonFiles = contentDir.listSync().whereType<File>().where((f) => f.path.endsWith('.json')).toList()
    ..sort((a, b) => a.path.compareTo(b.path));
  for (final file in jsonFiles) {
    final name = file.uri.pathSegments.last;
    final json = jsonDecode(file.readAsStringSync());
    issues.addAll(lintContentJson(name, json, rules));
  }

  final libDir = Directory('${root.path}/lib');
  if (libDir.existsSync()) {
    final dartFiles = libDir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart')).toList()
      ..sort((a, b) => a.path.compareTo(b.path));
    for (final file in dartFiles) {
      final rel = file.path.substring(root.path.length + 1).replaceAll(r'\', '/');
      final lockScreen = rel.startsWith('lib/features/widget/');
      issues.addAll(lintDartSource(rel, file.readAsStringSync(), rules, lockScreen: lockScreen));
    }
  }
  return issues;
}

/// 콘텐츠 JSON 하나를 검사한다.
List<CopyIssue> lintContentJson(String fileName, Object? json, CopyRules rules) {
  final issues = <CopyIssue>[];

  void check(String path, String text, List<String> words) {
    for (final w in words) {
      if (text.contains(w)) issues.add(CopyIssue('$fileName $path', w, text));
    }
  }

  void walk(Object? node, String path, {required bool scan}) {
    if (node is Map<String, dynamic>) {
      if (node['lintExempt'] == true) return;
      for (final e in node.entries) {
        walk(e.value, '$path.${e.key}', scan: rules.scanFields.contains(e.key));
      }
    } else if (node is List) {
      for (var i = 0; i < node.length; i++) {
        walk(node[i], '$path[$i]', scan: scan);
      }
    } else if (node is String && scan) {
      check(path, node, rules.words);
    }
  }

  walk(json, r'$', scan: false);

  // 잠금화면에 보일 수 있는 알림 문구는 더 엄격하게.
  if (fileName == 'messages.json' && json is Map<String, dynamic>) {
    final notifications = (json['notifications'] as List?) ?? const [];
    for (var i = 0; i < notifications.length; i++) {
      final n = notifications[i] as Map<String, dynamic>;
      for (final key in n.keys) {
        final v = n[key];
        if (v is String && key != 'id' && key != 'type' && key != 'category') {
          check(r'$.notifications' '[$i].$key', v, rules.lockScreenWords);
        }
      }
    }
  }
  return issues;
}

final RegExp _hangul = RegExp(r'[가-힣ㄱ-ㆎ]');

/// Dart 소스에서 한글이 든 문자열 리터럴만 검사한다.
List<CopyIssue> lintDartSource(String fileName, String source, CopyRules rules, {bool lockScreen = false}) {
  final words = lockScreen ? [...rules.words, ...rules.lockScreenWords] : rules.words;
  final issues = <CopyIssue>[];
  for (final (line, literal) in dartStringLiterals(source)) {
    if (!_hangul.hasMatch(literal)) continue;
    for (final w in words) {
      if (literal.contains(w)) issues.add(CopyIssue('$fileName:$line', w, literal));
    }
  }
  return issues;
}

/// Dart 소스의 문자열 리터럴 (시작 줄 번호, 내용). 주석은 건너뛴다.
/// 보간(`${...}`) 안의 코드도 문자열 내용으로 취급하지만 검사 목적에는 충분하다.
List<(int, String)> dartStringLiterals(String src) {
  final out = <(int, String)>[];
  var i = 0;
  var line = 1;
  final n = src.length;

  bool startsWithAt(int at, String s) => src.startsWith(s, at);

  while (i < n) {
    final c = src[i];
    if (c == '\n') {
      line++;
      i++;
      continue;
    }
    // 주석
    if (startsWithAt(i, '//')) {
      while (i < n && src[i] != '\n') {
        i++;
      }
      continue;
    }
    if (startsWithAt(i, '/*')) {
      var depth = 1;
      i += 2;
      while (i < n && depth > 0) {
        if (startsWithAt(i, '/*')) {
          depth++;
          i += 2;
        } else if (startsWithAt(i, '*/')) {
          depth--;
          i += 2;
        } else {
          if (src[i] == '\n') line++;
          i++;
        }
      }
      continue;
    }
    // 문자열
    var raw = false;
    var start = i;
    if (c == 'r' && i + 1 < n && (src[i + 1] == "'" || src[i + 1] == '"') && (i == 0 || !_isIdent(src[i - 1]))) {
      raw = true;
      start = i + 1;
    }
    if (src[start] == "'" || src[start] == '"') {
      final q = src[start];
      final triple = startsWithAt(start, q * 3);
      final close = triple ? q * 3 : q;
      var j = start + close.length;
      final buf = StringBuffer();
      final startLine = line;
      while (j < n && !startsWithAt(j, close)) {
        if (!raw && src[j] == r'\' && j + 1 < n) {
          buf.write(src[j + 1]);
          j += 2;
          continue;
        }
        if (src[j] == '\n') {
          line++;
          if (!triple) break; // 닫히지 않은 한 줄 문자열
        }
        buf.write(src[j]);
        j++;
      }
      out.add((startLine, buf.toString()));
      i = j + close.length;
      continue;
    }
    i++;
  }
  return out;
}

bool _isIdent(String ch) => RegExp(r'[A-Za-z0-9_$]').hasMatch(ch);

void main(List<String> args) {
  final root = Directory(args.isNotEmpty ? args.first : Directory.current.path);
  final issues = lintCopy(root);
  if (issues.isEmpty) {
    stdout.writeln('lint_copy: 금지 문구 없음');
    return;
  }
  stderr.writeln('lint_copy: 금지 문구 ${issues.length}건');
  for (final i in issues) {
    stderr.writeln('  $i');
  }
  exitCode = 1;
}
