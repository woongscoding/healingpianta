import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healingpianta/app/app.dart';
import 'package:healingpianta/features/home/home_screen.dart';

void main() {
  testWidgets('앱이 콘텐츠를 읽고 홈까지 간다', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: HealingPiantaApp()));
    // 에셋 로딩은 실제 비동기 작업이라 runAsync로 기다린다.
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 500)));
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('HealingPianta'), findsOneWidget);
  });

  testWidgets('다크 모드와 큰 글씨에서도 오버플로 없음', (tester) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(tester.platformDispatcher.clearAllTestValues);
    await tester.pumpWidget(const ProviderScope(child: HealingPiantaApp()));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 500)));
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
