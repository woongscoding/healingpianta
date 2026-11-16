import 'json_reader.dart';
import 'species_content.dart' show duplicateIds;

/// 행동 사다리의 한 칸, 새싹 짝 행동, 또는 배송 대기 모드의 준비 행동.
class Mission {
  Mission({
    required this.id,
    required this.text,
    required this.minEnergy,
    required this.minutes,
    required this.time,
    required this.category,
    required this.values,
    this.ladderId,
    this.step,
    this.requires,
    this.isPrep = false,
  });

  factory Mission.fromJson(
    JsonReader r, {
    String? ladderId,
    String? ladderCategory,
    bool isPrep = false,
  }) =>
      Mission(
        id: r.str('id'),
        text: r.str('text'),
        minEnergy: r.integer('minEnergy'),
        minutes: r.integer('minutes'),
        time: r.strList('time'),
        category: r.strOpt('category') ?? ladderCategory ?? r.fail('category', '필수 값이 없음'),
        values: r.strList('values'),
        ladderId: ladderId,
        step: ladderId == null ? null : r.integer('step'),
        requires: r.strOpt('requires'),
        isPrep: isPrep,
      );

  final String id;
  final String text;
  final int minEnergy;
  final int minutes;

  /// 제안 가능한 시간대. 비어 있으면 언제든.
  final List<String> time;

  /// 무엇을 하는 행동인가 (행동 종류, 미션당 1개).
  final String category;

  /// 왜 하는가 (사용자 가치 id, 미션당 0개 이상). CLAUDE.md 6.3.
  final List<String> values;

  /// 사다리 미션이면 사다리 id, 새싹 짝 행동·준비 행동이면 null.
  final String? ladderId;
  final int? step;

  /// 예: `harvested` — 수확한 적이 있어야 제안.
  final String? requires;

  /// 배송 대기 모드의 준비 행동(`prep`)인지.
  final bool isPrep;

  bool get isPlantPair => ladderId == null && !isPrep;

  bool availableAt(String timeRange) => time.isEmpty || time.contains(timeRange);
}

class Ladder {
  Ladder({required this.id, required this.label, required this.category, required this.steps});

  factory Ladder.fromJson(JsonReader r) {
    final id = r.str('id');
    final category = r.str('category');
    return Ladder(
      id: id,
      label: r.str('label'),
      category: category,
      steps: [
        for (final s in r.objList('steps'))
          Mission.fromJson(s, ladderId: id, ladderCategory: category),
      ],
    );
  }

  final String id;
  final String label;
  final String category;
  final List<Mission> steps;
}

/// 온보딩에서 고르는 가치 하나. `users.values`에는 [id]를 저장한다.
class ValueOption {
  ValueOption({
    required this.id,
    required this.label,
    required this.description,
    required this.hiddenInOnboarding,
  });

  factory ValueOption.fromJson(JsonReader r) => ValueOption(
        id: r.str('id'),
        label: r.str('label'),
        description: r.str('description'),
        hiddenInOnboarding: r.boolOr('hiddenInOnboarding', false),
      );

  final String id;
  final String label;
  final String description;

  /// 온보딩 가치 목록에서 숨기는지 (예: 전용 사다리가 아직 없는 가치).
  final bool hiddenInOnboarding;
}

class RestOption {
  RestOption({required this.id, required this.text, required this.description});

  factory RestOption.fromJson(JsonReader r) =>
      RestOption(id: r.str('id'), text: r.str('text'), description: r.str('description'));

  final String id;
  final String text;
  final String description;
}

class MissionsContent {
  MissionsContent({
    required this.rest,
    required this.ladders,
    required this.plantPair,
    required this.values,
    required this.prep,
    this.valuesStatus,
    this.prepStatus,
    this.valueTagsStatus,
  });

  factory MissionsContent.fromJson(Object? json) {
    final r = JsonReader.root('missions.json', json);
    final valuesSection = r.obj('values');
    final prepSection = r.obj('prep');
    return MissionsContent(
      rest: RestOption.fromJson(r.obj('rest')),
      ladders: [for (final l in r.objList('ladders')) Ladder.fromJson(l)],
      plantPair: [for (final p in r.objList('plantPair')) Mission.fromJson(p)],
      values: [for (final v in valuesSection.objList('items')) ValueOption.fromJson(v)],
      prep: [for (final p in prepSection.objList('items')) Mission.fromJson(p, isPrep: true)],
      valuesStatus: valuesSection.strOpt('status'),
      prepStatus: prepSection.strOpt('status'),
      valueTagsStatus: r.strOpt('valueTagsStatus'),
    );
  }

