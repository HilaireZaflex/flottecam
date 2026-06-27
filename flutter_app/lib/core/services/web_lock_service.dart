import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:js_interop';

// Interop JS — expose window properties
@JS('window._flutterShowPin')
external set _jsFlutterShowPin(JSFunction? fn);

@JS('window._pendingPinRequest')
external bool? get _jsPendingPinRequest;

@JS('window._pendingPinRequest')
external set _jsPendingPinRequest(bool? val);

/// Service qui écoute le signal JS de verrouillage PIN
/// et appelle le callback Flutter pour naviguer vers /pin
class WebLockService {
  static void Function()? _onLockRequested;

  /// Initialiser le bridge JS → Flutter
  static void init(void Function() onLockRequested) {
    if (!kIsWeb) return;
    _onLockRequested = onLockRequested;

    // Exposer la fonction _flutterShowPin à JavaScript
    _jsFlutterShowPin = (() {
      _onLockRequested?.call();
    }).toJS;

    // Vérifier si un événement PIN était en attente avant que Flutter démarre
    final pending = _jsPendingPinRequest;
    if (pending == true) {
      _jsPendingPinRequest = false;
      Future.delayed(const Duration(milliseconds: 300), () {
        _onLockRequested?.call();
      });
    }
  }

  static void dispose() {
    _jsFlutterShowPin = null;
    _onLockRequested = null;
  }
}
