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
    apiKey: 'AIzaSyBzb45FuAr8kfE2WtnsqSrqY9iwGKxlzvo',
    appId: '1:569617503901:web:788df56d216d6a56fbe674',
    messagingSenderId: '569617503901',
    projectId: 'caption-image-app-640a0',
    authDomain: 'caption-image-app-640a0.firebaseapp.com',
    storageBucket: 'caption-image-app-640a0.appspot.com',
    measurementId: 'G-9W0KLJVD4V',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyB9ZmOOSo7VgrwZ6H6_1Y-TaLRKvkSNNSQ',
    appId: '1:569617503901:android:54662789f320473bfbe674',
    messagingSenderId: '569617503901',
    projectId: 'caption-image-app-640a0',
    storageBucket: 'caption-image-app-640a0.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCwF_gndWUAGNMWqk_UEb2EWHPzm304mKA',
    appId: '1:569617503901:ios:04a005cb494f48d7fbe674',
    messagingSenderId: '569617503901',
    projectId: 'caption-image-app-640a0',
    storageBucket: 'caption-image-app-640a0.appspot.com',
    iosBundleId: 'com.example.imageCaptionFlutterApp',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCwF_gndWUAGNMWqk_UEb2EWHPzm304mKA',
    appId: '1:569617503901:ios:6be93007cc5bdaeafbe674',
    messagingSenderId: '569617503901',
    projectId: 'caption-image-app-640a0',
    storageBucket: 'caption-image-app-640a0.appspot.com',
    iosBundleId: 'com.example.imageCaptionFlutterApp.RunnerTests',
  );
}
