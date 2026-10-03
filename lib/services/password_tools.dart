import 'dart:math';

import '../models.dart';

const _upper = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
const _lower = 'abcdefghijklmnopqrstuvwxyz';
const _digits = '0123456789';
const _symbols = r'!#$%&*+-=?@^_~.:;';

class GeneratorOptions {
  const GeneratorOptions({
    this.length = 20,
    this.upper = true,
    this.lower = true,
    this.digits = true,
    this.symbols = true,
  });

  final int length;
  final bool upper;
  final bool lower;
  final bool digits;
  final bool symbols;

  GeneratorOptions copyWith({int? length, bool? upper, bool? lower, bool? digits, bool? symbols}) =>
      GeneratorOptions(
        length: length ?? this.length,
        upper: upper ?? this.upper,
        lower: lower ?? this.lower,
        digits: digits ?? this.digits,
        symbols: symbols ?? this.symbols,
      );
}

/// Mot de passe aléatoire (Random.secure) contenant au moins un caractère de chaque classe choisie.
String generatePassword(GeneratorOptions o) {
  final rng = Random.secure();
  final sets = [
    if (o.upper) _upper,
    if (o.lower) _lower,
    if (o.digits) _digits,
    if (o.symbols) _symbols,
  ];
  if (sets.isEmpty) sets.add(_lower);
  final all = sets.join();
  final chars = [for (final s in sets) s[rng.nextInt(s.length)]];
  while (chars.length < o.length) {
    chars.add(all[rng.nextInt(all.length)]);
  }
  for (var i = chars.length - 1; i > 0; i--) {
    final j = rng.nextInt(i + 1);
    final t = chars[i];
    chars[i] = chars[j];
    chars[j] = t;
  }
  return chars.take(o.length).join();
}

class Strength {
  const Strength(this.level, this.label, this.bits);

  /// 0 = faible, 1 = moyen, 2 = fort, 3 = très fort.
  final int level;
  final String label;
  final double bits;
}

const _common = {
  '123456', '1234567', '12345678', '123456789', '1234567890', '1234', '12345', '000000',
  '111111', '123123', '123321', '654321', '666666', '121212', 'password', 'password1',
  'passw0rd', 'p@ssw0rd', 'motdepasse', 'azerty', 'azerty123', 'azertyuiop', 'qwerty',
  'qwerty123', 'qwertz', 'abc123', 'iloveyou', 'jetaime', 'admin', 'welcome', 'bonjour',
  'soleil', 'doudou', 'loulou', 'chouchou', 'marseille', 'football', 'dragon', 'monkey',
  'letmein', 'sunshine', 'princess', 'superman', 'batman', 'pokemon', 'starwars', 'master',
  'hello', 'freedom', 'whatever', 'trustno1', 'coucou', 'toto', 'toto123', 'nicolas', 'camille',
};

bool isCommon(String pw) => _common.contains(pw.toLowerCase());

Strength strengthOf(String pw) {
  if (pw.isEmpty) return const Strength(0, 'Vide', 0);
  var pool = 0;
  if (pw.contains(RegExp('[a-z]'))) pool += 26;
  if (pw.contains(RegExp('[A-Z]'))) pool += 26;
  if (pw.contains(RegExp('[0-9]'))) pool += 10;
  if (pw.contains(RegExp('[^a-zA-Z0-9]'))) pool += 33;
  var bits = pw.length * log(max(pool, 2)) / ln2;
  final unique = pw.split('').toSet().length;
  if (unique < pw.length / 2) bits *= 0.6;
  if (isCommon(pw)) bits = min(bits, 10);
  if (bits < 45) return Strength(0, 'Faible', bits);
  if (bits < 65) return Strength(1, 'Moyen', bits);
  if (bits < 90) return Strength(2, 'Fort', bits);
  return Strength(3, 'Très fort', bits);
}

enum Issue {
  common('Courants', 'Présents dans les listes de mots de passe connus'),
  weak('Faibles', 'Trop courts ou trop simples'),
  reused('Réutilisés', 'Même mot de passe sur plusieurs sites'),
  old('Anciens', 'Pas changés depuis plus d’un an');

  const Issue(this.label, this.hint);
  final String label;
  final String hint;
}

class Audit {
  Audit(List<Entry> entries) {
    final counts = <String, int>{};
    for (final e in entries) {
      counts[e.password] = (counts[e.password] ?? 0) + 1;
    }
    final yearAgo = DateTime.now().subtract(const Duration(days: 365));
    for (final e in entries) {
      final set = <Issue>{};
      if (isCommon(e.password)) {
        set.add(Issue.common);
      } else if (strengthOf(e.password).level == 0) {
        set.add(Issue.weak);
      }
      if (e.password.isNotEmpty && (counts[e.password] ?? 0) > 1) set.add(Issue.reused);
      if (e.passwordChangedAt.isBefore(yearAgo)) set.add(Issue.old);
      issues[e.id] = set;
    }
    total = entries.length;
  }

  final Map<String, Set<Issue>> issues = {};
  late final int total;

  int count(Issue i) => issues.values.where((s) => s.contains(i)).length;

  bool isReused(String id) => issues[id]?.contains(Issue.reused) ?? false;

  int get flagged => issues.values.where((s) => s.isNotEmpty).length;

  int? get score => total == 0 ? null : (100 * (total - flagged) / total).round();
}

String relativeTime(DateTime d) {
  final diff = DateTime.now().difference(d);
  if (diff.inMinutes < 1) return 'à l’instant';
  if (diff.inHours < 1) return 'il y a ${diff.inMinutes} min';
  if (diff.inDays < 1) return 'il y a ${diff.inHours} h';
  if (diff.inDays == 1) return 'hier';
  if (diff.inDays < 30) return 'il y a ${diff.inDays} jours';
  if (diff.inDays < 365) return 'il y a ${diff.inDays ~/ 30} mois';
  final y = diff.inDays ~/ 365;
  return 'il y a $y an${y > 1 ? 's' : ''}';
}
