import 'dart:math';

import 'package:flutter/material.dart';

import 'services/password_tools.dart';
import 'theme.dart';

/// Carte de surface : fond légèrement relevé, bord fin.
class CgCard extends StatelessWidget {
  const CgCard({super.key, required this.child, this.padding = EdgeInsets.zero, this.radius = 16});

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final p = context.cg.p;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: p.divider),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

/// Bouton carré 44×44 à icône seule.
class SquareButton extends StatelessWidget {
  const SquareButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
    this.outlined = true,
    this.size = 44,
    this.iconSize = 19,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color? color;
  final bool outlined;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final p = context.cg.p;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: outlined ? BorderSide(color: p.border) : BorderSide.none,
    );
    return Tooltip(
      message: label,
      child: Material(
        color: outlined ? p.surface : Colors.transparent,
        shape: shape,
        child: InkWell(
          customBorder: shape,
          onTap: onTap,
          child: SizedBox(
            width: size,
            height: size,
            child: Icon(icon, size: iconSize, color: color ?? (outlined ? p.text : p.muted)),
          ),
        ),
      ),
    );
  }
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({super.key, required this.label, required this.onPressed, this.loading = false, this.icon});

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final cg = context.cg;
    final enabled = onPressed != null && !loading;
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(14));
    return Material(
      color: enabled ? cg.accent : cg.accent.withValues(alpha: 0.45),
      shape: shape,
      child: InkWell(
        customBorder: shape,
        onTap: enabled ? onPressed : null,
        child: SizedBox(
          height: 54,
          child: Center(
            child: loading
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.4, color: cg.onAccent),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) ...[Icon(icon, size: 19, color: cg.onAccent), const SizedBox(width: 8)],
                      Text(label, style: geist(16, weight: FontWeight.w600, color: cg.onAccent)),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class GhostButton extends StatelessWidget {
  const GhostButton({super.key, required this.label, required this.onPressed, this.color, this.borderColor, this.icon});

  final String label;
  final VoidCallback? onPressed;
  final Color? color;
  final Color? borderColor;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final p = context.cg.p;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: BorderSide(color: borderColor ?? p.border),
    );
    final fg = color ?? p.text;
    return Material(
      color: Colors.transparent,
      shape: shape,
      child: InkWell(
        customBorder: shape,
        onTap: onPressed,
        child: SizedBox(
          height: 50,
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[Icon(icon, size: 18, color: fg), const SizedBox(width: 8)],
                Text(label, style: geist(15, weight: FontWeight.w500, color: fg)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Barre d'étapes du déverrouillage (mot de passe → empreinte).
class StepBar extends StatelessWidget {
  const StepBar({super.key, required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    final cg = context.cg;
    Widget seg(bool on, Widget label) => Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 3,
                decoration: BoxDecoration(
                  color: on ? cg.accent : cg.p.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 8),
              label,
            ],
          ),
        );
    return Row(
      children: [
        seg(
          true,
          step == 1
              ? Text('1 · Mot de passe', style: geist(12, weight: FontWeight.w500, color: cg.p.text))
              : Row(children: [
                  Icon(Icons.check_rounded, size: 14, color: cg.p.muted),
                  const SizedBox(width: 6),
                  Text('Mot de passe vérifié', style: geist(12, color: cg.p.muted)),
                ]),
        ),
        const SizedBox(width: 8),
        seg(
          step == 2,
          Text('2 · Empreinte',
              style: geist(12,
                  weight: step == 2 ? FontWeight.w500 : FontWeight.w400,
                  color: step == 2 ? cg.p.text : cg.p.muted)),
        ),
      ],
    );
  }
}

/// Interrupteur maison (piste 46×28, cible tactile 52×44).
class CgToggle extends StatelessWidget {
  const CgToggle({super.key, required this.value, required this.onChanged, required this.label});

  final bool value;
  final ValueChanged<bool> onChanged;
  final String label;

  @override
  Widget build(BuildContext context) {
    final cg = context.cg;
    return Semantics(
      toggled: value,
      label: label,
      button: true,
      child: InkResponse(
        onTap: () => onChanged(!value),
        radius: 28,
        child: SizedBox(
          width: 52,
          height: 44,
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              width: 46,
              height: 28,
              padding: const EdgeInsets.all(3),
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              decoration: BoxDecoration(
                color: value ? cg.accent : (cg.p.dark ? const Color(0xFF2E3237) : cg.p.border),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: value ? cg.onAccent : (cg.p.dark ? cg.p.muted : Colors.white),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Champ texte au style CiGuard, libellé au-dessus.
class CgField extends StatefulWidget {
  const CgField({
    super.key,
    required this.label,
    required this.controller,
    this.secret = false,
    this.mono = false,
    this.hint,
    this.trailing,
    this.autofocus = false,
    this.onSubmitted,
    this.onChanged,
    this.keyboardType,
    this.maxLines = 1,
    this.error,
    this.highlight = false,
    this.textInputAction,
    this.capitalization = TextCapitalization.none,
  });

  final String label;
  final TextEditingController controller;
  final bool secret;
  final bool mono;
  final String? hint;
  final Widget? trailing;
  final bool autofocus;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final TextInputType? keyboardType;
  final int maxLines;
  final String? error;
  final bool highlight;
  final TextInputAction? textInputAction;
  final TextCapitalization capitalization;

  @override
  State<CgField> createState() => _CgFieldState();
}

class _CgFieldState extends State<CgField> {
  bool _reveal = false;

  @override
  Widget build(BuildContext context) {
    final cg = context.cg;
    final p = cg.p;
    OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: c, width: w),
        );
    final hidden = widget.secret && !_reveal;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: geist(13, weight: FontWeight.w500, color: p.muted)),
        const SizedBox(height: 8),
        TextField(
          controller: widget.controller,
          obscureText: hidden,
          obscuringCharacter: '•',
          autofocus: widget.autofocus,
          autocorrect: false,
          enableSuggestions: !widget.secret && !widget.mono,
          keyboardType: widget.secret
              ? (hidden ? TextInputType.text : TextInputType.visiblePassword)
              : widget.keyboardType,
          textCapitalization: widget.capitalization,
          textInputAction: widget.textInputAction,
          maxLines: widget.secret ? 1 : widget.maxLines,
          minLines: 1,
          onSubmitted: widget.onSubmitted,
          onChanged: widget.onChanged,
          style: widget.mono || widget.secret
              ? geist(16, mono: true, color: p.text, spacing: hidden ? 0.08 : 0.02)
              : geist(16, color: p.text),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: p.surface,
            hintText: widget.hint,
            hintStyle: geist(16, color: p.muted.withValues(alpha: 0.8)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            enabledBorder: border(widget.highlight ? cg.accent : p.border),
            focusedBorder: border(cg.accent, 1.4),
            errorBorder: border(cg.danger),
            focusedErrorBorder: border(cg.danger, 1.4),
            errorText: widget.error,
            errorStyle: geist(12.5, color: cg.danger),
            suffixIcon: widget.trailing ??
                (widget.secret
                    ? IconButton(
                        tooltip: _reveal ? 'Masquer' : 'Afficher',
                        onPressed: () => setState(() => _reveal = !_reveal),
                        icon: Icon(
                          _reveal ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          size: 20,
                          color: p.muted,
                        ),
                      )
                    : null),
          ),
        ),
      ],
    );
  }
}

/// Pastille colorée avec l'initiale du site.
class Avatar extends StatelessWidget {
  const Avatar({super.key, required this.name, required this.initial, this.size = 40});

  final String name;
  final String initial;
  final double size;

  @override
  Widget build(BuildContext context) {
    final cg = context.cg;
    final hash = name.toLowerCase().codeUnits.fold<int>(7, (h, c) => (h * 31 + c) & 0x7fffffff);
    final base = cg.tint(accents[hash % accents.length].color);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: base.withValues(alpha: cg.p.dark ? 0.16 : 0.13),
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      child: Text(initial, style: geist(size * 0.38, weight: FontWeight.w600, color: base)),
    );
  }
}

class StrengthBar extends StatelessWidget {
  const StrengthBar({super.key, required this.strength});

  final Strength strength;

  @override
  Widget build(BuildContext context) {
    final cg = context.cg;
    final color = strengthColor(cg, strength.level);
    return Row(
      children: [
        for (var i = 0; i < 4; i++) ...[
          if (i > 0) const SizedBox(width: 4),
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 4,
              decoration: BoxDecoration(
                color: i <= strength.level && strength.bits > 0 ? color : cg.p.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

Color strengthColor(Cg cg, int level) => switch (level) {
      0 => cg.bad,
      1 => cg.warn,
      _ => cg.accent,
    };

/// Anneau de score de sécurité.
class ScoreRing extends StatelessWidget {
  const ScoreRing({super.key, required this.value, required this.label, this.size = 92});

  final double value;
  final String label;
  final double size;

  @override
  Widget build(BuildContext context) {
    final cg = context.cg;
    return SizedBox(
      width: size,
      height: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: value),
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeOutCubic,
        builder: (context, v, _) => CustomPaint(
          painter: _RingPainter(v, cg.p.border, cg.accent),
          child: Center(child: Text(label, style: geist(26, weight: FontWeight.w600, mono: true, color: cg.p.text))),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.value, this.track, this.color);

  final double value;
  final Color track;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(3.5 + 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, 0, 2 * pi, false, paint..color = track);
    if (value > 0) canvas.drawArc(rect, -pi / 2, 2 * pi * value, false, paint..color = color);
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.value != value || old.color != color || old.track != track;
}

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10, left: 2),
        child: Text(text, style: geist(13, weight: FontWeight.w500, color: context.cg.p.muted)),
      );
}

/// Ligne de réglage avec interrupteur, séparée par un filet.
class ToggleRow extends StatelessWidget {
  const ToggleRow({
    super.key,
    required this.label,
    required this.hint,
    required this.value,
    required this.onChanged,
    this.divider = true,
    this.onTapLabel,
  });

  final String label;
  final String hint;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool divider;
  final VoidCallback? onTapLabel;

  @override
  Widget build(BuildContext context) {
    final p = context.cg.p;
    return Container(
      decoration: BoxDecoration(border: divider ? Border(bottom: BorderSide(color: p.divider)) : null),
      padding: const EdgeInsets.fromLTRB(16, 8, 10, 8),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: onTapLabel ?? () => onChanged(!value),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: geist(15, color: p.text)),
                    const SizedBox(height: 2),
                    Text(hint, style: geist(12, color: p.muted)),
                  ],
                ),
              ),
            ),
          ),
          CgToggle(value: value, onChanged: onChanged, label: label),
        ],
      ),
    );
  }
}

