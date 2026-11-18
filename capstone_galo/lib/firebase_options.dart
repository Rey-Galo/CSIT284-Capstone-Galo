// PLACEHOLDER. Replace this file by running, from the project root:
//
//   dart pub global activate flutterfire_cli
//   flutterfire configure --platforms=android
//
// That command connects the app to your Firebase project and overwrites this
// file with the real settings.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform => throw UnsupportedError(
    'Firebase is not configured yet. Run `flutterfire configure '
    '--platforms=android` to generate lib/firebase_options.dart.',
  );
}
