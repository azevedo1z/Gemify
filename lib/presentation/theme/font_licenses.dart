import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

void registerFontLicenses() => LicenseRegistry.addLicense(_fontLicenses);

Stream<LicenseEntry> _fontLicenses() async* {
  final text = await rootBundle.loadString('assets/fonts/OFL.txt');
  yield LicenseEntryWithLineBreaks(const ['Barlow Condensed'], text);
}
