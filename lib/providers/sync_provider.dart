import 'package:flutter/foundation.dart';

enum SyncStatus { idle, syncing, ok, fail }

class SyncProvider extends ChangeNotifier {
  SyncStatus status = SyncStatus.idle;
  String? lastError;

  void set(SyncStatus s, {String? error}) {
    status = s; lastError = error; notifyListeners();
  }
}
