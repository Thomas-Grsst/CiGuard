import 'package:flutter/material.dart';

import '../services/platform.dart';
import '../services/crypto.dart' show passwordIterations;
import '../state.dart';
import '../theme.dart';
import '../widgets.dart';
import 'lock_screens.dart' show minMasterLength;

class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final cg = context.cg;
    final p = cg.p;
    final current = settings.accent.toARGB32();
    final isPreset = accents.any((a) => a.color.toARGB32() == current);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      children: [
        Text('Réglages', style: geist(28, weight: FontWeight.w600, color: p.text, spacing: -0.02)),
        const SizedBox(height: 20),
        const _Preview(),
        const SizedBox(height: 24),
        const SectionLabel('Style'),
        GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 2.3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [for (final pal in palettes) _PaletteTile(palette: pal)],
        ),
        const SizedBox(height: 24),
        const SectionLabel('Couleur d’accent'),
        GridView.count(
          crossAxisCount: 4,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 0.95,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [for (final a in accents) _AccentTile(swatch: a)],
        ),
        const SizedBox(height: 10),
        _CustomAccentRow(selected: !isPreset),
        const SizedBox(height: 28),
        const SectionLabel('Coffre'),
        CgCard(
          child: Column(
            children: [
              NavRow(
                icon: Icons.password_rounded,
                label: 'Changer le mot de passe maître',
                onTap: () => Navigator.of(context)
                    .push(MaterialPageRoute<void>(builder: (_) => const ChangeMasterScreen())),
              ),
              NavRow(
                icon: Icons.key_rounded,
                label: 'Nouvelle clé de récupération',
                hint: 'L’ancienne clé cessera de fonctionner',
                onTap: () => _regenRecovery(context),
              ),
              NavRow(
                icon: Icons.lock_outline_rounded,
                label: 'Verrouiller maintenant',
                onTap: vault.lock,
                divider: false,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'CiGuard 1.0 · données chiffrées sur l’appareil uniquement\nAES-256-GCM · PBKDF2-SHA256 (${passwordIterations ~/ 1000} k itérations)',
          textAlign: TextAlign.center,
          style: geist(12, color: p.muted, height: 1.5),
        ),
      ],
    );
  }

  Future<void> _regenRecovery(BuildContext context) async {
    final cg = context.cg;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nouvelle clé ?'),
        content: const Text('Une nouvelle clé de récupération sera créée. L’ancienne ne permettra plus d’ouvrir le coffre.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            style: TextButton.styleFrom(foregroundColor: cg.p.muted),
            child: const Text('Annuler'),
          ),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Créer')),
        ],
      ),
    );
    if (ok != true) return;
    final key = await vault.regenerateRecovery();
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Notez votre nouvelle clé'),
        contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Elle ne sera plus affichée.', style: geist(14, color: cg.p.muted)),
            const SizedBox(height: 14),
            RecoveryKeyCard(recoveryKey: key, onCopy: () => copySecret(ctx, key, what: 'Clé')),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('C’est noté'))],
      ),
    );
  }
}

class _Preview extends StatelessWidget {
  const _Preview();

  @override
  Widget build(BuildContext context) {
    final cg = context.cg;
    final p = cg.p;
    return CgCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Aperçu', style: geist(12, color: p.muted)),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(color: p.raised, borderRadius: BorderRadius.circular(14)),
                child: Icon(Icons.verified_user_outlined, color: cg.accent, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('CiGuard', style: geist(15, weight: FontWeight.w600, color: p.text)),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: 0.72,
                        minHeight: 4,
                        color: cg.accent,
                        backgroundColor: p.border,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              CgToggle(value: true, onChanged: (_) {}, label: 'Exemple'),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: cg.accent, borderRadius: BorderRadius.circular(12)),
            child: Text('Bouton principal', style: geist(15, weight: FontWeight.w600, color: cg.onAccent)),
          ),
        ],
      ),
    );
  }
}

