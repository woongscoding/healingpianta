import 'json_reader.dart';
import 'species_content.dart' show duplicateIds;

class Kit {
  Kit({
    required this.id,
    required this.name,
    required this.description,
    required this.species,
    this.productUrl,
    this.partnerUrl,
    this.verified = false,
    this.recommended = false,
  });

  factory Kit.fromJson(JsonReader r) => Kit(
        id: r.str('id'),
        name: r.str('name'),
        description: r.str('description'),
        species: r.strList('species', allowEmpty: false),
        productUrl: r.strOpt('productUrl'),
        partnerUrl: r.strOpt('partnerUrl'),
        verified: r.boolOr('verified', false),
        recommended: r.boolOr('recommended', false),
      );

  final String id;
  final String name;
  final String description;
  final List<String> species;
  final String? productUrl;

  /// 쿠팡 파트너스 링크. 비어 있으면 Remote Config(`kit_partner_urls`) 값을 쓴다.
  final String? partnerUrl;
  final bool verified;
  final bool recommended;

  /// 여러 종류가 든 세트면 온보딩에서 이번에 심을 종류를 고른다.
  bool get isMultiSpecies => species.length > 1;
}

class KitsContent {
  KitsContent({
    required this.disclosureKey,
    required this.kits,
    required this.ownKit,
    required this.defaultChaptersPerPack,
  });

  factory KitsContent.fromJson(Object? json) {
    final r = JsonReader.root('kits.json', json);
    return KitsContent(
      disclosureKey: r.str('disclosureKey'),
      kits: [for (final k in r.objList('kits')) Kit.fromJson(k)],
      ownKit: Kit.fromJson(r.obj('ownKit')),
      defaultChaptersPerPack: r.obj('refill').integer('defaultChaptersPerPack'),
    );
  }

  /// safety.json 안의 대가성 문구 키.
  final String disclosureKey;
  final List<Kit> kits;
  final Kit ownKit;
  final int defaultChaptersPerPack;

  Kit? kitById(String id) {
    if (ownKit.id == id) return ownKit;
    for (final k in kits) {
      if (k.id == id) return k;
    }
    return null;
  }

  List<String> validate({required Set<String> speciesIds}) {
    final errors = duplicateIds('kits.json', [...kits.map((k) => k.id), ownKit.id]);
    for (final k in [...kits, ownKit]) {
      for (final s in k.species) {
        if (!speciesIds.contains(s)) errors.add('kits.json ${k.id}: 알 수 없는 species $s');
      }
      for (final url in [k.productUrl, k.partnerUrl]) {
        if (url != null && url.isNotEmpty && !url.startsWith('https://')) {
          errors.add('kits.json ${k.id}: 링크는 https:// 로 시작해야 함');
        }
      }
    }
    if (defaultChaptersPerPack <= 0) errors.add('kits.json refill.defaultChaptersPerPack 는 양수');
    return errors;
  }
}
