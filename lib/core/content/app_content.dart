import 'dart:convert';

import 'json_reader.dart';
import 'kits_content.dart';
import 'levels_content.dart';
import 'messages_content.dart';
import 'missions_content.dart';
import 'recipes_content.dart';
import 'safety_content.dart';
import 'species_content.dart';

export 'json_reader.dart' show ContentFormatException;
export 'kits_content.dart';
export 'levels_content.dart';
export 'messages_content.dart';
export 'missions_content.dart';
export 'recipes_content.dart';
export 'safety_content.dart';
export 'species_content.dart';

/// `assets/content` 안의 파일 이름. 이 7개가 전부다.
const List<String> kContentFiles = [
  'species.json',
  'missions.json',
  'messages.json',
  'recipes.json',
  'kits.json',
  'levels.json',
  'safety.json',
];

const String kContentDir = 'assets/content';

/// 콘텐츠 검증에 실패했을 때.
class ContentValidationException implements Exception {
  ContentValidationException(this.errors);

  final List<String> errors;

  @override
  String toString() => 'ContentValidationException:\n  ${errors.join('\n  ')}';
}

/// 앱의 모든 문구·데이터. 앱 시작 시 한 번 읽고 바꾸지 않는다.
class AppContent {
  AppContent({
    required this.species,
    required this.missions,
    required this.messages,
    required this.recipes,
    required this.kits,
    required this.levels,
    required this.safety,
  });

  /// 파일 이름 → JSON 문자열에서 만든다. 구조가 틀리면 [ContentFormatException].
  factory AppContent.fromSources(Map<String, String> sources) {
    Object? decode(String file) {
      final src = sources[file];
      if (src == null) throw ContentFormatException(file, r'$', '파일이 없음');
      try {
        return jsonDecode(src);
      } on FormatException catch (e) {
        throw ContentFormatException(file, r'$', 'JSON 문법 오류: ${e.message}');
      }
    }

    return AppContent(
      species: SpeciesContent.fromJson(decode('species.json')),
      missions: MissionsContent.fromJson(decode('missions.json')),
      messages: MessagesContent.fromJson(decode('messages.json')),
      recipes: RecipesContent.fromJson(decode('recipes.json')),
      kits: KitsContent.fromJson(decode('kits.json')),
      levels: LevelsContent.fromJson(decode('levels.json')),
      safety: SafetyContent.fromJson(decode('safety.json')),
    );
  }

  final SpeciesContent species;
  final MissionsContent missions;
  final MessagesContent messages;
  final RecipesContent recipes;
  final KitsContent kits;
  final LevelsContent levels;
  final SafetyContent safety;

  /// 파일 사이의 참조까지 포함한 의미 검증. 문제 목록을 돌려준다(없으면 빈 목록).
  List<String> validate() {
    final speciesIds = {for (final s in species.species) s.id};
    final errors = <String>[
      ...species.validate(),
      ...messages.validate(),
      ...missions.validate(timeRanges: messages.timeRanges.keys.toSet()),
      ...recipes.validate(),
      ...kits.validate(speciesIds: speciesIds),
      ...levels.validate(speciesIds: speciesIds),
      ...safety.validate(),
    ];
    if (safety.raw[kits.disclosureKey] is! String) {
      errors.add('kits.json disclosureKey(${kits.disclosureKey}) 가 safety.json 에 없음');
    }
    return errors;
  }

  /// [validate]에 문제가 있으면 [ContentValidationException]을 던진다.
  AppContent validated() {
    final errors = validate();
    if (errors.isNotEmpty) throw ContentValidationException(errors);
    return this;
  }

  /// 대가성 문구 (kits.json의 disclosureKey로 safety.json에서 찾음).
  String get kitDisclosure => safety.raw[kits.disclosureKey] as String;
}