class _PaletteTile extends StatelessWidget {
  const _PaletteTile({required this.palette});

  final Palette palette;

  @override
  Widget build(BuildContext context) {
    final cg = context.cg;
    final on = settings.paletteId == palette.id;
    final accent = palette.dark ? settings.accent : forLight(settings.accent);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: BorderSide(color: on ? cg.accent : cg.p.border, width: on ? 2 : 1),
    );
    return Material(
      color: palette.bg,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => settings.setPalette(palette.id),
        child: Semantics(
          selected: on,
          label: 'Style ${palette.name}',
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    color: palette.surface,
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: palette.border),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(width: 18, height: 4, decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(2))),
                      const SizedBox(height: 4),
                      Container(width: 18, height: 4, decoration: BoxDecoration(color: palette.muted, borderRadius: BorderRadius.circular(2))),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(palette.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: geist(14, weight: on ? FontWeight.w600 : FontWeight.w500, color: palette.text)),
                ),
                if (on) Icon(Icons.check_circle_rounded, size: 18, color: accent),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AccentTile extends StatelessWidget {
  const _AccentTile({required this.swatch});

  final AccentSwatch swatch;

  @override
  Widget build(BuildContext context) {
    final cg = context.cg;
    final p = cg.p;
    final on = settings.accent.toARGB32() == swatch.color.toARGB32();
    final c = cg.tint(swatch.color);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: BorderSide(color: on ? c : p.border, width: on ? 1.8 : 1),
    );
    return Material(
      color: on ? p.raised : p.surface,
      shape: shape,
      child: InkWell(
        customBorder: shape,
        onTap: () => settings.setAccent(swatch.color),
        child: Semantics(
          selected: on,
          label: 'Accent ${swatch.name}',
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 26,
                height: 26,
                decoration: BoxDecoration(shape: BoxShape.circle, color: c),
                child: on ? Icon(Icons.check_rounded, size: 16, color: c.computeLuminance() > 0.4 ? const Color(0xFF0D0E10) : Colors.white) : null,
              ),
              const SizedBox(height: 8),
              Text(swatch.name,
                  maxLines: 1, overflow: TextOverflow.ellipsis, style: geist(12, color: on ? p.text : p.soft)),
            ],
          ),
        ),
      ),
    );
  }
}

class _CustomAccentRow extends StatelessWidget {
  const _CustomAccentRow({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    final cg = context.cg;
    final p = cg.p;
    final hex = '#${(settings.accent.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: BorderSide(color: selected ? cg.accent : p.border, width: selected ? 1.8 : 1),
    );
    return Material(
      color: p.surface,
      shape: shape,
      child: InkWell(
        customBorder: shape,
        onTap: () => showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          builder: (_) => const _ColorPickerSheet(),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 10, 10),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Personnalisée', style: geist(15, color: p.text)),
                    const SizedBox(height: 2),
                    Text(hex, style: geist(12, mono: true, color: p.muted)),
                  ],
                ),
              ),
              Container(
                width: 52,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: const SweepGradient(colors: [
                    Color(0xFFFF7A8A), Color(0xFFF2B36B), Color(0xFFE6E07A), Color(0xFF5FD08A),
                    Color(0xFF5FD3D8), Color(0xFF8FA8FF), Color(0xFFB79CFF), Color(0xFFFF7A8A),
                  ]),
                ),
                alignment: Alignment.center,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: cg.accent,
                    border: Border.all(color: Colors.white, width: 2),
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

/// Sélecteur teinte / saturation / luminosité.
class _ColorPickerSheet extends StatefulWidget {
  const _ColorPickerSheet();

  @override
  State<_ColorPickerSheet> createState() => _ColorPickerSheetState();
}

class _ColorPickerSheetState extends State<_ColorPickerSheet> {
  late HSLColor _c = HSLColor.fromColor(settings.accent);

