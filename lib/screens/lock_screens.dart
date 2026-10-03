import 'dart:async';

import 'package:flutter/material.dart';

import '../services/password_tools.dart';
import '../services/platform.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets.dart';

const minMasterLength = 8;

/// Premier lancement : création du mot de passe maître puis affichage de la clé de récupération.
class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _pw = TextEditingController();
  final _confirm = TextEditingController();
  String? _error;
  bool _busy = false;
  String? _recovery;
  bool _saved = false;

  @override
  void dispose() {
    _pw.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final pw = _pw.text;
    if (pw.length < minMasterLength) {
      setState(() => _error = 'Au moins $minMasterLength caractères.');
      return;
    }
    if (pw != _confirm.text) {
      setState(() => _error = 'Les deux mots de passe ne correspondent pas.');
      return;
    }
    setState(() {
      _error = null;
      _busy = true;
    });
    final rec = await vault.create(pw);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _recovery = rec;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cg = context.cg;
    final p = cg.p;
    final rec = _recovery;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(28, 48, 28, 32),
          child: rec == null ? _form(cg) : _recoveryStep(cg, p, rec),
        ),
      ),
    );
  }

  Widget _form(Cg cg) {
    final s = strengthOf(_pw.text);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Center(child: BrandMark(icon: Icons.shield_outlined)),
        const SizedBox(height: 20),
        Text('Bienvenue sur CiGuard',
            textAlign: TextAlign.center,
            style: geist(26, weight: FontWeight.w600, color: cg.p.text, spacing: -0.02)),
        const SizedBox(height: 8),
        Text(
          'Créez votre mot de passe maître. Il chiffre tout le coffre et n’est enregistré nulle part : ne l’oubliez pas.',
          textAlign: TextAlign.center,
          style: geist(15, color: cg.p.muted, height: 1.45),
        ),
        const SizedBox(height: 36),
        CgField(
          label: 'Mot de passe maître',
          controller: _pw,
          secret: true,
          autofocus: true,
          textInputAction: TextInputAction.next,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 10),
        StrengthBar(strength: s),
        const SizedBox(height: 6),
        Text(_pw.text.isEmpty ? 'Une phrase de 4 mots ou plus est idéale' : '${s.label} · ${_pw.text.length} caractères',
            style: geist(12, color: cg.p.muted)),
        const SizedBox(height: 18),
        CgField(
          label: 'Confirmer',
          controller: _confirm,
          secret: true,
          error: _error,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _create(),
        ),
        const SizedBox(height: 24),
        PrimaryButton(label: 'Créer le coffre', loading: _busy, onPressed: _create),
      ],
    );
  }

  Widget _recoveryStep(Cg cg, Palette p, String rec) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Center(child: BrandMark(icon: Icons.key_rounded)),
        const SizedBox(height: 20),
        Text('Notez votre clé',
            textAlign: TextAlign.center, style: geist(26, weight: FontWeight.w600, color: p.text, spacing: -0.02)),
        const SizedBox(height: 8),
        Text(
          'Si vous oubliez le mot de passe maître, cette clé est le seul moyen de rouvrir le coffre. Elle ne sera plus affichée.',
          textAlign: TextAlign.center,
          style: geist(15, color: p.muted, height: 1.45),
        ),
        const SizedBox(height: 28),
        RecoveryKeyCard(recoveryKey: rec, onCopy: () => copySecret(context, rec, what: 'Clé')),
        const SizedBox(height: 18),
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => setState(() => _saved = !_saved),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Checkbox(
                  value: _saved,
                  onChanged: (v) => setState(() => _saved = v ?? false),
                  activeColor: cg.accent,
                  checkColor: cg.onAccent,
                  side: BorderSide(color: p.muted, width: 1.5),
                ),
                const SizedBox(width: 4),
                Expanded(child: Text('J’ai noté ma clé dans un endroit sûr', style: geist(14.5, color: p.text))),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        PrimaryButton(label: 'Ouvrir le coffre', onPressed: _saved ? vault.finishSetup : null),
      ],
    );
  }
}

/// Étape 1 : mot de passe maître.
class UnlockScreen extends StatefulWidget {
  const UnlockScreen({super.key});

  @override
  State<UnlockScreen> createState() => _UnlockScreenState();
}

