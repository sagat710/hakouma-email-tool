import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/models/email_message.dart';

/// Naive Bayes spam classifier with SharedPreferences persistence.
class SpamClassifier {
  static const _keySpamWords = 'spam_word_counts';
  static const _keyHamWords = 'ham_word_counts';
  static const _keySpamTotal = 'spam_total_docs';
  static const _keyHamTotal = 'ham_total_docs';

  // word → count (loaded from prefs)
  final Map<String, int> _spamCounts = {};
  final Map<String, int> _hamCounts = {};
  int _spamDocs = 0;
  int _hamDocs = 0;

  bool _loaded = false;

  Future<void> _ensureLoaded() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();

    _spamDocs = prefs.getInt(_keySpamTotal) ?? 0;
    _hamDocs = prefs.getInt(_keyHamTotal) ?? 0;

    final spamRaw = prefs.getStringList(_keySpamWords) ?? [];
    final hamRaw = prefs.getStringList(_keyHamWords) ?? [];

    _parseCounts(spamRaw, _spamCounts);
    _parseCounts(hamRaw, _hamCounts);
    _loaded = true;
  }

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  Future<SpamStatus> classify(EmailMessage msg) async {
    await _ensureLoaded();
    if (_spamDocs + _hamDocs < 10) return SpamStatus.clean; // too little data

    final words = _tokenize('${msg.subject} ${msg.bodyText}');
    final score = _logPosterior(words);

    if (score > 1.0) return SpamStatus.spam;
    if (score > -1.0) return SpamStatus.ambiguous;
    return SpamStatus.clean;
  }

  Future<void> learn(EmailMessage msg, {required bool isSpam}) async {
    await _ensureLoaded();
    final words = _tokenize('${msg.subject} ${msg.bodyText}');
    final target = isSpam ? _spamCounts : _hamCounts;
    for (final w in words) {
      target[w] = (target[w] ?? 0) + 1;
    }
    if (isSpam) {
      _spamDocs++;
    } else {
      _hamDocs++;
    }
    await _persist();
  }

  // ---------------------------------------------------------------------------
  // Internals
  // ---------------------------------------------------------------------------

  /// Returns log(P(spam|words)) - log(P(ham|words)).
  /// Positive → spam; negative → ham.
  double _logPosterior(List<String> words) {
    final totalDocs = _spamDocs + _hamDocs;
    final logPriorSpam = log(_spamDocs / totalDocs);
    final logPriorHam = log(_hamDocs / totalDocs);

    final totalSpamWords =
        _spamCounts.values.fold<int>(0, (s, c) => s + c) + _spamCounts.length;
    final totalHamWords =
        _hamCounts.values.fold<int>(0, (s, c) => s + c) + _hamCounts.length;
    final vocabSize = <String>{..._spamCounts.keys, ..._hamCounts.keys}.length;

    double logSpam = logPriorSpam;
    double logHam = logPriorHam;

    for (final word in words) {
      // Laplace smoothing
      final spamCount = (_spamCounts[word] ?? 0) + 1;
      final hamCount = (_hamCounts[word] ?? 0) + 1;
      logSpam += log(spamCount / (totalSpamWords + vocabSize));
      logHam += log(hamCount / (totalHamWords + vocabSize));
    }
    return logSpam - logHam;
  }

  static List<String> _tokenize(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((w) => w.length > 2)
        .toList();
  }

  static void _parseCounts(List<String> raw, Map<String, int> out) {
    for (final entry in raw) {
      final parts = entry.split(':');
      if (parts.length == 2) {
        out[parts[0]] = int.tryParse(parts[1]) ?? 0;
      }
    }
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keySpamTotal, _spamDocs);
    await prefs.setInt(_keyHamTotal, _hamDocs);
    await prefs.setStringList(
        _keySpamWords, _spamCounts.entries.map((e) => '${e.key}:${e.value}').toList());
    await prefs.setStringList(
        _keyHamWords, _hamCounts.entries.map((e) => '${e.key}:${e.value}').toList());
  }
}

final spamClassifierProvider = SpamClassifier();
