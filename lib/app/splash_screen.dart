import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/content/content_repository.dart';
import 'router.dart';

/// 콘텐츠를 읽는 동안 보이는 첫 화면.
class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(appContentProvider, (_, next) {
      if (next.hasValue) context.go(Routes.home);
    });
    final content = ref.watch(appContentProvider);
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: Center(
        child: content.hasError
            // 콘텐츠 파일이 깨진 경우는 개발 중에만 생긴다. 사용자 문구를 새로 만들지 않고 아이콘만 보인다.
            ? Icon(Icons.eco_outlined, size: 72, color: scheme.error)
            : Icon(Icons.eco, size: 72, color: scheme.primary),
      ),
    );
  }
}
