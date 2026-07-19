import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/colors.dart';
import 'core/theme.dart';
import 'router.dart';
import 'security/app_lock_manager.dart';
import 'services/presence_service.dart';

class DuoShieldApp extends ConsumerStatefulWidget {
  const DuoShieldApp({super.key});

  @override
  ConsumerState<DuoShieldApp> createState() => _DuoShieldAppState();
}

class _DuoShieldAppState extends ConsumerState<DuoShieldApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    PresenceService.instance.init();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    PresenceService.instance.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      AppLockManager.instance.onAppBackgrounded();
    } else if (state == AppLifecycleState.resumed) {
      AppLockManager.instance.onAppResumed(appRouter);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'DuoShield',
      debugShowCheckedModeBanner: false,
      theme: dsTheme,
      routerConfig: appRouter,
    );
  }
}
