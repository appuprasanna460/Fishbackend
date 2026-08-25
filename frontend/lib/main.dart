import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/zoom_provider.dart';
import 'router/app_router.dart';
import 'core/splash/splash_screen.dart';
import 'core/network/dio_client.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: FishMarketApp()));
}

class FishMarketApp extends ConsumerStatefulWidget {
  const FishMarketApp({super.key});

  @override
  ConsumerState<FishMarketApp> createState() => _FishMarketAppState();
}

class _FishMarketAppState extends ConsumerState<FishMarketApp>
    with SingleTickerProviderStateMixin {
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();

    // Show splash for 4 seconds, then transition to main app
    Future.delayed(const Duration(milliseconds: 4000), () {
      if (mounted) {
        setState(() => _showSplash = false);
      }
    });

    // Listen for subscription expiry from any Dio request.
    // When the backend returns SUBSCRIPTION_EXPIRED the notifier flips,
    // and we navigate to the expired screen — the user can request renewal
    // from there without being fully locked out.
    subscriptionExpiredNotifier.addListener(_onSubscriptionExpired);
  }

  @override
  void dispose() {
    subscriptionExpiredNotifier.removeListener(_onSubscriptionExpired);
    super.dispose();
  }

  void _onSubscriptionExpired() {
    // Get the router and navigate — only after splash, only if authenticated
    if (!_showSplash) {
      final router = ref.read(appRouterProvider);
      final currentLocation = router.routerDelegate.currentConfiguration
          .matches.last.matchedLocation;
      // Don't redirect if already on subscription screens
      const subscriptionPaths = [
        '/subscription-expired',
        '/subscription-detail',
        '/plan-selection',
      ];
      if (!subscriptionPaths.any((p) => currentLocation.startsWith(p))) {
        router.go('/subscription-expired');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final zoomLevel = ref.watch(zoomLevelProvider);

    if (_showSplash) {
      return MaterialApp(
        title: 'Fish Market Management',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        builder: (context, child) {
          return ZoomWrapper(
            zoomLevel: zoomLevel,
            child: child!,
          );
        },
        home: const SplashScreen(),
      );
    }

    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'Fish Market Management',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
      builder: (context, child) {
        return ZoomWrapper(
          zoomLevel: zoomLevel,
          child: child!,
        );
      },
    );
  }
}
