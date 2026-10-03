import 'dart:convert';
import 'dart:isolate';
import 'dart:math';

import 'package:cryptography/cryptography.dart';

/// Itérations PBKDF2-HMAC-SHA256 pour le mot de passe maître.
const passwordIterations = 120000;

/// La clé de récupération a ~120 bits d'entropie : moins d'itérations suffisent.
const recoveryIterations = 20000;

final _aes = AesGcm.with256bits();
final _rng = Random.secure();

List<int> randomBytes(int n) => List<int>.generate(n, (_) => _rng.nextInt(256));

/// Dérive une clé de 256 bits hors du thread UI.
Future<SecretKey> deriveKey(String secret, List<int> salt, int iterations) async {
  final bytes = await Isolate.run(() async {
    final pbkdf2 = Pbkdf2(macAlgorithm: Hmac.sha256(), iterations: iterations, bits: 256);
    final key = await pbkdf2.deriveKeyFromPassword(password: secret, nonce: salt);
    return key.extractBytes();
  });
  return SecretKey(bytes);
}

class Sealed {
  Sealed(this.nonce, this.cipherText, this.mac);

  factory Sealed.fromJson(Map<String, dynamic> j) => Sealed(
        base64Decode(j['n'] as String),
        base64Decode(j['c'] as String),
        base64Decode(j['m'] as String),
      );

  final List<int> nonce;
  final List<int> cipherText;
  final List<int> mac;

  Map<String, dynamic> toJson() => {
        'n': base64Encode(nonce),
        'c': base64Encode(cipherText),
        'm': base64Encode(mac),
      };
}

Future<Sealed> seal(List<int> plain, SecretKey key) async {
  final box = await _aes.encrypt(plain, secretKey: key);
  return Sealed(box.nonce, box.cipherText, box.mac.bytes);
}

/// Lève [SecretBoxAuthenticationError] si la clé est mauvaise.
Future<List<int>> unseal(Sealed s, SecretKey key) =>
    _aes.decrypt(SecretBox(s.cipherText, nonce: s.nonce, mac: Mac(s.mac)), secretKey: key);

const _recoveryAlphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

/// 24 caractères en 6 groupes : XXXX-XXXX-XXXX-XXXX-XXXX-XXXX.
String generateRecoveryKey() {
  final chars = List.generate(24, (_) => _recoveryAlphabet[_rng.nextInt(_recoveryAlphabet.length)]);
  final groups = [for (var i = 0; i < 24; i += 4) chars.sublist(i, i + 4).join()];
  return groups.join('-');
}

String normalizeRecoveryKey(String s) => s.toUpperCase().replaceAll(RegExp('[^A-Z0-9]'), '');
