import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/lint_copy.dart';

void main() {
  final rules = CopyRules(
    scanFields: {'text', 'title', 'body', 'steps'},
    words: ['치료', '연속', '놓쳤'],
    lockScreenWords: ['기분', '우울'],
  );

  test('실제 프로젝트(콘텐츠 + lib)에 금지 문구 없음', () {
    final issues = lintCopy(Directory.current);
    expect(issues, isEmpty, reason: issues.join('\n'));
  });

  group('콘텐츠 JSON', () {
    test('scanFields 값에서 금지어를 찾음', () {
      final issues = lintContentJson('x.json', {
        'home': [
          {'id': 'a', 'text': '3일 연속 왔어요'},
        ],
      }, rules);
      expect(issues.single.word, '연속');
      expect(issues.single.location, contains(r'$.home[0].text'));
    });

    test('배열 값(steps)도 검사', () {
      final issues = lintContentJson('x.json', {
        'guide': {
          'steps': ['괜찮아요', '물 주는 걸 놓쳤어요'],
        },
      }, rules);
      expect(issues.single.word, '놓쳤');
    });

    test('scanFields 가 아닌 키는 건너뜀', () {
      final issues = lintContentJson('x.json', {'note': '치료 아님', 'id': '연속'}, rules);
      expect(issues, isEmpty);
    });

    test('lintExempt 객체는 건너뜀', () {
      final issues = lintContentJson('x.json', {
        'disclaimer': {'lintExempt': true, 'text': '진단이나 치료를 대신하지 않아요'},
      }, rules);
      expect(issues, isEmpty);
    });

    test('알림 문구는 잠금화면 단어도 검사', () {
      final json = {
        'home': [
          {'id': 'h', 'text': '기분이 어때요?'},
        ],
        'notifications': [
          {'id': 'n', 'type': 'evening', 'category': 'plant', 'title': '새싹', 'body': '오늘 기분은 어때요?'},
        ],
      };
      final issues = lintContentJson('messages.json', json, rules);
      // home 은 잠금화면 검사 대상이 아님 → 알림 body 1건만
      expect(issues.single.location, contains('notifications[0].body'));
      expect(issues.single.word, '기분');
    });
  });

  group('Dart 소스', () {
    test('한글 문자열 리터럴의 금지어', () {
      const src = '''
final a = '새싹을 놓쳤어요';
final b = "괜찮아요";
''';
      final issues = lintDartSource('lib/a.dart', src, rules);
      expect(issues.single.location, 'lib/a.dart:1');
    });

    test('주석은 검사하지 않음', () {
      const src = '''
// 치료 표현 금지
/* 연속 기록 금지 */
/// 놓쳤 같은 말
final ok = '좋아요'; // 치료
''';
      expect(lintDartSource('lib/a.dart', src, rules), isEmpty);
    });

    test('URL 안의 // 는 주석이 아님', () {
      const src = "final u = 'https://x.kr/치료';";
      expect(lintDartSource('lib/a.dart', src, rules), hasLength(1));
    });

    test('세 따옴표 문자열과 이스케이프', () {
      const src = "final t = '''\n첫 줄\n연속 기록\n''';\nfinal e = '그건 \\'연속\\'';";
      final issues = lintDartSource('lib/a.dart', src, rules);
      expect(issues.map((i) => i.location), ['lib/a.dart:1', 'lib/a.dart:5']);
    });

    test('홈 위젯 문구는 잠금화면 단어도 검사', () {
      const src = "final w = '오늘 기분 체크';";
      expect(lintDartSource('lib/a.dart', src, rules), isEmpty);
      expect(lintDartSource('lib/features/widget/w.dart', src, rules, lockScreen: true), hasLength(1));
    });
  });

  test('safety.json 에서 규칙을 읽음', () {
    final safety = jsonDecode(File('assets/content/safety.json').readAsStringSync()) as Map<String, dynamic>;
    final r = CopyRules.fromSafetyJson(safety);
    expect(r.words, contains('치료'));
    expect(r.lockScreenWords, contains('우울'));
    expect(r.scanFields, contains('text'));
  });
}
