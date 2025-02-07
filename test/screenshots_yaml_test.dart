import 'dart:io';

import 'package:screenshots/src/config.dart';
import 'package:screenshots/src/daemon_client.dart';
import 'package:screenshots/src/globals.dart';
import 'package:screenshots/src/image_processor.dart';
import 'package:screenshots/src/screens.dart';
import 'package:test/test.dart';
import 'package:screenshots/src/fastlane.dart' as fastlane;
import 'package:yaml/yaml.dart';

final screenshotsYaml = '''
# Screen capture tests
tests:
  - example/test_driver/main.dart

# Interim location of screenshots from tests before processing
staging: /tmp/screenshots

# A list of locales supported in app
locales:
#  - fr_CA
  - en_US
#  - de_DE

# A list of devices to emulate
devices:
  ios:
    iPhone 5c:
      frame: false
    iPhone X:
    iPhone 7 Plus:
      frame: false
#    - iPad Pro (12.9-inch) (2nd generation)
#   "iPhone 6",
#   "iPhone 6 Plus",
#   "iPhone 5",
#   "iPhone 4s",
#   "iPad Retina",
#   "iPad Pro"
  android:
    Nexus 5X:

# Frame screenshots
frame: true
''';

void main() {
  test('config info for app from string', () {
    final expected = {
      'tests': ['example/test_driver/main.dart'],
      'locales': ['en_US'],
      'frame': true,
      'devices': {
        'android': {'Nexus 5X': null},
        'ios': {
          'iPhone 7 Plus': {'frame': false},
          'iPhone X': null,
          'iPhone 5c': {'frame': false}
        }
      },
      'staging': '/tmp/screenshots'
    };

    final Map screenshotsConfig = loadYaml(screenshotsYaml);
    expect(screenshotsConfig, expected);
  });

  test('config info for app from file', () {
    final expected = {
      'tests': ['test_driver/main.dart'],
      'locales': ['en-US'],
      'frame': true,
      'devices': {
        'android': {'Nexus 6P': null},
        'ios': {
          'iPhone X': null,
          'iPhone 5c': {'frame': false}
        }
      },
      'staging': '/tmp/screenshots'
    };

    final Config config = Config(configPath: 'test/screenshots_test.yaml');
    Map appConfig = config.configInfo;
    expect(appConfig, expected);
  });

  test('validate config file', () async {
    final Screens screens = Screens();
    await screens.init();
    final Config config = Config(configPath: 'test/screenshots_test.yaml');
    final daemonClient = DaemonClient();
    await daemonClient.start;
    // for this test change directory
    final origDir = Directory.current;
    Directory.current = 'example';
    expect(
        await config.validate(
          screens,
          await daemonClient.devices,
          await daemonClient.emulators,
        ),
        true);
    // allow other tests to continue
    Directory.current = origDir;
  });

  test('clear all destination directories on init', () async {
    final Screens screens = Screens();
    await screens.init();
    final Map config = loadYaml(screenshotsYaml);
    await fastlane.clearFastlaneDirs(config, screens, RunMode.normal);
  });

  test('check if frame is needed', () {
    final Map config = loadYaml(screenshotsYaml);

    expect(ImageProcessor.isFrameRequired(config, DeviceType.ios, 'iPhone X'),
        true);
    expect(
        ImageProcessor.isFrameRequired(config, DeviceType.ios, 'iPhone 7 Plus'),
        false);
    expect(
        ImageProcessor.isFrameRequired(config, DeviceType.android, 'Nexus 5X'),
        true);
    expect(ImageProcessor.isFrameRequired(config, DeviceType.ios, 'iPhone 5c'),
        false);
    final unknownDevice = 'unknown';
    expect(
        () => ImageProcessor.isFrameRequired(config, DeviceType.ios, 'unknown'),
        throwsA('Error: device \'$unknownDevice\' not found'));
  });
}
