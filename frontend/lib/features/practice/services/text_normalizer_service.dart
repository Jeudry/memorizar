import 'package:diacritic/diacritic.dart';

class TextNormalizerService {
  const TextNormalizerService();

  String normalize(String value) {
    final lowered = removeDiacritics(value).toLowerCase();
    final cleaned = lowered.replaceAll(RegExp(r'[^a-z0-9\s]'), ' ');
    return cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  List<String> tokenize(String value) {
    final normalized = normalize(value);
    if (normalized.isEmpty) return const [];
    return normalized.split(' ');
  }
}
