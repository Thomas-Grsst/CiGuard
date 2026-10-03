import 'package:flutter/material.dart';

import '../services/password_tools.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets.dart';

class SecurityTab extends StatelessWidget {
  const SecurityTab({super.key, required this.onIssueTap});

  final ValueChanged<Issue> onIssueTap;

  static const delays = [30, 60, 120, 300, 900];

  void _pickDelay(BuildContext context) {
    final cg = context.cg;
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Verrouiller après', style: geist(17, weight: FontWeight.w600, color: cg.p.text)),
              const SizedBox(height: 12),
              for (final d in delays)
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                  title: Text('${autoLockLabel(d)} d’inactivité', style: geist(15, color: cg.p.text)),
                  trailing: settings.autoLockSeconds == d ? Icon(Icons.check_rounded, color: cg.accent) : null,
                  onTap: () {
                    settings.setAutoLockSeconds(d);
                    Navigator.pop(ctx);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cg = context.cg;
    final p = cg.p;
    return ListenableBuilder(
      listenable: Listenable.merge([vault, settings]),
      builder: (context, _) {
        final audit = Audit(vault.entries);
        final score = audit.score;
        final (title, sub) = switch (score) {
          null => ('Coffre vide', 'Ajoutez des identifiants pour obtenir un score.'),
          100 => ('Excellent', 'Aucun problème détecté. Bravo.'),
          final s => (
              s >= 80 ? 'Bon niveau' : (s >= 50 ? 'À améliorer' : 'Fragile'),
              'Corrigez ${audit.flagged} identifiant${audit.flagged > 1 ? 's' : ''} pour atteindre 100.'
            ),
        };
        final colors = {
          Issue.common: cg.bad,
          Issue.weak: cg.warn,
          Issue.reused: cg.warn,
          Issue.old: p.muted,
        };
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          children: [
            Text('Sécurité', style: geist(28, weight: FontWeight.w600, color: p.text, spacing: -0.02)),
            const SizedBox(height: 20),
            CgCard(
              radius: 18,
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  ScoreRing(value: (score ?? 0) / 100, label: score?.toString() ?? '—'),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: geist(17, weight: FontWeight.w600, color: p.text)),
                        const SizedBox(height: 6),
                        Text(sub, style: geist(13, color: p.muted, height: 1.45)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            CgCard(
              child: Column(
                children: [
                  for (final i in Issue.values)
                    InkWell(
                      onTap: audit.count(i) == 0 ? null : () => onIssueTap(i),
                      child: Container(
                        decoration: BoxDecoration(
                          border: i == Issue.values.last ? null : Border(bottom: BorderSide(color: p.divider)),
                        ),
                        padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: audit.count(i) == 0 ? p.border : colors[i],
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(i.label, style: geist(15, color: p.text)),
                                  const SizedBox(height: 2),
                                  Text(i.hint, style: geist(12, color: p.muted)),
                                ],
                              ),
                            ),
                            Text('${audit.count(i)}', style: geist(15, mono: true, color: p.text)),
                            const SizedBox(width: 6),
                            Icon(Icons.chevron_right_rounded, size: 18, color: p.muted),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            const SectionLabel('Protection'),
            CgCard(
              child: Column(
                children: [
                  ToggleRow(
                    label: 'Verrouillage auto',
                    hint: 'Après ${autoLockLabel(settings.autoLockSeconds)} d’inactivité · toucher pour changer',
                    value: settings.autoLock,
                    onChanged: settings.setAutoLock,
                    onTapLabel: () => _pickDelay(context),
                  ),
                  ToggleRow(
                    label: 'Vider le presse-papiers',
                    hint: '30 s après une copie',
                    value: settings.clearClipboard,
                    onChanged: settings.setClearClipboard,
                  ),
                  ToggleRow(
                    label: 'Bloquer les captures',
                    hint: 'Écran masqué dans le multitâche',
                    value: settings.blockScreenshots,
                    onChanged: settings.setBlockScreenshots,
                  ),
                  ToggleRow(
                    label: 'Empreinte + mot de passe',
                    hint: 'Les deux exigés à chaque ouverture',
                    value: settings.requireBiometric,
                    onChanged: settings.setRequireBiometric,
                    divider: false,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
