import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';

import '../state.dart';

/// Pont natif Android : FLAG_SECURE et presse-papiers marqué « sensible ».
class SecurePlatform {
  static const _ch = MethodChannel('ciguard/secure');

  static Future<void> setSecure(bool on) async {
    try {
      await _ch.invokeMethod('setSecure', on);
    } catch (_) {}
  }

  static Future<void> copy(String text) async {
    try {
      await _ch.invokeMethod('copy', text);
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: text));
    }
  }

  static Future<void> clearClipboard() async {
    try {
      await _ch.invokeMethod('clearClipboard');
    } catch (_) {
      await Clipboard.setData(const ClipboardData(text: ''));
    }
  }
}

Timer? _clipTimer;

Future<void> copySecret(BuildContext context, String text, {String what = 'Mot de passe'}) async {
  await SecurePlatform.copy(text);
  _clipTimer?.cancel();
  final clear = settings.clearClipboard;
  if (clear) _clipTimer = Timer(const Duration(seconds: 30), SecurePlatform.clearClipboard);
  if (!context.mounted) return;
  showToast(context, clear ? '$what copié · effacé dans 30 s' : '$what copié');
}

void showToast(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message), duration: const Duration(seconds: 2)));
}

class Biometrics {
  static final _auth = LocalAuthentication();

  static Future<bool> available() async {
    try {
      if (!await _auth.isDeviceSupported()) return false;
      if (!await _auth.canCheckBiometrics) return false;
      return (await _auth.getAvailableBiometrics()).isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Retourne null si succès, sinon un message d'erreur.
  static Future<String?> authenticate() async {
    try {
      final ok = await _auth.authenticate(
        localizedReason: 'Posez votre doigt sur le capteur pour ouvrir le coffre',
        biometricOnly: true,
        persistAcrossBackgrounding: true,
        authMessages: const [
          AndroidAuthMessages(
            signInTitle: 'CiGuard',
            signInHint: 'Confirmez votre identité',
            cancelButton: 'Annuler',
          ),
        ],
      );
      return ok ? null : 'Empreinte non reconnue.';
    } on LocalAuthException catch (e) {
      return switch (e.code) {
        LocalAuthExceptionCode.userCanceled => 'Vérification annulée.',
        LocalAuthExceptionCode.temporaryLockout => 'Trop d’essais. Réessayez dans un moment.',
        LocalAuthExceptionCode.biometricLockout => 'Capteur bloqué. Déverrouillez le téléphone puis réessayez.',
        LocalAuthExceptionCode.noBiometricsEnrolled => 'Aucune empreinte enregistrée sur ce téléphone.',
        _ => 'Vérification impossible (${e.code.name}).',
      };
    } catch (e) {
      return 'Vérification impossible.';
    }
  }
}
