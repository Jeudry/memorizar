import 'package:flutter/material.dart';
import '../app_state.dart';

/// Splits a text into words for study purposes, removing punctuation and extra whitespace.
List<String> studyWords(String text) {
  final cleaned = text
      .replaceAll(RegExp(r'[“”"]'), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  if (cleaned.isEmpty) return const ['Jehová', 'es', 'mi', 'pastor'];
  return cleaned.split(' ');
}

/// Takes the first [count] words from a text.
String firstWords(String text, int count) {
  final words = studyWords(text);
  return words.take(count).join(' ');
}

/// Clips a text to a maximum length, adding ellipsis if truncated.
String clipText(String text, {int maxLength = 34}) {
  if (text.length <= maxLength) return text;
  return '${text.substring(0, maxLength)}...';
}

/// Gets the study text (back) of the active card.
String cardStudyText(BuildContext context) {
  return AppScope.of(context).activeCard.back;
}

/// Gets the source/reference text for the active card.
String cardSourceText(BuildContext context) {
  final store = AppScope.of(context);
  final card = store.activeCard;
  if (store.activeDeck.isBible) return '${card.front} · ${card.source}';
  return '${store.activeDeck.title} · ${card.source}';
}

/// Normalizes a string for comparison by removing accents and non-alphabetic characters.
String normalizeText(String value) {
  const accents = {
    'á': 'a', 'é': 'e', 'í': 'i', 'ó': 'o', 'ú': 'u', 'ü': 'u', 'ñ': 'n',
  };
  var text = value.toLowerCase();
  for (final entry in accents.entries) {
    text = text.replaceAll(entry.key, entry.value);
  }
  return text.replaceAll(RegExp(r'[^a-z]'), '');
}

/// Calculates the similarity between spoken words and target text.
double speechSimilarity(String spoken, String target) {
  final s1 = normalizeText(spoken);
  final s2 = normalizeText(target);
  if (s1.isEmpty || s2.isEmpty) return 0;
  if (s1 == s2) return 1.0;

  // Simple overlap score
  final w1 = s1.split('');
  final w2 = s2.split('');
  var matches = 0;
  final minLen = w1.length < w2.length ? w1.length : w2.length;
  for (var i = 0; i < minLen; i++) {
    if (w1[i] == w2[i]) matches++;
  }
  return matches / s2.length;
}
