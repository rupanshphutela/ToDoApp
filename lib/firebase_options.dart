// File generated by FlutterFire CLI.
// ignore_for_file: lines_longer_than_80_chars, avoid_classes_with_only_static_members
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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
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
    apiKey: 'AIzaSyDdYkz2MFj0r5gmiy8ouY6iRAoJCUKU7ws',
    appId: '1:355832515260:web:49b34b3cd957ad0c42deb9',
    messagingSenderId: '355832515260',
    projectId: 'the-to-do-app-68c6e',
    authDomain: 'the-to-do-app-68c6e.firebaseapp.com',
    storageBucket: 'the-to-do-app-68c6e.appspot.com',
    measurementId: 'G-V08SXD8FCG',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCWOP_5q4cl2i0heDpt4tn_LjlCunyah8Q',
    appId: '1:355832515260:android:f9ab33ee1a3d7bce42deb9',
    messagingSenderId: '355832515260',
    projectId: 'the-to-do-app-68c6e',
    storageBucket: 'the-to-do-app-68c6e.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDWXSuutw7aAOjTJEHrE6enysXiytP5d2o',
    appId: '1:355832515260:ios:0f8467cb80bbda8642deb9',
    messagingSenderId: '355832515260',
    projectId: 'the-to-do-app-68c6e',
    storageBucket: 'the-to-do-app-68c6e.appspot.com',
    iosClientId: '355832515260-i8fkghn9kp9er1k4qvsmd4uf3pdv0rp5.apps.googleusercontent.com',
    iosBundleId: 'com.example.toDoApp',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDWXSuutw7aAOjTJEHrE6enysXiytP5d2o',
    appId: '1:355832515260:ios:0f8467cb80bbda8642deb9',
    messagingSenderId: '355832515260',
    projectId: 'the-to-do-app-68c6e',
    storageBucket: 'the-to-do-app-68c6e.appspot.com',
    iosClientId: '355832515260-i8fkghn9kp9er1k4qvsmd4uf3pdv0rp5.apps.googleusercontent.com',
    iosBundleId: 'com.example.toDoApp',
  );
}
