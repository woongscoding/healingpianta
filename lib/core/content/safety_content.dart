import 'json_reader.dart';
import 'species_content.dart' show duplicateIds;

class TitledText {
  TitledText({required this.title, required this.text});

  factory TitledText.fromJson(JsonReader r) => TitledText(title: r.str('title'), text: r.str('text'));

  final String title;
  final String text;
}

class Disclaimer extends TitledText {
  Disclaimer({required super.title, required super.text, required this.confirmLabel});

  factory Disclaimer.fromJson(JsonReader r) => Disclaimer(
        title: r.str('title'),
        text: r.str('text'),
        confirmLabel: r.str('confirmLabel'),
      );

  final String confirmLabel;
}

class AgeGate extends TitledText {
  AgeGate({required super.title, required super.text, required this.minAge});

  factory AgeGate.fromJson(JsonReader r) =>
      AgeGate(title: r.str('title'), text: r.str('text'), minAge: r.integer('minAge'));

  final int minAge;
}

/// 위기 연락처. Remote Config(`crisis_contacts`)로 덮어쓸 수 있다.
class CrisisContact {
  CrisisContact({
    required this.id,
    required this.label,
    required this.description,
    required this.action,
    required this.value,
    this.verifyBeforeRelease = false,
  });

  factory CrisisContact.fromJson(JsonReader r) => CrisisContact(
        id: r.str('id'),
        label: r.str('label'),
        description: r.str('description'),
        action: r.str('action'),
        value: r.str('value'),
        verifyBeforeRelease: r.boolOr('verifyBeforeRelease', false),
      );

  final String id;
  final String label;
  final String description;

  /// tel | url
  final String action;
  final String value;
  final bool verifyBeforeRelease;
}

class HelpScreen extends TitledText {
  HelpScreen({
    required super.title,
    required super.text,
    required this.contacts,
    required this.remoteConfigKey,
  });

  factory HelpScreen.fromJson(JsonReader r) => HelpScreen(
        title: r.str('title'),
        text: r.str('text'),
        contacts: [for (final c in r.objList('contacts')) CrisisContact.fromJson(c)],
        remoteConfigKey: r.str('remoteConfigKey'),
      );

  final List<CrisisContact> contacts;
  final String remoteConfigKey;
}

/// 지지 모드 진입·해제 기준 (6.5). Remote Config(`support_mode_rules`)로 덮어쓸 수 있다.
class SupportModeRules {
  SupportModeRules({
    required this.consecutiveMoodOne,
    required this.lowMoodWindow,
    required this.lowMoodThreshold,
    required this.lowMoodCount,
    required this.keywordDetection,
    required this.exitByUserSelfReport,
    required this.selfReportLabel,
    required this.exitMoodAtLeast,
    required this.exitRequiredCount,
    required this.hideActionSuggestions,
    required this.stopActivationNotifications,
    required this.dailySupportCheckins,
    required this.showHelpCardOnHome,
    required this.muteFriendNotifications,
    required this.remoteConfigKey,
  });

  factory SupportModeRules.fromJson(JsonReader r) {
    final enter = r.obj('enter');
    final exit = r.obj('exit');
    final b = r.obj('behavior');
    return SupportModeRules(
      consecutiveMoodOne: enter.integer('consecutiveMoodOne'),
      lowMoodWindow: enter.integer('lowMoodWindow'),
      lowMoodThreshold: enter.integer('lowMoodThreshold'),
      lowMoodCount: enter.integer('lowMoodCount'),
      keywordDetection: enter.boolean('keywordDetection'),
      exitByUserSelfReport: exit.boolean('userSelfReport'),
      selfReportLabel: exit.str('selfReportLabel'),
      exitMoodAtLeast: exit.integer('moodAtLeast'),
      exitRequiredCount: exit.integer('requiredCount'),
      hideActionSuggestions: b.boolean('hideActionSuggestions'),
      stopActivationNotifications: b.boolean('stopActivationNotifications'),
      dailySupportCheckins: b.integer('dailySupportCheckins'),
      showHelpCardOnHome: b.boolean('showHelpCardOnHome'),
      muteFriendNotifications: b.boolean('muteFriendNotifications'),
      remoteConfigKey: r.str('remoteConfigKey'),
    );
  }

  final int consecutiveMoodOne;
  final int lowMoodWindow;
  final int lowMoodThreshold;
  final int lowMoodCount;
  final bool keywordDetection;
  final bool exitByUserSelfReport;
  final String selfReportLabel;
  final int exitMoodAtLeast;
  final int exitRequiredCount;
  final bool hideActionSuggestions;
  final bool stopActivationNotifications;
  final int dailySupportCheckins;
  final bool showHelpCardOnHome;
  final bool muteFriendNotifications;
  final String remoteConfigKey;
}

