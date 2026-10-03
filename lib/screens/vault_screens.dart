import 'package:flutter/material.dart';

import '../models.dart';
import '../services/password_tools.dart';
import '../services/platform.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets.dart';
import 'generator.dart';

enum VaultFilter {
  all('Tous'),
  favorites('Favoris'),
  travail('Travail'),
  perso('Perso'),
  autre('Autre');

  const VaultFilter(this.label);
  final String label;
}

class VaultTab extends StatefulWidget {
  const VaultTab({super.key, this.issue, required this.onClearIssue});

  final Issue? issue;
  final VoidCallback onClearIssue;

  @override
  State<VaultTab> createState() => _VaultTabState();
}

class _VaultTabState extends State<VaultTab> {
  final _q = TextEditingController();
  VaultFilter _filter = VaultFilter.all;

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  List<Entry> _visible(List<Entry> all) {
    final q = _q.text.trim().toLowerCase();
    final audit = widget.issue == null ? null : Audit(all);
    final list = all.where((e) {
      if (audit != null && !(audit.issues[e.id]?.contains(widget.issue) ?? false)) return false;
      switch (_filter) {
        case VaultFilter.favorites:
          if (!e.favorite) return false;
        case VaultFilter.travail:
          if (e.category != Category.travail) return false;
        case VaultFilter.perso:
          if (e.category != Category.perso) return false;
        case VaultFilter.autre:
          if (e.category != Category.autre) return false;
        case VaultFilter.all:
          break;
      }
      if (q.isEmpty) return true;
      return e.name.toLowerCase().contains(q) ||
          e.login.toLowerCase().contains(q) ||
          e.url.toLowerCase().contains(q);
    }).toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final cg = context.cg;
    final p = cg.p;
    return ListenableBuilder(
      listenable: vault,
      builder: (context, _) {
        final all = vault.entries;
        final items = _visible(all);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Coffre', style: geist(28, weight: FontWeight.w600, color: p.text, spacing: -0.02)),
                            const SizedBox(height: 2),
                            Text('CiGuard · ${all.length} identifiant${all.length > 1 ? 's' : ''}',
                                style: geist(13, color: p.muted)),
                          ],
                        ),
                      ),
                      SquareButton(icon: Icons.lock_outline_rounded, label: 'Verrouiller maintenant', onTap: vault.lock),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _q,
                    onChanged: (_) => setState(() {}),
                    style: geist(15, color: p.text),
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      isDense: true,
                      filled: true,
                      fillColor: p.surface,
                      hintText: 'Rechercher un nom, un email…',
                      hintStyle: geist(15, color: p.muted),
                      prefixIcon: Icon(Icons.search_rounded, size: 19, color: p.muted),
                      suffixIcon: _q.text.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Effacer',
                              icon: Icon(Icons.close_rounded, size: 18, color: p.muted),
                              onPressed: () => setState(_q.clear),
                            ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 13),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: p.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: cg.accent),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  if (widget.issue != null) ...[
                    _Chip(
                      label: widget.issue!.label,
                      selected: true,
                      color: cg.warn,
                      trailing: Icons.close_rounded,
                      onTap: widget.onClearIssue,
                    ),
                    const SizedBox(width: 8),
                  ],
                  for (final f in VaultFilter.values) ...[
                    _Chip(label: f.label, selected: _filter == f, onTap: () => setState(() => _filter = f)),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: items.isEmpty
                  ? _Empty(hasAny: all.isNotEmpty)
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, i) => _EntryTile(entry: items[i]),
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.selected, required this.onTap, this.color, this.trailing});

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? color;
  final IconData? trailing;

  @override
  Widget build(BuildContext context) {
    final cg = context.cg;
    final p = cg.p;
    final fill = color ?? p.text;
    final shape = StadiumBorder(side: BorderSide(color: selected ? fill : p.border));
    final fg = selected ? (fill.computeLuminance() > 0.4 ? const Color(0xFF0D0E10) : Colors.white) : p.soft;
    return Material(
      color: selected ? fill : Colors.transparent,
      shape: shape,
      child: InkWell(
        customBorder: shape,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              Text(label, style: geist(13, weight: selected ? FontWeight.w500 : FontWeight.w400, color: fg)),
              if (trailing != null) ...[const SizedBox(width: 4), Icon(trailing, size: 15, color: fg)],
            ],
          ),
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.hasAny});

  final bool hasAny;

  @override
  Widget build(BuildContext context) {
    final p = context.cg.p;
    return Padding(
      padding: const EdgeInsets.fromLTRB(40, 40, 40, 120),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(hasAny ? Icons.search_off_rounded : Icons.inventory_2_outlined, size: 40, color: p.muted),
          const SizedBox(height: 14),
          Text(hasAny ? 'Aucun résultat' : 'Coffre vide',
              style: geist(17, weight: FontWeight.w600, color: p.text)),
          const SizedBox(height: 6),
          Text(
            hasAny ? 'Essayez un autre mot ou un autre filtre.' : 'Appuyez sur + pour enregistrer votre premier identifiant.',
            textAlign: TextAlign.center,
            style: geist(14, color: p.muted, height: 1.45),
          ),
        ],
      ),
    );
  }
}

