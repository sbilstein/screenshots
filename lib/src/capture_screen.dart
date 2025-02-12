import 'dart:async';
import 'dart:io';

import 'globals.dart';

/// Called by integration test to capture images.
Future screenshot(final driver, Map config, String name,
    {Duration timeout = const Duration(seconds: 30),
    bool silent = false}) async {
  // todo: auto-naming scheme
  await driver.waitUntilNoTransientCallbacks(timeout: timeout);
  final pixels = await driver.screenshot();
  final testDir = '${config['staging']}/$kTestScreenshotsDir';
  final file =
      await File('$testDir/$name.$kImageExtension').create(recursive: true);
  await file.writeAsBytes(pixels);
  if (!silent) print('Screenshot $name created');
}
