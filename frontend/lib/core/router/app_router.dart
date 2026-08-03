import 'package:go_router/go_router.dart';

import '../../features/home/presentation/home_page.dart';
import '../../features/splash/presentation/splash_page.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const SplashPage()),
    GoRoute(path: '/home', builder: (context, state) => const HomePage()),
  ],
);
