import '../josa.dart';
import 'json_reader.dart';
import 'species_content.dart' show duplicateIds;

/// 하루 중 시각 범위. `23:00-04:59`처럼 자정을 넘을 수 있다.
class TimeRange {
  TimeRange(this.id, this.startMinute, this.endMinute);

  factory TimeRange.parse(String id, String value, JsonReader r) {
    final m = RegExp(r'^(\d{2}):(\d{2})-(\d{2}):(\d{2})$').firstMatch(value);
    if (m == null) r.fail(id, 'HH:mm-HH:mm 형식이어야 함');
    int minute(int h, int mm) {
      if (h > 23 || mm > 59) r.fail(id, '시각 범위가 잘못됨');
      return h * 60 + mm;
    }

    return TimeRange(
      id,
      minute(int.parse(m.group(1)!), int.parse(m.group(2)!)),
      minute(int.parse(m.group(3)!), int.parse(m.group(4)!)),
    );
  }

  final String id;

  /// 자정부터 분. 끝 값도 범위에 포함한다.
  final int startMinute;
  final int endMinute;

  bool contains(int minuteOfDay) => startMinute <= endMinute
      ? minuteOfDay >= startMinute && minuteOfDay <= endMinute
      : minuteOfDay >= startMinute || minuteOfDay <= endMinute;
}

/// 단순 문구 (id + text).
class TextMessage {
  TextMessage({required this.id, required this.text});

  factory TextMessage.fromJson(JsonReader r) => TextMessage(id: r.str('id'), text: r.str('text'));

  final String id;
  final String text;
}

class HomeMessage extends TextMessage {
  HomeMessage({
    required super.id,
    required super.text,
    required this.contexts,
    required this.energy,
    required this.category,
  });

  factory HomeMessage.fromJson(JsonReader r) => HomeMessage(
        id: r.str('id'),
        text: r.str('text'),
        contexts: r.strList('context', allowEmpty: false),
        energy: r.intList('energy', allowEmpty: false),
        category: r.str('category'),
      );

  final List<String> contexts;
  final List<int> energy;
  final String category;
}

class PersonalMessage extends TextMessage {
  PersonalMessage({required super.id, required super.text, required this.requires});

  factory PersonalMessage.fromJson(JsonReader r) => PersonalMessage(
        id: r.str('id'),
        text: r.str('text'),
        requires: r.strList('requires', allowEmpty: false),
      );

  final List<String> requires;
}

class NotificationMessage {
  NotificationMessage({
    required this.id,
    required this.type,
    required this.category,
    required this.title,
    required this.body,
  });

  factory NotificationMessage.fromJson(JsonReader r) => NotificationMessage(
        id: r.str('id'),
        type: r.str('type'),
        category: r.str('category'),
        title: r.str('title'),
        body: r.str('body'),
      );

  final String id;
  final String type;

  /// Thompson Sampling 묶음(6.9). `event`는 학습 대상이 아님.
  final String category;
  final String title;
  final String body;
}

/// 행동 후 문구 묶음 이름.
const List<String> kAfterActionKinds = ['positive', 'zero', 'negative', 'skipped', 'chain'];

/// 알림 종류. 알림 엔진(6.4)이 아는 값만 허용한다.
const Set<String> kNotificationTypes = {
  'morning_care',
  'evening',
  'germination',
  'harvest_ready',
  'analysis_done',
  'weekly_report',
  'gentle_return',
  'support_checkin',
  'refill',
  'friend_reaction',
  'level_up',
};

class MessagesContent {
  MessagesContent({
    required this.slotsDoc,
    required this.contexts,
    required this.timeRanges,
    required this.home,
    required this.personal,
    required this.afterAction,
    required this.rest,
    required this.support,
    required this.notifications,
  });

  factory MessagesContent.fromJson(Object? json) {
    final r = JsonReader.root('messages.json', json);
    final ranges = r.obj('timeRanges');
    final aa = r.obj('afterAction');
    return MessagesContent(
      slotsDoc: r.strMap('slotsDoc'),
      contexts: r.strList('contexts', allowEmpty: false),
      timeRanges: {
        for (final k in ranges.keys) k: TimeRange.parse(k, ranges.str(k), ranges),
      },
      home: [for (final m in r.objList('home')) HomeMessage.fromJson(m)],
      personal: [for (final m in r.objList('personal')) PersonalMessage.fromJson(m)],
      afterAction: {
        for (final kind in kAfterActionKinds)
          kind: [for (final m in aa.objList(kind)) TextMessage.fromJson(m)],
      },
      rest: [for (final m in r.objList('rest')) TextMessage.fromJson(m)],
      support: [for (final m in r.objList('support')) TextMessage.fromJson(m)],
      notifications: [
        for (final m in r.objList('notifications')) NotificationMessage.fromJson(m),
      ],
    );
  }

