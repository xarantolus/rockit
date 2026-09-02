import 'dart:async';

import 'package:flutter/material.dart';
import 'package:rockit/apis/launch_library/api.dart';
import 'package:rockit/apis/launch_library/launch_response.dart';
import 'package:rockit/background/handler.dart';
import 'package:rockit/background/keywords.dart';
import 'package:rockit/l10n/app_localizations.dart';
import 'package:rockit/widgets/addons/app_bar.dart';
import 'package:rockit/widgets/addons/insets.dart';

/// The words to watch for, and how far ahead to watch for each.
class KeywordsPage extends StatefulWidget {
  const KeywordsPage({super.key});

  @override
  State<KeywordsPage> createState() => _KeywordsPageState();
}

class _KeywordsPageState extends State<KeywordsPage> {
  final _handler = BackgroundHandler();

  List<LaunchKeyword>? _keywords;

  /// Everything already cached, so the add sheet can say how many launches a
  /// word matches before it is saved. Cache only — deciding whether to add a
  /// keyword is not worth one of fifteen requests an hour.
  List<Launch> _known = const [];

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final keywords = await _handler.loadKeywords();

    List<Launch> known = const [];
    try {
      final cached = await LaunchLibraryAPI().cachedUpcomingLaunches();
      known = cached?.results ?? const [];
    } catch (e) {
      debugPrint("Could not read cached launches for keyword matching: $e");
    }

    if (mounted) {
      setState(() {
        _keywords = keywords;
        _known = known;
      });
    }
  }

  Future<void> _save(List<LaunchKeyword> keywords) async {
    await _handler.saveKeywords(keywords);

    if (mounted) {
      setState(() => _keywords = keywords);
    }
  }

  Future<void> _add() async {
    final result = await _edit();
    if (result == null) {
      return;
    }

    await _save([...?_keywords, result.keyword]);

    if (result.backfill) {
      await _handler.scanForKeywordMatches(_known, notify: false);
    }
  }

  Future<void> _editAt(int index) async {
    final existing = _keywords![index];
    final result = await _edit(existing: existing);
    if (result == null) {
      return;
    }

    final next = [..._keywords!];
    next[index] = result.keyword;
    await _save(next);

    if (result.backfill) {
      await _handler.scanForKeywordMatches(_known, notify: false);
    }
  }

  Future<void> _deleteAt(int index) async {
    final next = [..._keywords!]..removeAt(index);
    await _save(next);

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.keywordDeleted)),
    );
  }

  Future<_KeywordEdit?> _edit({LaunchKeyword? existing}) {
    return showModalBottomSheet<_KeywordEdit>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _KeywordSheet(existing: existing, known: _known),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final keywords = _keywords;

    return Scaffold(
      appBar: CustomAppBar.create(context, title: localizations.keywords),
      floatingActionButton: FloatingActionButton(
        onPressed: () => unawaited(_add()),
        tooltip: localizations.addKeyword,
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: keywords == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: bottomSystemBarPadding(context),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    localizations.keywordsExplainer,
                    style: TextStyle(
                      color: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                    ),
                  ),
                ),
                if (keywords.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(child: Text(localizations.keywordsEmpty)),
                  ),
                for (var i = 0; i < keywords.length; i++)
                  ListTile(
                    title: Text(keywords[i].text),
                    subtitle: Text(
                      "${localizations.keywordWindow}: "
                      "${localizations.keywordWindowDays(keywords[i].days)}",
                    ),
                    onTap: () => unawaited(_editAt(i)),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      tooltip: localizations.deleteKeyword,
                      onPressed: () => unawaited(_deleteAt(i)),
                    ),
                  ),
              ],
            ),
    );
  }
}

/// What the sheet hands back: the keyword, and whether to apply it to what is
/// already known rather than only to launches found later.
class _KeywordEdit {
  const _KeywordEdit(this.keyword, this.backfill);

