import 'json_reader.dart';
import 'species_content.dart' show duplicateIds;

/// 행동 사다리의 한 칸 또는 새싹 짝 행동.
class Mission {
  Mission({
    required this.id,
    required this.text,
    required this.minEnergy,
    required this.minutes,
    required this.time,
    required this.category,
    this.ladderId,
    this.step,
    this.requires,
  });

  factory Mission.fromJson(
    JsonReader r, {
    String? ladderId,
    String? ladderCategory,
  }) =>
      Mission(
        id: r.str('id'),
        text: r.str('text'),
        minEnergy: r.integer('minEnergy'),
        minutes: r.integer('minutes'),
        time: r.strList('time'),
        category: r.strOpt('category') ?? ladderCategory ?? r.fail('category', '필수 값이 없음'),
        ladderId: ladderId,
        step: ladderId == null ? null : r.integer('step'),
        requires: r.strOpt('requires'),
      );

  final String id;
  final String text;
  final int minEnergy;
  final int minutes;

  /// 제안 가능한 시간대. 비어 있으면 언제든.
  final List<String> time;
  final String category;

  /// 사다리 미션이면 사다리 id, 새싹 짝 행동이면 null.
  final String? ladderId;
  final int? step;

  /// 예: `harvested` — 수확한 적이 있어야 제안.
  final String? requires;

  bool get isPlantPair => ladderId == null;

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

class RestOption {
  RestOption({required this.id, required this.text, required this.description});

  factory RestOption.fromJson(JsonReader r) =>
      RestOption(id: r.str('id'), text: r.str('text'), description: r.str('description'));

  final String id;
  final String text;
  final String description;
}

class MissionsContent {
  MissionsContent({required this.rest, required this.ladders, required this.plantPair});

  factory MissionsContent.fromJson(Object? json) {
    final r = JsonReader.root('missions.json', json);
    return MissionsContent(
      rest: RestOption.fromJson(r.obj('rest')),
      ladders: [for (final l in r.objList('ladders')) Ladder.fromJson(l)],
      plantPair: [for (final p in r.objList('plantPair')) Mission.fromJson(p)],
    );
  }

  final RestOption rest;
  final List<Ladder> ladders;
  final List<Mission> plantPair;

  Iterable<Mission> get allMissions sync* {
    for (final l in ladders) {
      yield* l.steps;
    }
    yield* plantPair;
  }

  Mission? missionById(String id) {
    for (final m in allMissions) {
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
    final errors = <String>[
      ...duplicateIds('missions.json ladders', [for (final l in ladders) l.id]),
      ...duplicateIds('missions.json missions', [rest.id, ...allMissions.map((m) => m.id)]),
    ];
    for (final l in ladders) {
      for (var i = 0; i < l.steps.length; i++) {
        if (l.steps[i].step != i + 1) {
          errors.add('missions.json ladder(${l.id}) step 은 1부터 차례로 (${l.steps[i].id})');
        }
      }
    }
    for (final m in allMissions) {
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
    }
    // 에너지 1에서도 언제나 고를 수 있는 새싹 짝 행동이 있어야 한다(6.3).
    if (!plantPair.any((m) => m.minEnergy == 1)) {
      errors.add('missions.json plantPair 에 minEnergy 1 행동이 없음');
    }
    return errors;
  }
}
