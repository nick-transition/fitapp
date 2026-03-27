import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyA9zs4JMe5zLfDO7iDYJZBbVoJUHUL3i2M',
    appId: '1:742534666491:web:e1968cf230648410caf85e',
    messagingSenderId: '742534666491',
    projectId: 'fitapp-ns',
    authDomain: 'fitapp-ns.firebaseapp.com',
    storageBucket: 'fitapp-ns.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDYIAmi6pKuJSgqWtOHedDlSvLhE4AGhTs',
    appId: '1:742534666491:android:7e2c2d9d5571cacccaf85e',
    messagingSenderId: '742534666491',
    projectId: 'fitapp-ns',
    storageBucket: 'fitapp-ns.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBonbfG5Trv9-fijpTANuXXZe0VhUyQZ9g',
    appId: '1:742534666491:ios:1c92963f8d13d965caf85e',
    messagingSenderId: '742534666491',
    projectId: 'fitapp-ns',
    storageBucket: 'fitapp-ns.firebasestorage.app',
    iosBundleId: 'com.fitapp.fitapp',
  );
}