  final LaunchKeyword keyword;
  final bool backfill;
}

class _KeywordSheet extends StatefulWidget {
  const _KeywordSheet({required this.existing, required this.known});

  final LaunchKeyword? existing;
  final List<Launch> known;

  @override
  State<_KeywordSheet> createState() => _KeywordSheetState();
}

class _KeywordSheetState extends State<_KeywordSheet> {
  late final _text = TextEditingController(text: widget.existing?.text ?? "");
  late final _days = TextEditingController(
    text: "${widget.existing?.days ?? LaunchKeyword.defaultDays}",
  );

  bool _backfill = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _text.addListener(() => unawaited(_countMatches()));
    _days.addListener(() => unawaited(_countMatches()));
    unawaited(_countMatches());
  }

  @override
  void dispose() {
    _text.dispose();
    _days.dispose();
    super.dispose();
  }

  LaunchKeyword? get _draft {
    final days = int.tryParse(_days.text.trim());
    if (_text.text.trim().isEmpty || days == null || days <= 0) {
      return null;
    }

    return LaunchKeyword(text: _text.text.trim(), days: days);
  }

  /// What this would actually take on, so the checkbox is a decision rather
  /// than a guess.
  ///
  /// The full rule, not just the text match: a word can appear in forty launch
  /// names and only a handful of them be inside the window with a date firm
  /// enough to set reminders against.
  ///
  /// Both halves are kept, because zero to take on means two different things
  /// and the reader cannot tell them apart from the number alone.
  ({int pending, int already}) _matches = (pending: 0, already: 0);

  Future<void> _countMatches() async {
    final draft = _draft;
    final coverage = draft == null
        ? null
        : await BackgroundHandler().keywordCoverage(widget.known, [draft]);

    final next = coverage == null
        ? (pending: 0, already: 0)
        : (
            pending: coverage.pending.length,
            already: coverage.alreadySubscribed,
          );

    if (mounted && next != _matches) {
      setState(() => _matches = next);
    }
  }

  /// What the backfill would do, and what it has no work left to do about.
  ///
  /// Four states rather than a count, because the count alone misreports three
  /// of them: zero reads as "this keyword is broken" when the truth is that it
  /// already ran, and a bare "2 matches" hides that a third launch matched and
  /// is already subscribed — which is visible on the previous screen, so the
  /// number looks simply wrong.
  String _countLabel(AppLocalizations localizations) {
    final (:pending, :already) = _matches;

    if (pending > 0) {
      return already > 0
          ? localizations.keywordBackfillCountWithExisting(pending, already)
          : localizations.keywordBackfillCount(pending);
    }

    return already > 0
        ? localizations.keywordBackfillAllSubscribed(already)
        : localizations.keywordBackfillNone;
  }

  void _submit() {
    final draft = _draft;
    final localizations = AppLocalizations.of(context)!;

    if (draft == null) {
      setState(() {
        _error = _text.text.trim().isEmpty
            ? localizations.keywordNeeded
            : localizations.keywordWindowNeeded;
      });

      return;
    }

    Navigator.of(context).pop(_KeywordEdit(draft, _backfill));
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.existing == null
                ? localizations.addKeyword
                : localizations.editKeyword,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _text,
            autofocus: true,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: localizations.keyword,
              hintText: localizations.keywordHint,
              errorText: _error,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _days,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: localizations.keywordWindow,
              suffixText: localizations.keywordWindowDays(2).split(' ').last,
            ),
          ),
          const SizedBox(height: 8),
          CheckboxListTile(
            value: _backfill,
            onChanged: (v) => setState(() => _backfill = v ?? false),
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            title: Text(localizations.keywordBackfill),
            subtitle: Text(_countLabel(localizations)),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: _submit,
            child: Text(
              widget.existing == null
                  ? localizations.addKeyword
                  : localizations.editKeyword,
            ),
          ),
        ],
      ),
    );
  }
}
