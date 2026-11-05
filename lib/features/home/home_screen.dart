import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/content/content_repository.dart';
import '../../core/josa.dart';

/// 홈 (Phase 1 자리표시). Phase 3에서 인사·에너지·행동 제안으로 채운다.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final content = ref.watch(appContentProvider).requireValue;
    // 콘텐츠 로딩 확인용: 슬롯이 없는 first_open 문구 하나.
    final greeting = content.messages.home
        .where((m) => m.contexts.contains('first_open') && slotsIn(m.text).isEmpty)
        .firstOrNull;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('HealingPianta')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Icon(Icons.eco, size: 96, color: theme.colorScheme.primary),
            const SizedBox(height: 24),
            if (greeting != null)
              Text(greeting.text, style: theme.textTheme.titleLarge, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