class KeywordDetectedSheet extends TitledText {
  KeywordDetectedSheet({
    required super.title,
    required super.text,
    required this.primaryLabel,
    required this.secondaryLabel,
  });

  factory KeywordDetectedSheet.fromJson(JsonReader r) => KeywordDetectedSheet(
        title: r.str('title'),
        text: r.str('text'),
        primaryLabel: r.str('primaryLabel'),
        secondaryLabel: r.str('secondaryLabel'),
      );

  final String primaryLabel;
  final String secondaryLabel;
}

class ForbiddenCopy {
  ForbiddenCopy({required this.scanFields, required this.words, required this.lockScreenWords});

  factory ForbiddenCopy.fromJson(JsonReader r) => ForbiddenCopy(
        scanFields: r.strList('scanFields', allowEmpty: false),
        words: r.strList('words', allowEmpty: false),
        lockScreenWords: r.strList('lockScreenWords', allowEmpty: false),
      );

  final List<String> scanFields;
  final List<String> words;
  final List<String> lockScreenWords;
}

class SafetyContent {
  SafetyContent({
    required this.disclaimer,
    required this.ageGate,
    required this.consents,
    required this.cameraHint,
    required this.helpScreen,
    required this.supportMode,
    required this.crisisKeywords,
    required this.keywordDetectedSheet,
    required this.coupangDisclosure,
    required this.forbiddenCopy,
    required this.raw,
  });

  factory SafetyContent.fromJson(Object? json) {
    final r = JsonReader.root('safety.json', json);
    final consents = r.objMap('consents');
    return SafetyContent(
      disclaimer: Disclaimer.fromJson(r.obj('disclaimer')),
      ageGate: AgeGate.fromJson(r.obj('ageGate')),
      consents: {for (final e in consents.entries) e.key: TitledText.fromJson(e.value)},
      cameraHint: r.str('cameraHint'),
      helpScreen: HelpScreen.fromJson(r.obj('helpScreen')),
      supportMode: SupportModeRules.fromJson(r.obj('supportMode')),
      crisisKeywords: r.obj('crisisKeywords').strList('keywords', allowEmpty: false),
      keywordDetectedSheet: KeywordDetectedSheet.fromJson(r.obj('keywordDetectedSheet')),
      coupangDisclosure: r.str('coupangDisclosure'),
      forbiddenCopy: ForbiddenCopy.fromJson(r.obj('forbiddenCopy')),
      raw: r.raw,
    );
  }

  final Disclaimer disclaimer;
  final AgeGate ageGate;

  /// sensitive(민감정보, 필수), photo(사진 안내) 등.
  final Map<String, TitledText> consents;
  final String cameraHint;
  final HelpScreen helpScreen;
  final SupportModeRules supportMode;
  final List<String> crisisKeywords;
  final KeywordDetectedSheet keywordDetectedSheet;
  final String coupangDisclosure;
  final ForbiddenCopy forbiddenCopy;

  /// 키로 문구를 찾을 때 쓴다(예: kits.json의 disclosureKey).
  final Map<String, dynamic> raw;

  List<String> validate() {
    final errors = duplicateIds('safety.json helpScreen.contacts', helpScreen.contacts.map((c) => c.id));
    if (ageGate.minAge < 19) errors.add('safety.json ageGate.minAge 는 19 이상');
    if (!consents.containsKey('sensitive')) errors.add('safety.json consents.sensitive 필요');
    for (final c in helpScreen.contacts) {
      if (c.action != 'tel' && c.action != 'url') {
        errors.add('safety.json contact ${c.id}.action 은 tel 또는 url');
      }
      if (c.action == 'url' && !c.value.startsWith('https://')) {
        errors.add('safety.json contact ${c.id}: 링크는 https:// 로 시작해야 함');
      }
      if (c.action == 'tel' && !RegExp(r'^[0-9-]+$').hasMatch(c.value)) {
        errors.add('safety.json contact ${c.id}: 전화번호 형식이 잘못됨');
      }
    }
    if (!helpScreen.contacts.any((c) => c.value == '109')) {
      errors.add('safety.json helpScreen 에 109 연락처가 없음');
    }
    final s = supportMode;
    if (s.consecutiveMoodOne < 1 ||
        s.lowMoodWindow < 1 ||
        s.lowMoodCount < 1 ||
        s.lowMoodCount > s.lowMoodWindow ||
        s.lowMoodThreshold < 1 ||
        s.lowMoodThreshold > 5 ||
        s.exitMoodAtLeast < 1 ||
        s.exitMoodAtLeast > 5 ||
        s.exitRequiredCount < 1) {
      errors.add('safety.json supportMode 기준값 범위가 잘못됨');
    }
    return errors;
  }
}
