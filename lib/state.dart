import 'dart:convert';
import 'dart:io';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';
import 'services/crypto.dart';
import 'services/platform.dart';
import 'theme.dart';

final settings = SettingsStore();
final vault = VaultStore();

late SharedPreferences _prefs;

Future<void> initAppState() async {
  _prefs = await SharedPreferences.getInstance();
  settings._load();
  await vault._init();
}

class SettingsStore extends ChangeNotifier {
  String paletteId = 'graphite';
  Color accent = const Color(0xFF8FA8FF);
  bool autoLock = true;
  int autoLockSeconds = 60;
  bool clearClipboard = true;
  bool blockScreenshots = true;
  bool requireBiometric = true;

  Palette get palette => palettes.firstWhere((p) => p.id == paletteId, orElse: () => palettes.first);

  void _load() {
    paletteId = _prefs.getString('palette') ?? paletteId;
    final a = _prefs.getInt('accent');
    if (a != null) accent = Color(a);
    autoLock = _prefs.getBool('autoLock') ?? autoLock;
    autoLockSeconds = _prefs.getInt('autoLockSeconds') ?? autoLockSeconds;
    clearClipboard = _prefs.getBool('clearClipboard') ?? clearClipboard;
    blockScreenshots = _prefs.getBool('blockScreenshots') ?? blockScreenshots;
    requireBiometric = _prefs.getBool('requireBiometric') ?? requireBiometric;
  }

  void setPalette(String id) {
    paletteId = id;
    _prefs.setString('palette', id);
    notifyListeners();
  }

  void setAccent(Color c) {
    accent = c;
    _prefs.setInt('accent', c.toARGB32());
    notifyListeners();
  }

  void setAutoLock(bool v) {
    autoLock = v;
    _prefs.setBool('autoLock', v);
    notifyListeners();
  }

  void setAutoLockSeconds(int s) {
    autoLockSeconds = s;
    _prefs.setInt('autoLockSeconds', s);
    notifyListeners();
  }

  void setClearClipboard(bool v) {
    clearClipboard = v;
    _prefs.setBool('clearClipboard', v);
    notifyListeners();
  }

  void setBlockScreenshots(bool v) {
    blockScreenshots = v;
    _prefs.setBool('blockScreenshots', v);
    SecurePlatform.setSecure(v);
    notifyListeners();
  }

  void setRequireBiometric(bool v) {
    requireBiometric = v;
    _prefs.setBool('requireBiometric', v);
    notifyListeners();
  }
}

String autoLockLabel(int s) => switch (s) {
      < 60 => '$s s',
      60 => '1 min',
      _ => '${s ~/ 60} min',
    };

enum VaultStatus { loading, empty, locked, needsBiometric, unlocked }

enum UnlockResult { ok, wrong, lockedOut }

const maxFailures = 5;
const lockoutDuration = Duration(minutes: 15);

/// Coffre chiffré.
///
/// Une clé de données aléatoire (DK) chiffre les identifiants en AES-256-GCM.
/// DK est elle-même chiffrée deux fois : par une clé dérivée du mot de passe
/// maître (PBKDF2) et par une clé dérivée de la clé de récupération.
class VaultStore extends ChangeNotifier {
  VaultStatus status = VaultStatus.loading;
  List<Entry> _entries = [];
  SecretKey? _dk;
  Map<String, dynamic>? _file;
  late File _path;

  int failures = 0;
  DateTime? lockedUntil;

  List<Entry> get entries => List.unmodifiable(_entries);

  Entry? byId(String id) {
    for (final e in _entries) {
      if (e.id == id) return e;
    }
    return null;
  }

  Duration? get lockoutRemaining {
    final until = lockedUntil;
    if (until == null) return null;
    final left = until.difference(DateTime.now());
    return left.isNegative ? null : left;
  }

  Future<void> _init() async {
    final dir = await getApplicationSupportDirectory();
    _path = File('${dir.path}/vault.json');
    failures = _prefs.getInt('failures') ?? 0;
    final until = _prefs.getInt('lockedUntil');
    lockedUntil = until == null ? null : DateTime.fromMillisecondsSinceEpoch(until);
    if (await _path.exists()) {
      _file = jsonDecode(await _path.readAsString()) as Map<String, dynamic>;
      status = VaultStatus.locked;
    } else {
      status = VaultStatus.empty;
    }
    notifyListeners();
  }

  /// Crée le coffre et renvoie la clé de récupération à montrer une seule fois.
  Future<String> create(String master) async {
    _dk = SecretKey(randomBytes(32));
    _entries = [];
    _file = {'v': 1};
    final recovery = generateRecoveryKey();
    await _wrap('pw', master, passwordIterations);
    await _wrap('rec', normalizeRecoveryKey(recovery), recoveryIterations);
    await _persist();
    return recovery;
  }

