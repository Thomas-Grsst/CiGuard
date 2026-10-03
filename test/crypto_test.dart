import 'package:ciguard/services/crypto.dart';
import 'package:ciguard/services/password_tools.dart';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('seal / unseal round trip, wrong key rejected', () async {
    final salt = randomBytes(16);
    final key = await deriveKey('correct horse', salt, 1000);
    final sealed = await seal([1, 2, 3], key);
    expect(await unseal(Sealed.fromJson(sealed.toJson()), key), [1, 2, 3]);
    final wrong = await deriveKey('wrong', salt, 1000);
    expect(() => unseal(sealed, wrong), throwsA(isA<SecretBoxAuthenticationError>()));
  });

  test('recovery key format', () {
    final k = generateRecoveryKey();
    expect(RegExp(r'^([A-Z2-9]{4}-){5}[A-Z2-9]{4}$').hasMatch(k), isTrue);
    expect(normalizeRecoveryKey(k.toLowerCase().replaceAll('-', ' ')), k.replaceAll('-', ''));
  });

  test('generator honours length and classes', () {
    for (var i = 0; i < 50; i++) {
      final pw = generatePassword(const GeneratorOptions(length: 12, symbols: false));
      expect(pw.length, 12);
      expect(pw.contains(RegExp('[A-Z]')) && pw.contains(RegExp('[a-z]')) && pw.contains(RegExp('[0-9]')), isTrue);
      expect(pw.contains(RegExp('[^A-Za-z0-9]')), isFalse);
    }
    expect(strengthOf('azerty').level, 0);
    expect(strengthOf(generatePassword(const GeneratorOptions())).level, 3);
  });
}
