import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_content.dart';

/// 번들된 `assets/content/*.json`을 읽어 검증한다.
Future<AppContent> loadAppContent(AssetBundle bundle) async {
  final sources = <String, String>{
    for (final f in kContentFiles) f: await bundle.loadString('$kContentDir/$f', cache: false),
  };
  return AppContent.fromSources(sources).validated();
}

/// 앱 전체에서 쓰는 콘텐츠. 스플래시에서 로딩을 기다린다.
final appContentProvider = FutureProvider<AppContent>((ref) => loadAppContent(rootBundle));