class _EntryTile extends StatelessWidget {
  const _EntryTile({required this.entry});

  final Entry entry;

  @override
  Widget build(BuildContext context) {
    final cg = context.cg;
    final p = cg.p;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: BorderSide(color: p.divider),
    );
    return Material(
      color: p.surface,
      shape: shape,
      child: InkWell(
        customBorder: shape,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => EntryScreen(id: entry.id)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
          child: Row(
            children: [
              Avatar(name: entry.name, initial: entry.initial),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(entry.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: geist(15, weight: FontWeight.w500, color: p.text)),
                        ),
                        if (entry.favorite) ...[
                          const SizedBox(width: 6),
                          Icon(Icons.star_rounded, size: 14, color: cg.accent),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(entry.login.isEmpty ? '—' : entry.login,
                        maxLines: 1, overflow: TextOverflow.ellipsis, style: geist(13, color: p.muted)),
                  ],
                ),
              ),
              SquareButton(
                icon: Icons.content_copy_rounded,
                label: 'Copier le mot de passe',
                outlined: false,
                iconSize: 18,
                onTap: () => copySecret(context, entry.password),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Détail d'un identifiant.
class EntryScreen extends StatefulWidget {
  const EntryScreen({super.key, required this.id});

  final String id;

  @override
  State<EntryScreen> createState() => _EntryScreenState();
}

class _EntryScreenState extends State<EntryScreen> {
  bool _reveal = false;

  Future<void> _delete(Entry e) async {
    final cg = context.cg;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer l’identifiant ?'),
        content: Text('« ${e.name} » sera effacé du coffre. Cette action est définitive.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            style: TextButton.styleFrom(foregroundColor: cg.p.muted),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: cg.danger),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    Navigator.of(context).pop();
    await vault.delete(e.id);
  }

  @override
  Widget build(BuildContext context) {
    final cg = context.cg;
    final p = cg.p;
    return ListenableBuilder(
      listenable: vault,
      builder: (context, _) {
        final e = vault.byId(widget.id);
        if (e == null) return Scaffold(backgroundColor: p.bg);
        final s = strengthOf(e.password);
        final reused = Audit(vault.entries).isReused(e.id);
        return Scaffold(
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              children: [
                Row(
                  children: [
                    SquareButton(
                      icon: Icons.arrow_back_ios_new_rounded,
                      label: 'Retour',
                      iconSize: 17,
                      onTap: () => Navigator.of(context).pop(),
                    ),
                    const Spacer(),
                    SquareButton(
                      icon: e.favorite ? Icons.star_rounded : Icons.star_border_rounded,
                      label: e.favorite ? 'Retirer des favoris' : 'Ajouter aux favoris',
                      color: e.favorite ? cg.accent : p.muted,
                      onTap: () => vault.upsert(e.copyWith(favorite: !e.favorite)),
                    ),
                    const SizedBox(width: 8),
                    _TextPill(
                      label: 'Modifier',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(builder: (_) => EditScreen(entry: e)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Avatar(name: e.name, initial: e.initial, size: 60),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(e.name, style: geist(26, weight: FontWeight.w600, color: p.text, spacing: -0.02)),
                          const SizedBox(height: 4),
                          Text('${e.category.label} · modifié ${relativeTime(e.updatedAt)}',
                              style: geist(13, color: p.muted)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                CgCard(
                  child: Column(
                    children: [
                      _FieldRow(
                        label: 'Email / identifiant',
                        value: e.login.isEmpty ? '—' : e.login,
                        actions: [
                          if (e.login.isNotEmpty)
                            SquareButton(
                              icon: Icons.content_copy_rounded,
                              label: 'Copier l’identifiant',
                              outlined: false,
                              iconSize: 18,
                              onTap: () => copySecret(context, e.login, what: 'Identifiant'),
                            ),
                        ],
                      ),
                      _FieldRow(
                        label: 'Mot de passe',
                        value: _reveal ? e.password : '•' * e.password.length.clamp(8, 20),
                        mono: true,
                        actions: [
                          SquareButton(
                            icon: _reveal ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            label: _reveal ? 'Masquer le mot de passe' : 'Afficher le mot de passe',
                            outlined: false,
                            onTap: () => setState(() => _reveal = !_reveal),
                          ),
                          SquareButton(
                            icon: Icons.content_copy_rounded,
                            label: 'Copier le mot de passe',
                            outlined: false,
                            iconSize: 18,
                            onTap: () => copySecret(context, e.password),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            StrengthBar(strength: s),
                            const SizedBox(height: 8),
                            Text(
                              '${s.label} · ${e.password.length} caractères · ${reused ? 'réutilisé' : 'unique'}',
                              style: geist(12, color: reused ? cg.warn : p.muted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (e.url.isNotEmpty || e.note.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  CgCard(
                    child: Column(
                      children: [
                        if (e.url.isNotEmpty) _FieldRow(label: 'Site web', value: e.url, divider: e.note.isNotEmpty),
                        if (e.note.isNotEmpty) _FieldRow(label: 'Note', value: e.note, divider: false, soft: true),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                if (settings.clearClipboard)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text('Le presse-papiers est vidé 30 s après une copie',
                        textAlign: TextAlign.center, style: geist(12, color: p.muted)),
                  ),
                GhostButton(
                  label: 'Supprimer l’identifiant',
                  color: cg.danger,
                  borderColor: cg.dangerBorder,
                  onPressed: () => _delete(e),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TextPill extends StatelessWidget {
  const _TextPill({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.cg.p;
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: p.border));
    return Material(
      color: p.surface,
      shape: shape,
      child: InkWell(
        customBorder: shape,
        onTap: onTap,
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          child: Text(label, style: geist(14, weight: FontWeight.w500, color: p.text)),
        ),
      ),
    );
  }
}

class _FieldRow extends StatelessWidget {
  const _FieldRow({
    required this.label,
    required this.value,
    this.actions = const [],
    this.mono = false,
    this.divider = true,
    this.soft = false,
  });

  final String label;
  final String value;
  final List<Widget> actions;
  final bool mono;
  final bool divider;
  final bool soft;

  @override
  Widget build(BuildContext context) {
    final p = context.cg.p;
    return Container(
      decoration: BoxDecoration(border: divider ? Border(bottom: BorderSide(color: p.divider)) : null),
      padding: EdgeInsets.fromLTRB(16, 14, actions.isEmpty ? 16 : 6, 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: geist(12, color: p.muted)),
                const SizedBox(height: 4),
                SelectableText(
                  value,
                  style: mono
                      ? geist(16, mono: true, color: p.text, spacing: 0.04)
                      : geist(soft ? 15 : 16, color: soft ? p.soft : p.text, height: 1.4),
                ),
              ],
            ),
          ),
          ...actions,
        ],
      ),
    );
  }
}

/// Ajout / modification d'un identifiant, avec générateur intégré.
class EditScreen extends StatefulWidget {
  const EditScreen({super.key, this.entry});

  final Entry? entry;

  @override
  State<EditScreen> createState() => _EditScreenState();
}

class _EditScreenState extends State<EditScreen> {
  late final Entry? _e = widget.entry;
  late final _name = TextEditingController(text: _e?.name ?? '');
  late final _login = TextEditingController(text: _e?.login ?? '');
  late final _pw = TextEditingController(text: _e?.password ?? generatePassword(_opts));
  late final _url = TextEditingController(text: _e?.url ?? '');
  late final _note = TextEditingController(text: _e?.note ?? '');
  late Category _cat = _e?.category ?? Category.perso;
  GeneratorOptions _opts = const GeneratorOptions();
  String? _nameError;
  bool _saving = false;

  @override
  void dispose() {
    for (final c in [_name, _login, _pw, _url, _note]) {
      c.dispose();
    }
    super.dispose();
  }

  void _regen([GeneratorOptions? o]) => setState(() {
        if (o != null) _opts = o;
        _pw.text = generatePassword(_opts);
      });

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) {
      setState(() => _nameError = 'Donnez un nom à cet identifiant.');
      return;
    }
    setState(() => _saving = true);
    final now = DateTime.now();
    final old = _e;
    final entry = old == null
        ? Entry(
            id: vault.newId(),
            name: _name.text.trim(),
            login: _login.text.trim(),
            password: _pw.text,
            url: _url.text.trim(),
            note: _note.text.trim(),
            category: _cat,
            createdAt: now,
            updatedAt: now,
            passwordChangedAt: now,
          )
        : old.copyWith(
            name: _name.text.trim(),
            login: _login.text.trim(),
            password: _pw.text,
            url: _url.text.trim(),
            note: _note.text.trim(),
            category: _cat,
            updatedAt: now,
            passwordChangedAt: old.password == _pw.text ? null : now,
          );
    await vault.upsert(entry);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final cg = context.cg;
    final p = cg.p;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
              child: Row(
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(foregroundColor: p.muted),
                    child: Text('Annuler', style: geist(15, color: p.muted)),
                  ),
                  Expanded(
                    child: Text(_e == null ? 'Nouvel identifiant' : 'Modifier',
                        textAlign: TextAlign.center, style: geist(17, weight: FontWeight.w600, color: p.text)),
                  ),
                  TextButton(onPressed: _saving ? null : _save, child: const Text('Enregistrer')),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                children: [
                  CgField(
                    label: 'Nom',
                    controller: _name,
                    hint: 'Notion, Banque, Wi-Fi…',
                    autofocus: _e == null,
                    error: _nameError,
                    capitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 14),
                  CgField(
                    label: 'Email / identifiant',
                    controller: _login,
                    hint: 'nom@exemple.fr',
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 14),
                  CgField(
                    label: 'Mot de passe',
                    controller: _pw,
                    mono: true,
                    highlight: true,
                    onChanged: (_) => setState(() {}),
                    trailing: IconButton(
                      tooltip: 'Générer un nouveau mot de passe',
                      onPressed: _regen,
                      icon: Icon(Icons.autorenew_rounded, size: 20, color: cg.accent),
                    ),
                  ),
                  const SizedBox(height: 16),
                  GeneratorPanel(options: _opts, strength: strengthOf(_pw.text), onChanged: _regen),
                  const SizedBox(height: 18),
                  const SectionLabel('Catégorie'),
                  Row(
                    children: [
                      for (final c in Category.values) ...[
                        if (c != Category.values.first) const SizedBox(width: 8),
                        Expanded(child: _CategoryButton(category: c, selected: _cat == c, onTap: () => setState(() => _cat = c))),
                      ],
                    ],
                  ),
                  const SizedBox(height: 18),
                  CgField(
                    label: 'Site web',
                    controller: _url,
                    hint: 'exemple.fr',
                    keyboardType: TextInputType.url,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 14),
                  CgField(
                    label: 'Note',
                    controller: _note,
                    hint: 'Codes de secours, question secrète…',
                    maxLines: 4,
                    capitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 28),
                  PrimaryButton(label: 'Enregistrer dans le coffre', loading: _saving, onPressed: _save),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryButton extends StatelessWidget {
  const _CategoryButton({required this.category, required this.selected, required this.onTap});

  final Category category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cg = context.cg;
    final p = cg.p;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: BorderSide(color: selected ? cg.accent : p.border, width: selected ? 1.3 : 1),
    );
    return Material(
      color: selected ? p.raised : Colors.transparent,
      shape: shape,
      child: InkWell(
        customBorder: shape,
        onTap: onTap,
        child: SizedBox(
          height: 44,
          child: Center(
            child: Text(category.label,
                style: geist(14, weight: selected ? FontWeight.w500 : FontWeight.w400, color: selected ? p.text : p.muted)),
          ),
        ),
      ),
    );
  }
}
