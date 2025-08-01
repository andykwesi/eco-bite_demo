// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
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

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyC5Mc33bl1JJF394gCjxcwFIASQCdNHY0M',
    appId: '1:499078252124:android:7c8f8d661e41e07c694899',
    messagingSenderId: '499078252124',
    projectId: 'ecobite-app',
    storageBucket: 'ecobite-app.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBr-CQ6R7N_j14KpCgpgGQwb_geTIlD--M',
    appId: '1:499078252124:ios:49f86b72ae361e84694899',
    messagingSenderId: '499078252124',
    projectId: 'ecobite-app',
    storageBucket: 'ecobite-app.firebasestorage.app',
    iosClientId: '499078252124-8u0n9isrf0tl44lljecsj7smabdel1ma.apps.googleusercontent.com',
    iosBundleId: 'com.muraadshams.ecobite',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCMwGV4DEVmKsooPOtK32UvCOWc8q78wVo',
    appId: '1:499078252124:web:061dfd31db979f75694899',
    messagingSenderId: '499078252124',
    projectId: 'ecobite-app',
    authDomain: 'ecobite-app.firebaseapp.com',
    storageBucket: 'ecobite-app.firebasestorage.app',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBr-CQ6R7N_j14KpCgpgGQwb_geTIlD--M',
    appId: '1:499078252124:ios:f7ba01367ad28dc8694899',
    messagingSenderId: '499078252124',
    projectId: 'ecobite-app',
    storageBucket: 'ecobite-app.firebasestorage.app',
    iosClientId: '499078252124-5im3q7okg4mjboo46insu2brh0j1rd0v.apps.googleusercontent.com',
    iosBundleId: 'com.example.ecobite',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyCMwGV4DEVmKsooPOtK32UvCOWc8q78wVo',
    appId: '1:499078252124:web:c6bd628fb627c59c694899',
    messagingSenderId: '499078252124',
    projectId: 'ecobite-app',
    authDomain: 'ecobite-app.firebaseapp.com',
    storageBucket: 'ecobite-app.firebasestorage.app',
  );

}