/// Ligne de navigation (titre + sous-titre + chevron).
class NavRow extends StatelessWidget {
  const NavRow({
    super.key,
    required this.icon,
    required this.label,
    this.hint,
    required this.onTap,
    this.divider = true,
    this.color,
  });

  final IconData icon;
  final String label;
  final String? hint;
  final VoidCallback onTap;
  final bool divider;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final cg = context.cg;
    final p = cg.p;
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(border: divider ? Border(bottom: BorderSide(color: p.divider)) : null),
        padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color ?? cg.accent),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: geist(15, color: color ?? p.text)),
                  if (hint != null) ...[
                    const SizedBox(height: 2),
                    Text(hint!, style: geist(12, color: p.muted)),
                  ],
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 20, color: p.muted),
          ],
        ),
      ),
    );
  }
}

/// Clé de récupération mise en avant, avec copie.
class RecoveryKeyCard extends StatelessWidget {
  const RecoveryKeyCard({super.key, required this.recoveryKey, required this.onCopy});

  final String recoveryKey;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final cg = context.cg;
    final groups = recoveryKey.split('-');
    return CgCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.key_rounded, size: 18, color: cg.accent),
              const SizedBox(width: 8),
              Text('Clé de récupération', style: geist(14, weight: FontWeight.w600, color: cg.p.text)),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final g in groups)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: cg.p.raised,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(g, style: geist(18, mono: true, weight: FontWeight.w500, color: cg.p.text, spacing: 0.08)),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: onCopy,
              icon: const Icon(Icons.content_copy_rounded, size: 17),
              label: const Text('Copier la clé'),
            ),
          ),
        ],
      ),
    );
  }
}

class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.icon = Icons.lock_outline_rounded});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final cg = context.cg;
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: cg.p.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: cg.p.border),
      ),
      child: Icon(icon, size: 32, color: cg.accent),
    );
  }
}
