import 'json_reader.dart';
import 'species_content.dart' show SproutSkin, duplicateIds;

/// 레벨 2 이상 식물의 프로필 (단계는 주 단위).
class LevelPlantProfile {
  LevelPlantProfile({
    required this.stages,
    required this.stageWeeks,
    required this.normalLook,
    required this.skin,
    required this.defaultTip,
  });

  factory LevelPlantProfile.fromJson(JsonReader r) => LevelPlantProfile(
        stages: r.strList('stages', allowEmpty: false),
        stageWeeks: r.intMap('stageWeeks'),
        normalLook: r.str('normalLook'),
        skin: SproutSkin.fromJson(r.obj('skin')),
        defaultTip: r.str('defaultTip'),
      );

  final List<String> stages;
  final Map<String, int> stageWeeks;
  final String normalLook;
  final SproutSkin skin;
  final String defaultTip;
}

class Level {
  Level({
    required this.level,
    required this.id,
    required this.title,
    required this.plants,
    required this.skills,
    required this.behaviors,
    required this.durationNote,
    required this.suggestNextWhen,
    required this.season,
    required this.seasonStartMonths,
    required this.implemented,
    this.plantLabel,
    this.profile,
  });

  factory Level.fromJson(JsonReader r) => Level(
        level: r.integer('level'),
        id: r.str('id'),
        title: r.str('title'),
        plants: r.strList('plants', allowEmpty: false),
        plantLabel: r.strOpt('plantLabel'),
        skills: r.strList('skills'),
        behaviors: r.strList('behaviors'),
        durationNote: r.str('durationNote'),
        suggestNextWhen: r.has('suggestNextWhen') ? r.intMap('suggestNextWhen') : const {},
        season: r.str('season'),
        seasonStartMonths: r.has('seasonStartMonths') ? r.intList('seasonStartMonths') : const [],
        implemented: r.boolean('implemented'),
        profile: r.has('profile') ? LevelPlantProfile.fromJson(r.obj('profile')) : null,
      );

  final int level;
  final String id;
  final String title;
  final List<String> plants;
  final String? plantLabel;
  final List<String> skills;
  final List<String> behaviors;
  final String durationNote;

  /// 다음 레벨을 제안하는 조건. 비어 있으면 마지막 레벨.
  /// 키: harvestCount, orCareDays, careDaysSinceLevel
  final Map<String, int> suggestNextWhen;

  /// all | spring_summer
  final String season;
  final List<int> seasonStartMonths;
  final bool implemented;
  final LevelPlantProfile? profile;

  bool isOpenInMonth(int month) =>
      season == 'all' || seasonStartMonths.isEmpty || seasonStartMonths.contains(month);
}

class GardenStage {
  GardenStage({required this.fromLevel, required this.id, required this.label});

  factory GardenStage.fromJson(JsonReader r) =>
      GardenStage(fromLevel: r.integer('fromLevel'), id: r.str('id'), label: r.str('label'));

  final int fromLevel;
  final String id;
  final String label;
}

const Set<String> kSuggestConditionKeys = {'harvestCount', 'orCareDays', 'careDaysSinceLevel'};

class LevelsContent {
  LevelsContent({required this.levels, required this.skillTree, required this.gardenStages});

  factory LevelsContent.fromJson(Object? json) {
    final r = JsonReader.root('levels.json', json);
    return LevelsContent(
      levels: [for (final l in r.objList('levels')) Level.fromJson(l)],
      skillTree: r.strList('skillTree', allowEmpty: false),
      gardenStages: [for (final g in r.objList('gardenStages')) GardenStage.fromJson(g)],
    );
  }

  final List<Level> levels;
  final List<String> skillTree;
  final List<GardenStage> gardenStages;

  Level? byNumber(int level) {
    for (final l in levels) {
      if (l.level == level) return l;
    }
    return null;
  }

  List<String> validate({required Set<String> speciesIds}) {
    final errors = duplicateIds('levels.json', levels.map((l) => l.id));
    for (var i = 0; i < levels.length; i++) {
      final l = levels[i];
      if (l.level != i + 1) errors.add('levels.json levels[$i].level 은 ${i + 1} 이어야 함');
      for (final k in l.suggestNextWhen.keys) {
        if (!kSuggestConditionKeys.contains(k)) {
          errors.add('levels.json ${l.id}.suggestNextWhen: 알 수 없는 조건 $k');
        }
      }
      if (!const {'all', 'spring_summer'}.contains(l.season)) {
        errors.add('levels.json ${l.id}.season 은 all 또는 spring_summer');
      }
      if (l.season != 'all' && l.seasonStartMonths.isEmpty) {
        errors.add('levels.json ${l.id}: 계절 제한이 있으면 seasonStartMonths 필요');
      }
      for (final m in l.seasonStartMonths) {
        if (m < 1 || m > 12) errors.add('levels.json ${l.id}.seasonStartMonths 는 1~12');
      }
      if (l.level >= 2 && l.implemented && l.profile == null) {
        errors.add('levels.json ${l.id}: 구현된 레벨 2 이상은 profile 필요');
      }
      final p = l.profile;
      if (p != null) {
        for (final s in p.stages) {
          if (!p.stageWeeks.containsKey(s)) errors.add('levels.json ${l.id}.profile.stageWeeks 에 $s 없음');
        }
      }
      if (i < levels.length - 1 && l.suggestNextWhen.isEmpty) {
        errors.add('levels.json ${l.id}: 마지막이 아닌 레벨은 suggestNextWhen 필요');
      }
    }
    final level1 = byNumber(1);
    if (level1 == null || !level1.implemented) {
      errors.add('levels.json 레벨 1은 반드시 구현돼 있어야 함');
    } else {
      for (final s in level1.plants) {
        if (!speciesIds.contains(s)) errors.add('levels.json 레벨 1 plants 의 $s 가 species.json 에 없음');
      }
    }
    for (final g in gardenStages) {
      if (byNumber(g.fromLevel) == null) errors.add('levels.json gardenStages ${g.id}: 없는 레벨');
    }
    return errors;
  }
}
