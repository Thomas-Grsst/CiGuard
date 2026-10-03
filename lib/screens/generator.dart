import 'package:flutter/material.dart';

import '../services/password_tools.dart';
import '../services/platform.dart';
import '../theme.dart';
import '../widgets.dart';

/// Panneau de réglages du générateur (longueur + classes de caractères).
class GeneratorPanel extends StatelessWidget {
  const GeneratorPanel({super.key, required this.options, required this.strength, required this.onChanged});

  final GeneratorOptions options;
  final Strength strength;
  final ValueChanged<GeneratorOptions> onChanged;

  @override
  Widget build(BuildContext context) {
    final cg = context.cg;
    final p = cg.p;
    final o = options;
    final enabled = [o.upper, o.lower, o.digits, o.symbols].where((x) => x).length;
    Widget opt(String label, String sample, bool on, GeneratorOptions Function(bool) next) {
      final shape = RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: on ? cg.accent : p.border, width: on ? 1.2 : 1),
      );
      return Material(
        color: on ? p.raised : Colors.transparent,
        shape: shape,
        child: InkWell(
          customBorder: shape,
          // Au moins une classe reste active.
          onTap: on && enabled == 1 ? null : () => onChanged(next(!on)),
          child: Semantics(
            toggled: on,
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Expanded(child: Text(label, style: geist(13, color: on ? p.text : p.muted))),
                  Text(sample, style: geist(12, mono: true, color: (on ? p.text : p.muted).withValues(alpha: 0.8))),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return CgCard(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text('Générateur', style: geist(14, weight: FontWeight.w600, color: p.text))),
              Text(strength.label,
                  style: geist(12, weight: FontWeight.w500, color: strengthColor(cg, strength.level))),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: Text('Longueur', style: geist(13, color: p.muted))),
              Text('${o.length}', style: geist(13, mono: true, color: p.text)),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(overlayShape: const RoundSliderOverlayShape(overlayRadius: 18)),
            child: Slider(
              value: o.length.toDouble(),
              min: 8,
              max: 40,
              divisions: 32,
              label: '${o.length}',
              onChanged: (v) => onChanged(o.copyWith(length: v.round())),
            ),
          ),
          const SizedBox(height: 4),
          GridView.count(
            crossAxisCount: 2,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 3.4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              opt('Majuscules', 'A–Z', o.upper, (v) => o.copyWith(upper: v)),
              opt('Minuscules', 'a–z', o.lower, (v) => o.copyWith(lower: v)),
              opt('Chiffres', '0–9', o.digits, (v) => o.copyWith(digits: v)),
              opt('Symboles', r'!#$', o.symbols, (v) => o.copyWith(symbols: v)),
            ],
          ),
        ],
      ),
    );
  }
}

/// Onglet « Générateur » autonome.
class GeneratorTab extends StatefulWidget {
  const GeneratorTab({super.key});

  @override
  State<GeneratorTab> createState() => _GeneratorTabState();
}

class _GeneratorTabState extends State<GeneratorTab> {
  GeneratorOptions _o = const GeneratorOptions();
  late String _pw = generatePassword(_o);

  void _regen([GeneratorOptions? o]) => setState(() {
        if (o != null) _o = o;
        _pw = generatePassword(_o);
      });

  @override
  Widget build(BuildContext context) {
    final cg = context.cg;
    final p = cg.p;
    final s = strengthOf(_pw);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      children: [
        Text('Générateur', style: geist(28, weight: FontWeight.w600, color: p.text, spacing: -0.02)),
        const SizedBox(height: 4),
        Text('Mots de passe aléatoires, générés sur l’appareil', style: geist(13, color: p.muted)),
        const SizedBox(height: 20),
        CgCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: SelectableText(
                  _pw,
                  key: ValueKey(_pw),
                  textAlign: TextAlign.center,
                  style: geist(_pw.length > 28 ? 17 : 21, mono: true, weight: FontWeight.w500, color: p.text, height: 1.4),
                ),
              ),
              const SizedBox(height: 18),
              StrengthBar(strength: s),
              const SizedBox(height: 8),
              Text('${s.label} · ${_pw.length} caractères · ${s.bits.round()} bits d’entropie',
                  textAlign: TextAlign.center, style: geist(12, color: p.muted)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: GhostButton(label: 'Régénérer', icon: Icons.autorenew_rounded, onPressed: _regen),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SizedBox(
                height: 50,
                child: PrimaryButton(
                  label: 'Copier',
                  icon: Icons.content_copy_rounded,
                  onPressed: () => copySecret(context, _pw),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        GeneratorPanel(options: _o, strength: s, onChanged: _regen),
      ],
    );
  }
}
