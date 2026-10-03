import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/home.dart';
import 'screens/lock_screens.dart';
import 'services/platform.dart';
import 'state.dart';
import 'theme.dart';

final _navKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initAppState();
  SecurePlatform.setSecure(settings.blockScreenshots);
  runApp(const CiGuardApp());
}

class CiGuardApp extends StatefulWidget {
  const CiGuardApp({super.key});

  @override
  State<CiGuardApp> createState() => _CiGuardAppState();
}

class _CiGuardAppState extends State<CiGuardApp> with WidgetsBindingObserver {
  Timer? _idle;
  DateTime? _backgroundedAt;
  VaultStatus _last = vault.status;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    vault.addListener(_onVault);
    settings.addListener(_resetIdle);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    vault.removeListener(_onVault);
    settings.removeListener(_resetIdle);
    _idle?.cancel();
    super.dispose();
  }

  void _onVault() {
    final s = vault.status;
    if (s != _last) {
      // Changement d'état du coffre : on revient à la racine (fermeture des écrans ouverts).
      _navKey.currentState?.popUntil((r) => r.isFirst);
      _last = s;
    }
    _resetIdle();
  }

  void _resetIdle() {
    _idle?.cancel();
    if (vault.status == VaultStatus.unlocked && settings.autoLock) {
      _idle = Timer(Duration(seconds: settings.autoLockSeconds), vault.lock);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) {
      if (vault.status == VaultStatus.unlocked) _backgroundedAt ??= DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      final since = _backgroundedAt;
      _backgroundedAt = null;
      if (since != null &&
          settings.autoLock &&
          DateTime.now().difference(since).inSeconds >= settings.autoLockSeconds) {
        vault.lock();
      }
      _resetIdle();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) {
        final p = settings.palette;
        return MaterialApp(
          navigatorKey: _navKey,
          title: 'CiGuard',
          debugShowCheckedModeBanner: false,
          theme: buildTheme(p, settings.accent),
          builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
            value: (p.dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark).copyWith(
              statusBarColor: Colors.transparent,
              systemNavigationBarColor: p.bg,
              systemNavigationBarDividerColor: p.bg,
            ),
            child: Listener(
              behavior: HitTestBehavior.translucent,
              onPointerDown: (_) => _resetIdle(),
              child: child,
            ),
          ),
          home: const _RootGate(),
        );
      },
    );
  }
}

class _RootGate extends StatelessWidget {
  const _RootGate();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: vault,
      builder: (context, _) {
        final Widget child = switch (vault.status) {
          VaultStatus.loading => const Scaffold(),
          VaultStatus.empty => const SetupScreen(),
          VaultStatus.locked => const UnlockScreen(),
          VaultStatus.needsBiometric => const BiometricScreen(),
          VaultStatus.unlocked => const HomeShell(),
        };
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: KeyedSubtree(key: ValueKey(vault.status), child: child),
        );
      },
    );
  }
}
