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
        return android;
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCrbrlQsDMCmEvUAMY2ZQK8_5VLWvZoe_E',
    appId: '1:801625925468:android:ee2382c3a86b750d18c399',
    messagingSenderId: '801625925468',
    projectId: 'creva-healthcare',
    storageBucket: 'creva-healthcare.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCrbrlQsDMCmEvUAMY2ZQK8_5VLWvZoe_E',
    appId: '1:801625925468:android:ee2382c3a86b750d18c399',
    messagingSenderId: '801625925468',
    projectId: 'creva-healthcare',
    storageBucket: 'creva-healthcare.firebasestorage.app',
    iosBundleId: 'com.creva.creva',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCrbrlQsDMCmEvUAMY2ZQK8_5VLWvZoe_E',
    appId: '1:801625925468:android:ee2382c3a86b750d18c399',
    messagingSenderId: '801625925468',
    projectId: 'creva-healthcare',
    storageBucket: 'creva-healthcare.firebasestorage.app',
    authDomain: 'creva-healthcare.firebaseapp.com',
  );
}
