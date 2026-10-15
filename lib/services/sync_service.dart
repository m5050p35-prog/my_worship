import 'dart:async';
import '../models.dart';
import '../providers/sync_provider.dart';
import '../storage.dart';
import 'supabase_service.dart';

class SyncService {
  final SyncProvider provider;
  SyncService(this.provider);

  Timer? _timer;
  UserData? _pending;

  void schedulePush(UserData user) {
    _pending = user;
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 800), _push);
  }

  Future<void> pushNow(UserData user) async {
    _timer?.cancel();
    _pending = user;
    await _push();
  }

  Future<void> _push() async {
    final u = _pending;
    if (u == null) {
      return;
    }
    provider.set(SyncStatus.syncing);
    await Storage.saveUser(u);
    final (ok, err, _) = await SupabaseService.saveUserWithResult(u);
    if (ok) {
      provider.set(SyncStatus.ok);
    } else {
      provider.set(SyncStatus.fail, error: err);
    }
  }
}
