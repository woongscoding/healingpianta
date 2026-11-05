/// 콘텐츠 JSON을 타입 검사하며 읽는 도우미.
///
/// 잘못된 값을 만나면 파일 이름과 JSON 경로가 담긴 [ContentFormatException]을 던져
/// 어느 줄을 고쳐야 하는지 바로 알 수 있게 한다.
library;

class ContentFormatException implements Exception {
  ContentFormatException(this.file, this.path, this.message);

  final String file;
  final String path;
  final String message;

  @override
  String toString() => 'ContentFormatException($file:$path): $message';
}

class JsonReader {
  JsonReader._(this.file, this.path, this._map);

  /// 파일 최상위 객체로 시작한다.
  factory JsonReader.root(String file, Object? decoded) {
    if (decoded is! Map<String, dynamic>) {
      throw ContentFormatException(file, r'$', '최상위가 객체가 아님');
    }
    return JsonReader._(file, r'$', decoded);
  }

  final String file;
  final String path;
  final Map<String, dynamic> _map;

  Map<String, dynamic> get raw => _map;
  bool has(String key) => _map.containsKey(key) && _map[key] != null;
  Iterable<String> get keys => _map.keys;

  Never fail(String key, String message) =>
      throw ContentFormatException(file, '$path.$key', message);

  T _req<T>(String key, String typeName) {
    final v = _map[key];
    if (v == null) fail(key, '필수 값이 없음');
    if (v is! T) fail(key, '$typeName 이어야 함 (실제: ${v.runtimeType})');
    return v;
  }

  String str(String key, {bool allowEmpty = false}) {
    final v = _req<String>(key, '문자열');
    if (!allowEmpty && v.trim().isEmpty) fail(key, '빈 문자열');
    return v;
  }

  String? strOpt(String key) {
    if (!has(key)) return null;
    return str(key, allowEmpty: true);
  }

  int integer(String key) {
    final v = _req<num>(key, '숫자');
    if (v is! int && v != v.roundToDouble()) fail(key, '정수여야 함');
    return v.toInt();
  }

  int? intOpt(String key) => has(key) ? integer(key) : null;

  double number(String key) => _req<num>(key, '숫자').toDouble();

  bool boolean(String key) => _req<bool>(key, '불리언');

  bool boolOr(String key, bool fallback) => has(key) ? boolean(key) : fallback;

  List<dynamic> _list(String key) => _req<List<dynamic>>(key, '배열');

  List<String> strList(String key, {bool allowEmpty = true}) {
    final list = _list(key);
    if (!allowEmpty && list.isEmpty) fail(key, '빈 배열');
    return [
      for (var i = 0; i < list.length; i++)
        if (list[i] is String && (list[i] as String).isNotEmpty)
          list[i] as String
        else
          fail('$key[$i]', '비어 있지 않은 문자열이어야 함'),
    ];
  }

  List<String> strListOr(String key, List<String> fallback) =>
      has(key) ? strList(key) : fallback;

  List<int> intList(String key, {bool allowEmpty = true}) {
    final list = _list(key);
    if (!allowEmpty && list.isEmpty) fail(key, '빈 배열');
    return [
      for (var i = 0; i < list.length; i++)
        if (list[i] is int) list[i] as int else fail('$key[$i]', '정수여야 함'),
    ];
  }

  List<num> numList(String key) {
    final list = _list(key);
    return [
      for (var i = 0; i < list.length; i++)
        if (list[i] is num) list[i] as num else fail('$key[$i]', '숫자여야 함'),
    ];
  }

  JsonReader obj(String key) {
    final v = _req<Map<String, dynamic>>(key, '객체');
    return JsonReader._(file, '$path.$key', v);
  }

  JsonReader? objOpt(String key) => has(key) ? obj(key) : null;

  List<JsonReader> objList(String key, {bool allowEmpty = false}) {
    final list = _list(key);
    if (!allowEmpty && list.isEmpty) fail(key, '빈 배열');
    return [
      for (var i = 0; i < list.length; i++)
        if (list[i] is Map<String, dynamic>)
          JsonReader._(file, '$path.$key[$i]', list[i] as Map<String, dynamic>)
        else
          fail('$key[$i]', '객체여야 함'),
    ];
  }

  Map<String, String> strMap(String key) {
    final o = obj(key);
    return {for (final k in o.keys) k: o.str(k)};
  }

  Map<String, int> intMap(String key) {
    final o = obj(key);
    return {for (final k in o.keys) k: o.integer(k)};
  }

  /// 값이 모두 객체인 맵. 예: species.json의 `issues`.
  Map<String, JsonReader> objMap(String key) {
    final o = obj(key);
    return {for (final k in o.keys) k: o.obj(k)};
  }
}

/// `#RRGGBB` 또는 `#AARRGGBB` → ARGB 정수.
int parseHexColor(JsonReader r, String key) {
  final s = r.str(key);
  final m = RegExp(r'^#([0-9a-fA-F]{6}|[0-9a-fA-F]{8})$').firstMatch(s);
  if (m == null) r.fail(key, '색은 #RRGGBB 형식이어야 함 (실제: $s)');
  final hex = m.group(1)!;
  return int.parse(hex.length == 6 ? 'FF$hex' : hex, radix: 16);
}
