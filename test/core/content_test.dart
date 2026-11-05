import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:healingpianta/core/content/app_content.dart';

Map<String, String> readSources() => {
      for (final f in kContentFiles) f: File('$kContentDir/$f').readAsStringSync(),
    };

/// 원본을 고쳐 볼 때 쓰는 도우미.
Map<String, String> patched(String file, void Function(Map<String, dynamic> json) edit) {
  final sources = readSources();
  final json = jsonDecode(sources[file]!) as Map<String, dynamic>;
  edit(json);
  return {...sources, file: jsonEncode(json)};
}

void main() {
  group('실제 콘텐츠 7개 파일', () {
    late AppContent content;

    setUpAll(() {
      content = AppContent.fromSources(readSources());
    });

    test('파일 목록이 assets/content 와 같음', () {
      final onDisk = Directory(kContentDir)
          .listSync()
          .whereType<File>()
          .map((f) => f.uri.pathSegments.last)
          .where((n) => n.endsWith('.json'))
          .toSet();
      expect(onDisk, kContentFiles.toSet());
    });

    test('검증 오류 없음', () {
      expect(content.validate(), isEmpty);
    });

    test('species.json', () {
      expect(content.species.stages.map((s) => s.id), kStageIds);
      expect(content.species.species.length, 6);
      final radish = content.species.speciesById('radish')!;
      expect(radish.label, '무순');
      expect(radish.stageDays['harvest_ready'], 5);
      expect(radish.skin.stem, 0xFFEEF5E1);
      expect(radish.harvestHeightMaxCm, 7);
      expect(content.species.issues['mold_suspected']!.showMoldGuide, isTrue);
      expect(content.species.moldGuide.steps, isNotEmpty);
    });

    test('missions.json', () {
      expect(content.missions.ladders.map((l) => l.id), ['space', 'body', 'meal', 'connection', 'sleep']);
      final water = content.missions.missionById('body_1')!;
      expect(water.minEnergy, 1);
      expect(water.ladderId, 'body');
      expect(water.category, 'body'); // 사다리 category 상속
      expect(water.availableAt('late_night'), isTrue); // time 비어 있으면 언제든
      expect(content.missions.missionById('meal_4')!.requires, 'harvested');
      expect(content.missions.plantPair.every((m) => m.isPlantPair), isTrue);
      expect(content.missions.rest.id, 'rest');
    });

    test('messages.json', () {
      final m = content.messages;
      expect(m.contexts, contains('return_after_absence'));
      expect(m.timeRangeAt(5 * 60), 'morning');
      expect(m.timeRangeAt(11 * 60 + 59), 'morning');
      expect(m.timeRangeAt(12 * 60), 'afternoon');
      expect(m.timeRangeAt(22 * 60 + 59), 'evening');
      expect(m.timeRangeAt(23 * 60), 'late_night');
      expect(m.timeRangeAt(0), 'late_night');
      expect(m.timeRangeAt(4 * 60 + 59), 'late_night');
      expect(m.home.length, greaterThan(40));
      expect(m.personal.firstWhere((p) => p.id == 'p_1').requires, ['action', 'delta']);
      expect(m.afterAction.keys, kAfterActionKinds);
      expect(m.notifications.map((n) => n.type).toSet(), kNotificationTypes);
    });

    test('recipes.json — 익혀 먹는 메뉴 먼저', () {
      final ordered = content.recipes.ordered;
      expect(ordered.first.cooked, isTrue);
      expect(content.recipes.safetySteps, isNotEmpty);
    });

    test('kits.json', () {
      expect(content.kits.kitById('kit_brassica_4')!.isMultiSpecies, isTrue);
      expect(content.kits.kitById('kit_own'), isNotNull);
      expect(content.kitDisclosure, contains('쿠팡 파트너스'));
    });

    test('levels.json', () {
      expect(content.levels.levels.length, 7);
      expect(content.levels.byNumber(1)!.suggestNextWhen, {'harvestCount': 2, 'orCareDays': 14});
      expect(content.levels.byNumber(2)!.profile!.stages.first, 'cutting');
      final fruits = content.levels.byNumber(6)!;
      expect(fruits.isOpenInMonth(4), isTrue);
      expect(fruits.isOpenInMonth(11), isFalse);
      expect(content.levels.byNumber(3)!.implemented, isFalse);
    });

    test('safety.json', () {
      final s = content.safety;
      expect(s.ageGate.minAge, 19);
      expect(s.helpScreen.contacts.map((c) => c.value), containsAll(['109', '119']));
      expect(s.supportMode.consecutiveMoodOne, 3);
      expect(s.supportMode.lowMoodCount, 4);
      expect(s.supportMode.exitRequiredCount, 2);
      expect(s.crisisKeywords, isNotEmpty);
      expect(s.forbiddenCopy.words, contains('치료'));
      expect(s.consents.keys, containsAll(['sensitive', 'photo']));
    });
  });

  group('구조 오류 감지', () {
    test('필수 값이 없으면 파일·경로가 담긴 오류', () {
      final src = patched('species.json', (j) => (j['species'] as List).first.remove('defaultTip'));
      expect(
        () => AppContent.fromSources(src),
        throwsA(isA<ContentFormatException>()
            .having((e) => e.file, 'file', 'species.json')
            .having((e) => e.path, 'path', r'$.species[0].defaultTip')),
      );
    });

    test('타입이 틀리면 오류', () {
      final src = patched('missions.json', (j) {
        ((j['ladders'] as List).first['steps'] as List).first['minEnergy'] = '1';
      });
      expect(() => AppContent.fromSources(src), throwsA(isA<ContentFormatException>()));
    });

    test('JSON 문법 오류', () {
      final src = {...readSources(), 'kits.json': '{ "version": 1, '};
      expect(
        () => AppContent.fromSources(src),
        throwsA(isA<ContentFormatException>().having((e) => e.file, 'file', 'kits.json')),
      );
    });

    test('파일이 빠지면 오류', () {
      final src = readSources()..remove('levels.json');
      expect(() => AppContent.fromSources(src), throwsA(isA<ContentFormatException>()));
    });

    test('잘못된 색 형식', () {
      final src = patched('species.json', (j) => (j['species'] as List).first['skin']['leaf'] = 'green');
      expect(() => AppContent.fromSources(src), throwsA(isA<ContentFormatException>()));
    });
  });

  group('의미 오류 감지 (validate)', () {
    List<String> errorsOf(Map<String, String> src) => AppContent.fromSources(src).validate();

    test('정의되지 않은 슬롯', () {
      final src = patched('messages.json', (j) => (j['home'] as List).first['text'] = '{nickname} 안녕');
      expect(errorsOf(src), contains(contains('정의되지 않은 슬롯 {nickname}')));
    });

    test('지원하지 않는 조사', () {
      final src = patched('messages.json', (j) => (j['home'] as List).first['text'] = '{name.의} 자리');
      expect(errorsOf(src), contains(contains('지원하지 않는 조사')));
    });

    test('알 수 없는 context', () {
      final src = patched('messages.json', (j) => (j['home'] as List).first['context'] = ['midnight']);
      expect(errorsOf(src), contains(contains('알 수 없는 context midnight')));
    });

    test('personal 문구의 슬롯이 requires 에 없음', () {
      final src = patched('messages.json', (j) => (j['personal'] as List).first['requires'] = ['action']);
      expect(errorsOf(src), contains(contains('{delta} 가 requires 에 없음')));
    });

    test('시간대가 하루를 다 덮지 않음', () {
      final src = patched('messages.json', (j) => j['timeRanges']['morning'] = '06:00-11:59');
      expect(errorsOf(src), contains(contains('timeRanges')));
    });

    test('stageDays 순서가 거꾸로', () {
      final src = patched('species.json', (j) => (j['species'] as List).first['stageDays']['sprout'] = 0);
      expect(errorsOf(src), contains(contains('단계 순서대로')));
    });

    test('키트가 없는 종류를 가리킴', () {
      final src = patched('kits.json', (j) => (j['kits'] as List).first['species'] = ['carrot']);
      expect(errorsOf(src), contains(contains('알 수 없는 species carrot')));
    });

    test('미션 에너지 범위', () {
      final src = patched('missions.json', (j) => (j['plantPair'] as List).first['minEnergy'] = 4);
      expect(errorsOf(src), contains(contains('minEnergy 는 1~3')));
    });

    test('사다리 단계 건너뜀', () {
      final src = patched('missions.json', (j) => ((j['ladders'] as List).first['steps'] as List).removeAt(1));
      expect(errorsOf(src), contains(contains('step 은 1부터 차례로')));
    });

    test('id 중복', () {
      final src = patched('recipes.json', (j) => (j['recipes'] as List)[1]['id'] = 'egg_scramble');
      expect(errorsOf(src), contains(contains('"egg_scramble" 중복')));
    });

    test('연령 기준이 19 미만', () {
      final src = patched('safety.json', (j) => j['ageGate']['minAge'] = 14);
      expect(errorsOf(src), contains(contains('minAge')));
    });

    test('109 연락처 누락', () {
      final src = patched('safety.json', (j) {
        (j['helpScreen']['contacts'] as List).removeWhere((c) => c['value'] == '109');
      });
      expect(errorsOf(src), contains(contains('109')));
    });

    test('validated() 는 오류가 있으면 예외', () {
      final src = patched('safety.json', (j) => j['ageGate']['minAge'] = 14);
      expect(() => AppContent.fromSources(src).validated(), throwsA(isA<ContentValidationException>()));
    });
  });
}