  void finishSetup() {
    status = VaultStatus.unlocked;
    notifyListeners();
  }

  Future<UnlockResult> submitPassword(String pw, {required bool biometricNext}) async {
    if (lockoutRemaining != null) return UnlockResult.lockedOut;
    try {
      final dk = await _unwrap('pw', pw);
      _entries = await _decryptEntries(dk);
      _dk = dk;
    } on SecretBoxAuthenticationError {
      failures++;
      if (failures >= maxFailures) {
        failures = 0;
        lockedUntil = DateTime.now().add(lockoutDuration);
        _prefs.setInt('lockedUntil', lockedUntil!.millisecondsSinceEpoch);
      }
      _prefs.setInt('failures', failures);
      notifyListeners();
      return lockoutRemaining != null ? UnlockResult.lockedOut : UnlockResult.wrong;
    }
    failures = 0;
    lockedUntil = null;
    _prefs.setInt('failures', 0);
    _prefs.remove('lockedUntil');
    status = biometricNext ? VaultStatus.needsBiometric : VaultStatus.unlocked;
    notifyListeners();
    return UnlockResult.ok;
  }

  void completeBiometric() {
    if (status != VaultStatus.needsBiometric) return;
    status = VaultStatus.unlocked;
    notifyListeners();
  }

  void lock() {
    if (status == VaultStatus.empty || status == VaultStatus.loading) return;
    _dk = null;
    _entries = [];
    status = VaultStatus.locked;
    notifyListeners();
  }

  Future<bool> recover(String recoveryKey, String newMaster) async {
    try {
      final dk = await _unwrap('rec', normalizeRecoveryKey(recoveryKey));
      _entries = await _decryptEntries(dk);
      _dk = dk;
    } on SecretBoxAuthenticationError {
      return false;
    }
    await _wrap('pw', newMaster, passwordIterations);
    await _persist();
    failures = 0;
    lockedUntil = null;
    _prefs.setInt('failures', 0);
    _prefs.remove('lockedUntil');
    status = VaultStatus.unlocked;
    notifyListeners();
    return true;
  }

  Future<bool> changeMaster(String current, String next) async {
    try {
      await _unwrap('pw', current);
    } on SecretBoxAuthenticationError {
      return false;
    }
    await _wrap('pw', next, passwordIterations);
    await _persist();
    return true;
  }

  Future<String> regenerateRecovery() async {
    final recovery = generateRecoveryKey();
    await _wrap('rec', normalizeRecoveryKey(recovery), recoveryIterations);
    await _persist();
    return recovery;
  }

  Future<void> upsert(Entry e) async {
    final i = _entries.indexWhere((x) => x.id == e.id);
    if (i < 0) {
      _entries.add(e);
    } else {
      _entries[i] = e;
    }
    notifyListeners();
    await _persist();
  }

  Future<void> delete(String id) async {
    _entries.removeWhere((e) => e.id == id);
    notifyListeners();
    await _persist();
  }

  String newId() => base64UrlEncode(randomBytes(12));

  Future<void> _wrap(String slot, String secret, int iterations) async {
    final salt = randomBytes(16);
    final kek = await deriveKey(secret, salt, iterations);
    final sealed = await seal(await _dk!.extractBytes(), kek);
    _file![slot] = {'s': base64Encode(salt), 'i': iterations, ...sealed.toJson()};
  }

  Future<SecretKey> _unwrap(String slot, String secret) async {
    final j = _file![slot] as Map<String, dynamic>;
    final kek = await deriveKey(secret, base64Decode(j['s'] as String), j['i'] as int);
    return SecretKey(await unseal(Sealed.fromJson(j), kek));
  }

  Future<List<Entry>> _decryptEntries(SecretKey dk) async {
    final data = _file!['data'] as Map<String, dynamic>;
    final plain = await unseal(Sealed.fromJson(data), dk);
    final list = jsonDecode(utf8.decode(plain)) as List<dynamic>;
    return [for (final j in list) Entry.fromJson(j as Map<String, dynamic>)];
  }

  Future<void> _persist() async {
    final plain = utf8.encode(jsonEncode([for (final e in _entries) e.toJson()]));
    _file!['data'] = (await seal(plain, _dk!)).toJson();
    final tmp = File('${_path.path}.tmp');
    await tmp.writeAsString(jsonEncode(_file), flush: true);
    await tmp.rename(_path.path);
  }
}