class _UnlockScreenState extends State<UnlockScreen> {
  final _pw = TextEditingController();
  bool _busy = false;
  String? _error;
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _startTickIfLocked();
  }

  @override
  void dispose() {
    _tick?.cancel();
    _pw.dispose();
    super.dispose();
  }

  void _startTickIfLocked() {
    _tick?.cancel();
    if (vault.lockoutRemaining == null) return;
    _tick = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (vault.lockoutRemaining == null) t.cancel();
      setState(() {});
    });
  }

  Future<void> _submit() async {
    if (_busy || _pw.text.isEmpty) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final bio = settings.requireBiometric && await Biometrics.available();
    final r = await vault.submitPassword(_pw.text, biometricNext: bio);
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (r == UnlockResult.wrong) {
        final left = maxFailures - vault.failures;
        _error = 'Mot de passe incorrect · $left essai${left > 1 ? 's' : ''} restant${left > 1 ? 's' : ''}';
        _pw.clear();
      } else if (r == UnlockResult.lockedOut) {
        _pw.clear();
        _startTickIfLocked();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cg = context.cg;
    final p = cg.p;
    final lockout = vault.lockoutRemaining;
    final twoSteps = settings.requireBiometric;
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, c) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: c.maxHeight),
              child: IntrinsicHeight(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(28, 56, 28, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Center(child: BrandMark()),
                      const SizedBox(height: 20),
                      Text('CiGuard',
                          textAlign: TextAlign.center,
                          style: geist(28, weight: FontWeight.w600, color: p.text, spacing: -0.02)),
                      const SizedBox(height: 8),
                      Text(
                        twoSteps
                            ? 'Coffre verrouillé. Double vérification :\nmot de passe maître, puis empreinte.'
                            : 'Coffre verrouillé.\nEntrez votre mot de passe maître.',
                        textAlign: TextAlign.center,
                        style: geist(15, color: p.muted, height: 1.45),
                      ),
                      const SizedBox(height: 40),
                      if (twoSteps) ...[const StepBar(step: 1), const SizedBox(height: 28)],
                      if (lockout != null)
                        _LockoutCard(remaining: lockout)
                      else ...[
                        CgField(
                          label: 'Mot de passe maître',
                          controller: _pw,
                          secret: true,
                          highlight: true,
                          autofocus: true,
                          error: _error,
                          textInputAction: TextInputAction.go,
                          onSubmitted: (_) => _submit(),
                        ),
                        const SizedBox(height: 20),
                        PrimaryButton(label: 'Continuer', loading: _busy, onPressed: _submit),
                      ],
                      const Spacer(),
                      const SizedBox(height: 32),
                      if (settings.autoLock)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.schedule_rounded, size: 15, color: p.muted),
                            const SizedBox(width: 8),
                            Text('Verrouillage auto après ${autoLockLabel(settings.autoLockSeconds)} d’inactivité',
                                style: geist(13, color: p.muted)),
                          ],
                        ),
                      const SizedBox(height: 6),
                      Center(
                        child: TextButton(
                          onPressed: () => Navigator.of(context)
                              .push(MaterialPageRoute<void>(builder: (_) => const RecoveryScreen())),
                          style: TextButton.styleFrom(foregroundColor: p.muted),
                          child: Text('Mot de passe oublié ? Clé de récupération',
                              style: geist(13, color: p.muted)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LockoutCard extends StatelessWidget {
  const _LockoutCard({required this.remaining});

  final Duration remaining;

  @override
  Widget build(BuildContext context) {
    final cg = context.cg;
    final m = remaining.inMinutes.toString().padLeft(2, '0');
    final s = (remaining.inSeconds % 60).toString().padLeft(2, '0');
    return CgCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Icon(Icons.lock_clock_outlined, size: 30, color: cg.bad),
          const SizedBox(height: 12),
          Text('Coffre bloqué', style: geist(17, weight: FontWeight.w600, color: cg.p.text)),
          const SizedBox(height: 6),
          Text('$maxFailures échecs consécutifs. Réessayez dans',
              textAlign: TextAlign.center, style: geist(13.5, color: cg.p.muted)),
          const SizedBox(height: 10),
          Text('$m:$s', style: geist(30, mono: true, weight: FontWeight.w500, color: cg.p.text)),
        ],
      ),
    );
  }
}

/// Étape 2 : empreinte digitale.
class BiometricScreen extends StatefulWidget {
  const BiometricScreen({super.key});

  @override
  State<BiometricScreen> createState() => _BiometricScreenState();
}