  final Map<String, String> slotsDoc;
  final List<String> contexts;
  final Map<String, TimeRange> timeRanges;
  final List<HomeMessage> home;
  final List<PersonalMessage> personal;
  final Map<String, List<TextMessage>> afterAction;
  final List<TextMessage> rest;
  final List<TextMessage> support;
  final List<NotificationMessage> notifications;

  /// 분(0~1439)이 속한 시간대 id.
  String timeRangeAt(int minuteOfDay) {
    for (final r in timeRanges.values) {
      if (r.contains(minuteOfDay)) return r.id;
    }
    throw StateError('시간대 정의가 하루 전체를 덮지 않음: $minuteOfDay');
  }

  /// 사용자에게 보이는 모든 문구 (id, 문구).
  Iterable<(String, String)> get allTexts sync* {
    for (final m in home) {
      yield (m.id, m.text);
    }
    for (final m in personal) {
      yield (m.id, m.text);
    }
    for (final list in afterAction.values) {
      for (final m in list) {
        yield (m.id, m.text);
      }
    }
    for (final m in [...rest, ...support]) {
      yield (m.id, m.text);
    }
    for (final n in notifications) {
      yield (n.id, n.title);
      yield (n.id, n.body);
    }
  }

  List<String> validate() {
    final errors = <String>[
      ...duplicateIds('messages.json', [
        ...home.map((m) => m.id),
        ...personal.map((m) => m.id),
        for (final l in afterAction.values) ...l.map((m) => m.id),
        ...rest.map((m) => m.id),
        ...support.map((m) => m.id),
        ...notifications.map((m) => m.id),
      ]),
    ];

    // 슬롯과 조사 표기
    for (final (id, text) in allTexts) {
      for (final s in slotsIn(text)) {
        if (!slotsDoc.containsKey(s)) errors.add('messages.json $id: 정의되지 않은 슬롯 {$s}');
      }
      for (final j in unsupportedJosaIn(text)) {
        errors.add('messages.json $id: 지원하지 않는 조사 표기 .$j');
      }
      if ('{'.allMatches(text).length != '}'.allMatches(text).length) {
        errors.add('messages.json $id: 중괄호 짝이 맞지 않음');
      }
    }
    for (final p in personal) {
      for (final s in slotsIn(p.text)) {
        if (!p.requires.contains(s)) errors.add('messages.json ${p.id}: {$s} 가 requires 에 없음');
      }
    }

    // 시간대: 하루 1440분을 정확히 한 번씩 덮어야 한다.
    for (var minute = 0; minute < 1440; minute++) {
      final hits = timeRanges.values.where((r) => r.contains(minute)).length;
      if (hits != 1) {
        errors.add('messages.json timeRanges: ${minute ~/ 60}:${minute % 60} 이(가) $hits 개 구간에 속함');
        break;
      }
    }
    for (final t in timeRanges.keys) {
      if (!contexts.contains(t)) errors.add('messages.json timeRanges.$t 가 contexts 에 없음');
    }

    // 홈 문구
    for (final m in home) {
      for (final c in m.contexts) {
        if (!contexts.contains(c)) errors.add('messages.json ${m.id}: 알 수 없는 context $c');
      }
      for (final e in m.energy) {
        if (e < 1 || e > 3) errors.add('messages.json ${m.id}: energy 는 1~3');
      }
    }
    for (final c in contexts) {
      for (final e in [1, 2, 3]) {
        final ok = home.any((m) => m.contexts.contains(c) && m.energy.contains(e));
        if (!ok) errors.add('messages.json home: context $c, 에너지 $e 에 해당하는 문구가 없음');
      }
    }

    // 알림
    for (final n in notifications) {
      if (!kNotificationTypes.contains(n.type)) {
        errors.add('messages.json ${n.id}: 알 수 없는 알림 type ${n.type}');
      }
    }
    for (final t in kNotificationTypes) {
      if (!notifications.any((n) => n.type == t)) {
        errors.add('messages.json notifications: type $t 문구가 없음');
      }
    }
    for (final kind in kAfterActionKinds) {
      if (afterAction[kind]!.isEmpty) errors.add('messages.json afterAction.$kind 가 비어 있음');
    }
    if (support.isEmpty || rest.isEmpty) errors.add('messages.json support/rest 가 비어 있음');
    return errors;
  }
}
