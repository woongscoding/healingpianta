import 'json_reader.dart';

/// 성장 단계 id. 순서가 곧 인덱스(0~5)다. (CLAUDE.md 6.1)
const List<String> kStageIds = [
  'seed',
  'root',
  'sprout',
  'cotyledon_open',
  'harvest_ready',
  'overgrown',
];

class StageInfo {
  StageInfo({required this.id, required this.index, required this.label, required this.description});

  factory StageInfo.fromJson(JsonReader r) => StageInfo(
        id: r.str('id'),
        index: r.integer('index'),
        label: r.str('label'),
        description: r.str('description'),
      );

  final String id;
  final int index;
  final String label;
  final String description;
}

/// 새싹 모형의 색과 잎 모양.
class SproutSkin {
  SproutSkin({required this.stem, required this.leaf, required this.leafShape, this.vessel});

  factory SproutSkin.fromJson(JsonReader r) => SproutSkin(
        stem: parseHexColor(r, 'stem'),
        leaf: parseHexColor(r, 'leaf'),
        leafShape: r.str('leafShape'),
        vessel: r.strOpt('vessel'),
      );

  /// ARGB
  final int stem;

  /// ARGB
  final int leaf;

  /// heart | round | heart_large
  final String leafShape;

  /// 레벨 2 이상 식물의 그릇 종류(예: glass). 새싹은 null.
  final String? vessel;
}

class Species {
  Species({
    required this.id,
    required this.label,
    required this.family,
    required this.stageDays,
    required this.harvestHeightMinCm,
    required this.harvestHeightMaxCm,
    required this.normalLook,
    required this.skin,
    required this.defaultTip,
  });

  factory Species.fromJson(JsonReader r) {
    final heights = r.numList('harvestHeightCm');
    if (heights.length != 2) r.fail('harvestHeightCm', '[최소, 최대] 두 값이어야 함');
    return Species(
      id: r.str('id'),
      label: r.str('label'),
      family: r.str('family'),
      stageDays: r.intMap('stageDays'),
      harvestHeightMinCm: heights[0].toDouble(),
      harvestHeightMaxCm: heights[1].toDouble(),
      normalLook: r.str('normalLook'),
      skin: SproutSkin.fromJson(r.obj('skin')),
      defaultTip: r.str('defaultTip'),
    );
  }

  final String id;
  final String label;
  final String family;

  /// 단계 id → 그 단계가 시작되는 날(심은 날 = 0).
  final Map<String, int> stageDays;
  final double harvestHeightMinCm;
  final double harvestHeightMaxCm;
  final String normalLook;
  final SproutSkin skin;
  final String defaultTip;
}

class MoldGuide {
  MoldGuide({required this.title, required this.steps});

  factory MoldGuide.fromJson(JsonReader r) =>
      MoldGuide(title: r.str('title'), steps: r.strList('steps', allowEmpty: false));

  final String title;
  final List<String> steps;
}

class IssueInfo {
  IssueInfo({required this.id, required this.label, this.message, this.showMoldGuide = false});

  factory IssueInfo.fromJson(String id, JsonReader r) => IssueInfo(
        id: id,
        label: r.str('label'),
        message: r.strOpt('message'),
        showMoldGuide: r.boolOr('showMoldGuide', false),
      );

  final String id;
  final String label;
  final String? message;
  final bool showMoldGuide;
}

class SpeciesContent {
  SpeciesContent({
    required this.stages,
    required this.species,
    required this.mismatchLabels,
    required this.moldGuide,
    required this.issues,
  });

  factory SpeciesContent.fromJson(Object? json) {
    final r = JsonReader.root('species.json', json);
    return SpeciesContent(
      stages: [for (final s in r.objList('stages')) StageInfo.fromJson(s)],
      species: [for (final s in r.objList('species')) Species.fromJson(s)],
      mismatchLabels: r.strMap('mismatchLabels'),
      moldGuide: MoldGuide.fromJson(r.obj('moldGuide')),
      issues: {
        for (final e in r.objMap('issues').entries) e.key: IssueInfo.fromJson(e.key, e.value),
      },
    );
  }

  final List<StageInfo> stages;
  final List<Species> species;
  final Map<String, String> mismatchLabels;
  final MoldGuide moldGuide;
  final Map<String, IssueInfo> issues;

  Species? speciesById(String id) {
    for (final s in species) {
      if (s.id == id) return s;
    }
    return null;
  }

  List<String> validate() {
    final errors = <String>[];
    final stageIds = [for (final s in stages) s.id];
    if (stageIds.join(',') != kStageIds.join(',')) {
      errors.add('species.json stages 순서는 ${kStageIds.join(' → ')} 이어야 함');
    }
    for (var i = 0; i < stages.length; i++) {
      if (stages[i].index != i) errors.add('species.json stages[$i].index 는 $i 이어야 함');
    }
    errors.addAll(duplicateIds('species.json species', [for (final s in species) s.id]));
    for (final s in species) {
      final where = 'species.json species(${s.id})';
      for (final id in kStageIds) {
        if (!s.stageDays.containsKey(id)) errors.add('$where.stageDays 에 $id 없음');
      }
      for (final k in s.stageDays.keys) {
        if (!kStageIds.contains(k)) errors.add('$where.stageDays 에 알 수 없는 단계 $k');
      }
      var prev = -1;
      for (final id in kStageIds) {
        final d = s.stageDays[id];
        if (d == null) continue;
        if (d < prev) errors.add('$where.stageDays 가 단계 순서대로 늘어나지 않음 ($id)');
        prev = d;
      }
      if (s.stageDays['seed'] != null && s.stageDays['seed'] != 0) {
        errors.add('$where.stageDays.seed 는 0 이어야 함');
      }
      if (s.harvestHeightMinCm <= 0 || s.harvestHeightMinCm > s.harvestHeightMaxCm) {
        errors.add('$where.harvestHeightCm 범위가 잘못됨');
      }
      if (!const {'heart', 'round'}.contains(s.skin.leafShape)) {
        errors.add('$where.skin.leafShape 는 heart 또는 round');
      }
    }
    for (final s in species) {
      if (!mismatchLabels.containsKey(s.id)) {
        errors.add('species.json mismatchLabels 에 ${s.id} 없음');
      }
    }
    if (!issues.containsKey('none') || !issues.containsKey('mold_suspected')) {
      errors.add('species.json issues 에 none, mold_suspected 는 반드시 있어야 함');
    }
    return errors;
  }
}

/// 목록 안에서 중복된 id를 찾아 오류 문장으로 돌려준다.
List<String> duplicateIds(String where, Iterable<String> ids) {
  final seen = <String>{};
  return [
    for (final id in ids)
      if (!seen.add(id)) '$where: id "$id" 중복',
  ];
}
