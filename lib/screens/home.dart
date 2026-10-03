import 'package:flutter/material.dart';

import '../services/password_tools.dart';
import '../theme.dart';
import 'generator.dart';
import 'security.dart';
import 'settings.dart';
import 'vault_screens.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tab = 0;
  Issue? _issue;

  static const _items = [
    (Icons.shield_moon_outlined, Icons.shield_moon_rounded, 'Coffre'),
    (Icons.autorenew_rounded, Icons.autorenew_rounded, 'Générateur'),
    (Icons.health_and_safety_outlined, Icons.health_and_safety_rounded, 'Sécurité'),
    (Icons.tune_rounded, Icons.tune_rounded, 'Réglages'),
  ];

  @override
  Widget build(BuildContext context) {
    final cg = context.cg;
    final p = cg.p;
    return PopScope(
      canPop: _tab == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _tab = 0);
      },
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: IndexedStack(
            index: _tab,
            children: [
              VaultTab(issue: _issue, onClearIssue: () => setState(() => _issue = null)),
              const GeneratorTab(),
              SecurityTab(
                onIssueTap: (i) => setState(() {
                  _issue = i;
                  _tab = 0;
                }),
              ),
              const SettingsTab(),
            ],
          ),
        ),
        floatingActionButton: _tab == 0
            ? SizedBox(
                width: 58,
                height: 58,
                child: FloatingActionButton(
                  tooltip: 'Ajouter un identifiant',
                  backgroundColor: cg.accent,
                  foregroundColor: cg.onAccent,
                  elevation: 6,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const EditScreen()),
                  ),
                  child: const Icon(Icons.add_rounded, size: 28),
                ),
              )
            : null,
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: p.bg,
            border: Border(top: BorderSide(color: p.divider)),
          ),
          padding: EdgeInsets.fromLTRB(12, 6, 12, 6 + MediaQuery.paddingOf(context).bottom),
          child: Row(
            children: [
              for (var i = 0; i < _items.length; i++)
                Expanded(
                  child: Semantics(
                    selected: _tab == i,
                    button: true,
                    child: InkResponse(
                      onTap: () => setState(() => _tab = i),
                      radius: 40,
                      child: SizedBox(
                        height: 58,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 52,
                              height: 30,
                              decoration: BoxDecoration(
                                color: _tab == i ? cg.accent.withValues(alpha: 0.16) : Colors.transparent,
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Icon(
                                _tab == i ? _items[i].$2 : _items[i].$1,
                                size: 22,
                                color: _tab == i ? cg.accent : p.muted,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              _items[i].$3,
                              style: geist(11,
                                  weight: _tab == i ? FontWeight.w600 : FontWeight.w400,
                                  color: _tab == i ? cg.accent : p.muted),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
