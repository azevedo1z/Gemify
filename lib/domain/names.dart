abstract final class Names {
  static final _whitespace = RegExp(r'\s+');
  static const _combiningMarksStart = 0x0300;
  static const _combiningMarksEnd = 0x036F;
  static const _unaccented = {
    'á': 'a',
    'à': 'a',
    'â': 'a',
    'ã': 'a',
    'ä': 'a',
    'é': 'e',
    'è': 'e',
    'ê': 'e',
    'ë': 'e',
    'í': 'i',
    'ì': 'i',
    'î': 'i',
    'ï': 'i',
    'ó': 'o',
    'ò': 'o',
    'ô': 'o',
    'õ': 'o',
    'ö': 'o',
    'ú': 'u',
    'ù': 'u',
    'û': 'u',
    'ü': 'u',
    'ç': 'c',
    'ñ': 'n',
  };

  static String clean(String raw) => raw.trim().replaceAll(_whitespace, ' ');

  static bool isClean(String name) => clean(name) == name;

  static String key(String name) {
    final buffer = StringBuffer();
    for (final rune in clean(name).toLowerCase().runes) {
      if (rune >= _combiningMarksStart && rune <= _combiningMarksEnd) continue;
      final character = String.fromCharCode(rune);
      buffer.write(_unaccented[character] ?? character);
    }
    return buffer.toString();
  }
}
