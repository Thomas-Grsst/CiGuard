enum Category {
  travail('Travail'),
  perso('Perso'),
  autre('Autre');

  const Category(this.label);
  final String label;

  static Category parse(String? s) =>
      Category.values.firstWhere((c) => c.name == s, orElse: () => Category.autre);
}

class Entry {
  const Entry({
    required this.id,
    required this.name,
    required this.login,
    required this.password,
    this.url = '',
    this.note = '',
    this.category = Category.perso,
    this.favorite = false,
    required this.createdAt,
    required this.updatedAt,
    required this.passwordChangedAt,
  });

  factory Entry.fromJson(Map<String, dynamic> j) => Entry(
        id: j['id'] as String,
        name: j['name'] as String? ?? '',
        login: j['login'] as String? ?? '',
        password: j['password'] as String? ?? '',
        url: j['url'] as String? ?? '',
        note: j['note'] as String? ?? '',
        category: Category.parse(j['category'] as String?),
        favorite: j['favorite'] as bool? ?? false,
        createdAt: DateTime.parse(j['createdAt'] as String),
        updatedAt: DateTime.parse(j['updatedAt'] as String),
        passwordChangedAt: DateTime.parse(j['passwordChangedAt'] as String),
      );

  final String id;
  final String name;
  final String login;
  final String password;
  final String url;
  final String note;
  final Category category;
  final bool favorite;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime passwordChangedAt;

  String get initial => name.trim().isEmpty ? '?' : name.trim().characters.first.toUpperCase();

  Entry copyWith({
    String? name,
    String? login,
    String? password,
    String? url,
    String? note,
    Category? category,
    bool? favorite,
    DateTime? updatedAt,
    DateTime? passwordChangedAt,
  }) =>
      Entry(
        id: id,
        name: name ?? this.name,
        login: login ?? this.login,
        password: password ?? this.password,
        url: url ?? this.url,
        note: note ?? this.note,
        category: category ?? this.category,
        favorite: favorite ?? this.favorite,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        passwordChangedAt: passwordChangedAt ?? this.passwordChangedAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'login': login,
        'password': password,
        'url': url,
        'note': note,
        'category': category.name,
        'favorite': favorite,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'passwordChangedAt': passwordChangedAt.toIso8601String(),
      };
}

extension on String {
  Iterable<String> get characters => runes.map(String.fromCharCode);
}