class _BiometricScreenState extends State<BiometricScreen> with SingleTickerProviderStateMixin {
  String? _error;
  bool _running = false;
  late final AnimationController _pulse =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..repeat(reverse: true);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _auth());
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  Future<void> _auth() async {
    if (_running) return;
    setState(() {
      _running = true;
      _error = null;
    });
    final err = await Biometrics.authenticate();
    if (!mounted) return;
    if (err == null) {
      vault.completeBiometric();
      return;
    }
    setState(() {
      _running = false;
      _error = err;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cg = context.cg;
    final p = cg.p;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) vault.lock();
      },
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 56, 28, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const StepBar(step: 2),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Semantics(
                        button: true,
                        label: 'Lancer la vérification par empreinte',
                        child: GestureDetector(
                          onTap: _auth,
                          child: AnimatedBuilder(
                            animation: _pulse,
                            builder: (context, child) => Container(
                              width: 196,
                              height: 196,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Color.lerp(p.border, cg.accent.withValues(alpha: 0.5), _pulse.value)!,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: child,
                            ),
                            child: Container(
                              width: 156,
                              height: 156,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: p.surface,
                                border: Border.all(color: _error == null ? cg.accent : cg.bad, width: 2),
                              ),
                              child: Icon(Icons.fingerprint_rounded,
                                  size: 84, color: _error == null ? cg.accent : cg.bad),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                      Text('Confirmez votre identité',
                          style: geist(24, weight: FontWeight.w600, color: p.text, spacing: -0.02)),
                      const SizedBox(height: 10),
                      Text(
                        _error ?? 'Posez votre doigt sur le capteur\npour ouvrir le coffre.',
                        textAlign: TextAlign.center,
                        style: geist(15, color: _error == null ? p.muted : cg.danger, height: 1.45),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 18),
                        TextButton.icon(
                          onPressed: _auth,
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                          label: const Text('Réessayer'),
                        ),
                      ],
                    ],
                  ),
                ),
                CgCard(
                  radius: 14,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Icon(Icons.shield_outlined, size: 18, color: p.muted),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text('Les deux facteurs sont obligatoires. $maxFailures échecs = coffre bloqué 15 min.',
                            style: geist(13, color: p.muted, height: 1.4)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                GhostButton(label: 'Annuler', onPressed: vault.lock),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Récupération du coffre avec la clé, puis nouveau mot de passe maître.
class RecoveryScreen extends StatefulWidget {
  const RecoveryScreen({super.key});

  @override
  State<RecoveryScreen> createState() => _RecoveryScreenState();
}

class _RecoveryScreenState extends State<RecoveryScreen> {
  final _key = TextEditingController();
  final _pw = TextEditingController();
  final _confirm = TextEditingController();
  String? _keyError;
  String? _pwError;
  bool _busy = false;

  @override
  void dispose() {
    _key.dispose();
    _pw.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _keyError = null;
      _pwError = null;
    });
    if (_pw.text.length < minMasterLength) {
      setState(() => _pwError = 'Au moins $minMasterLength caractères.');
      return;
    }
    if (_pw.text != _confirm.text) {
      setState(() => _pwError = 'Les deux mots de passe ne correspondent pas.');
      return;
    }
    setState(() => _busy = true);
    final ok = await vault.recover(_key.text, _pw.text);
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (!ok) _keyError = 'Clé de récupération invalide.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.cg.p;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
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
              Text('Récupérer le coffre', style: geist(26, weight: FontWeight.w600, color: p.text, spacing: -0.02)),
              const SizedBox(height: 8),
              Text('Saisissez la clé notée à la création du coffre, puis choisissez un nouveau mot de passe maître.',
                  style: geist(15, color: p.muted, height: 1.45)),
              const SizedBox(height: 28),
              CgField(
                label: 'Clé de récupération',
                controller: _key,
                mono: true,
                hint: 'XXXX-XXXX-XXXX-XXXX-XXXX-XXXX',
                capitalization: TextCapitalization.characters,
                error: _keyError,
                autofocus: true,
              ),
              const SizedBox(height: 16),
              CgField(label: 'Nouveau mot de passe maître', controller: _pw, secret: true),
              const SizedBox(height: 16),
              CgField(
                label: 'Confirmer',
                controller: _confirm,
                secret: true,
                error: _pwError,
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 24),
              PrimaryButton(label: 'Rouvrir le coffre', loading: _busy, onPressed: _submit),
            ],
          ),
        ),
      ),
    );
  }
}
