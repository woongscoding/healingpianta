import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Firebase 초기화는 프로젝트 연결 후 여기에 추가한다 (Phase 2 시작 전).
  runApp(const ProviderScope(child: HealingPiantaApp()));
}
