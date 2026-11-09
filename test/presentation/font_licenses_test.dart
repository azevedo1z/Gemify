import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offmoney/presentation/theme/font_licenses.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'lists the bundled display font under the SIL Open Font License',
    () async {
      addTearDown(LicenseRegistry.reset);

      registerFontLicenses();
      final entries = await LicenseRegistry.licenses.toList();

      final font = entries.singleWhere(
        (entry) => entry.packages.contains('Barlow Condensed'),
      );
      expect(
        font.paragraphs.map((paragraph) => paragraph.text).join('\n'),
        contains('SIL Open Font License'),
      );
    },
  );
}