  @override
  Widget build(BuildContext context) {
    final p = context.cg.p;
    final color = _c.toColor();
    Widget track(String label, double value, double max, List<Color> colors, ValueChanged<double> onChanged) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(label, style: geist(13, color: p.muted)),
          const SizedBox(height: 8),
          SizedBox(
            height: 36,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  height: 14,
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(7),
                    gradient: LinearGradient(colors: colors),
                  ),
                ),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 0,
                    activeTrackColor: Colors.transparent,
                    inactiveTrackColor: Colors.transparent,
                    thumbColor: Colors.white,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 11, elevation: 3),
                  ),
                  child: Slider(value: value, min: 0, max: max, onChanged: onChanged),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
                ),
                const SizedBox(width: 14),
                Expanded(child: Text('Couleur personnalisée', style: geist(17, weight: FontWeight.w600, color: p.text))),
              ],
            ),
            const SizedBox(height: 18),
            track('Teinte', _c.hue, 360, [
              for (var h = 0; h <= 360; h += 60) HSLColor.fromAHSL(1, h.toDouble(), _c.saturation, _c.lightness).toColor(),
            ], (v) => setState(() => _c = _c.withHue(v))),
            track('Saturation', _c.saturation, 1, [
              _c.withSaturation(0).toColor(),
              _c.withSaturation(1).toColor(),
            ], (v) => setState(() => _c = _c.withSaturation(v))),
            track('Luminosité', _c.lightness, 1, [
              _c.withLightness(0.15).toColor(),
              _c.withLightness(0.5).toColor(),
              _c.withLightness(0.9).toColor(),
            ], (v) => setState(() => _c = _c.withLightness(v.clamp(0.15, 0.9)))),
            const SizedBox(height: 16),
            PrimaryButton(
              label: 'Appliquer',
              onPressed: () {
                settings.setAccent(color);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class ChangeMasterScreen extends StatefulWidget {
  const ChangeMasterScreen({super.key});

  @override
  State<ChangeMasterScreen> createState() => _ChangeMasterScreenState();
}

class _ChangeMasterScreenState extends State<ChangeMasterScreen> {
  final _cur = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  String? _curError;
  String? _nextError;
  bool _busy = false;

  @override
  void dispose() {
    _cur.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _curError = null;
      _nextError = null;
    });
    if (_next.text.length < minMasterLength) {
      setState(() => _nextError = 'Au moins $minMasterLength caractères.');
      return;
    }
    if (_next.text != _confirm.text) {
      setState(() => _nextError = 'Les deux mots de passe ne correspondent pas.');
      return;
    }
    setState(() => _busy = true);
    final ok = await vault.changeMaster(_cur.text, _next.text);
    if (!mounted) return;
    setState(() => _busy = false);
    if (!ok) {
      setState(() => _curError = 'Mot de passe actuel incorrect.');
      return;
    }
    showToast(context, 'Mot de passe maître modifié');
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.cg.p;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            Row(children: [
              SquareButton(
                icon: Icons.arrow_back_ios_new_rounded,
                label: 'Retour',
                iconSize: 17,
                onTap: () => Navigator.of(context).pop(),
              ),
            ]),
            const SizedBox(height: 24),
            Text('Mot de passe maître', style: geist(26, weight: FontWeight.w600, color: p.text, spacing: -0.02)),
            const SizedBox(height: 8),
            Text('Le coffre est re-chiffré avec le nouveau mot de passe. La clé de récupération reste valable.',
                style: geist(15, color: p.muted, height: 1.45)),
            const SizedBox(height: 28),
            CgField(label: 'Mot de passe actuel', controller: _cur, secret: true, error: _curError, autofocus: true),
            const SizedBox(height: 16),
            CgField(label: 'Nouveau mot de passe', controller: _next, secret: true),
            const SizedBox(height: 16),
            CgField(
              label: 'Confirmer',
              controller: _confirm,
              secret: true,
              error: _nextError,
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 24),
            PrimaryButton(label: 'Modifier', loading: _busy, onPressed: _submit),
          ],
        ),
      ),
    );
  }
}
