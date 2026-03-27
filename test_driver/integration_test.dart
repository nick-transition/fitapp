import 'dart:io';
import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() async {
  await integrationDriver(
    onScreenshot: (name, bytes, [args]) async {
      // Save screenshots to the screenshots/ directory
      final file = File('screenshots/$name.png');
      file.writeAsBytesSync(bytes);
      return true;
    },
  );
}