  final RestOption rest;
  final List<Ladder> ladders;
  final List<Mission> plantPair;

  /// 가치 목록 (CLAUDE.md 6.3).
  final List<ValueOption> values;

  /// 배송 대기 모드 준비 행동 (CLAUDE.md 7절 6번). 일반 행동 제안에는 섞지 않는다.
  final List<Mission> prep;

  /// 초안 표시. 예: `draft_needs_expert_review`. 동작에는 쓰지 않는다.
  final String? valuesStatus;
  final String? prepStatus;
  final String? valueTagsStatus;

  /// 일반 행동 제안 대상: 사다리 미션 + 새싹 짝 행동 (준비 행동 제외).
  Iterable<Mission> get allMissions sync* {
    for (final l in ladders) {
      yield* l.steps;
    }
    yield* plantPair;
  }

  /// 온보딩에서 보여줄 가치.
  List<ValueOption> get onboardingValues => [for (final v in values) if (!v.hiddenInOnboarding) v];

  ValueOption? valueById(String id) {
    for (final v in values) {
      if (v.id == id) return v;
    }
    return null;
  }

  /// 준비 행동까지 포함해 찾는다 (행동 기록에 준비 행동 id도 남기 때문).
  Mission? missionById(String id) {
    for (final m in [...allMissions, ...prep]) {
      if (m.id == id) return m;
    }
    return null;
  }

  Ladder? ladderById(String id) {
    for (final l in ladders) {
      if (l.id == id) return l;
    }
    return null;
  }

  List<String> validate({required Set<String> timeRanges}) {
    final everyMission = [...allMissions, ...prep];
    final valueIds = {for (final v in values) v.id};
    final errors = <String>[
      ...duplicateIds('missions.json ladders', [for (final l in ladders) l.id]),
      ...duplicateIds('missions.json missions', [rest.id, ...everyMission.map((m) => m.id)]),
      ...duplicateIds('missions.json values', [for (final v in values) v.id]),
    ];
    for (final l in ladders) {
      for (var i = 0; i < l.steps.length; i++) {
        if (l.steps[i].step != i + 1) {
          errors.add('missions.json ladder(${l.id}) step 은 1부터 차례로 (${l.steps[i].id})');
        }
      }
    }
    for (final m in everyMission) {
      if (m.minEnergy < 1 || m.minEnergy > 3) {
        errors.add('missions.json ${m.id}.minEnergy 는 1~3');
      }
      if (m.minutes <= 0) errors.add('missions.json ${m.id}.minutes 는 양수');
      for (final t in m.time) {
        if (!timeRanges.contains(t)) errors.add('missions.json ${m.id}.time 에 알 수 없는 시간대 $t');
      }
      if (m.requires != null && m.requires != 'harvested') {
        errors.add('missions.json ${m.id}.requires 는 harvested 만 지원');
      }
      for (final v in m.values) {
        if (!valueIds.contains(v)) errors.add('missions.json ${m.id}.values 에 알 수 없는 가치 $v');
      }
    }
    // 에너지 1에서도 언제나 고를 수 있는 새싹 짝 행동이 있어야 한다(6.3).
    if (!plantPair.any((m) => m.minEnergy == 1)) {
      errors.add('missions.json plantPair 에 minEnergy 1 행동이 없음');
    }
    // 온보딩에서 고를 수 있는 가치마다 에너지 1로 할 수 있는 미션이 있어야 한다(6.3).
    for (final v in onboardingValues) {
      if (!allMissions.any((m) => m.minEnergy == 1 && m.values.contains(v.id))) {
        errors.add('missions.json 가치 ${v.id} 에 minEnergy 1 미션이 없음');
      }
    }
    // 배송 대기 모드도 에너지 1인 날에 돌아가야 한다(7절 6번).
    if (!prep.any((m) => m.minEnergy == 1)) {
      errors.add('missions.json prep 에 minEnergy 1 행동이 없음');
    }
    return errors;
  }
}
