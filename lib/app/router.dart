import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/home/home_screen.dart';
import 'splash_screen.dart';

/// 경로 이름. 화면이 늘어나면 여기에 추가한다.
abstract final class Routes {
  static const splash = '/';
  static const home = '/home';
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: Routes.splash,
    routes: [
      GoRoute(path: Routes.splash, builder: (context, state) => const SplashScreen()),
      GoRoute(path: Routes.home, builder: (context, state) => const HomeScreen()),
    ],
  );
});
