import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDWTiijj9GWeusgXkZfV-9Iy9EXVVsXkwk',
    appId: '1:774659079181:web:20c35bb0255a93e9c5e944',
    messagingSenderId: '774659079181',
    projectId: 'project-3954038220376677871',
    authDomain: 'project-3954038220376677871.firebaseapp.com',
    storageBucket: 'project-3954038220376677871.firebasestorage.app',
    measurementId: 'G-Y3DX52QF8Y',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBMgA7UB-8jr3c7jmWwn5VSqWDKCUb7zcU',
    appId: '1:774659079181:android:483e87437f386193c5e944',
    messagingSenderId: '774659079181',
    projectId: 'project-3954038220376677871',
    storageBucket: 'project-3954038220376677871.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAzYQ1A0P7ZspEUDzgTOhLdEvlLpYrFGW4',
    appId: '1:774659079181:ios:2722485ed294dec8c5e944',
    messagingSenderId: '774659079181',
    projectId: 'project-3954038220376677871',
    storageBucket: 'project-3954038220376677871.firebasestorage.app',
    iosBundleId: 'com.example.cashNote',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyAzYQ1A0P7ZspEUDzgTOhLdEvlLpYrFGW4',
    appId: '1:774659079181:ios:2722485ed294dec8c5e944',
    messagingSenderId: '774659079181',
    projectId: 'project-3954038220376677871',
    storageBucket: 'project-3954038220376677871.firebasestorage.app',
    iosBundleId: 'com.example.cashNote',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyDWTiijj9GWeusgXkZfV-9Iy9EXVVsXkwk',
    appId: '1:774659079181:web:0f8f006d02843835c5e944',
    messagingSenderId: '774659079181',
    projectId: 'project-3954038220376677871',
    authDomain: 'project-3954038220376677871.firebaseapp.com',
    storageBucket: 'project-3954038220376677871.firebasestorage.app',
    measurementId: 'G-YNBS2G6TF3',
  );
}
