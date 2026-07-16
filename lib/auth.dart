// State autentikasi — simpan token & user, persist ke device.
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api.dart';
import 'models.dart';

class AuthProvider extends ChangeNotifier {
  static const _kToken = 'auth_token';

  AppUser? _user;
  String? _token;
  bool _booting = true;

  AppUser? get user => _user;
  bool get isLoggedIn => _token != null && _user != null;
  bool get booting => _booting;

  Future<void> boot() async {
    final prefs = await SharedPreferences.getInstance();
    final t = prefs.getString(_kToken);
    if (t != null) {
      api.setToken(t);
      try {
        _user = await api.me();
        _token = t;
      } catch (_) {
        await _clear();
      }
    }
    _booting = false;
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    final res = await api.login(email.trim(), password);
    _token = res.token;
    _user = res.user;
    api.setToken(_token);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kToken, _token!);
    notifyListeners();
  }

  Future<void> logout() async {
    await api.logout();
    await _clear();
    notifyListeners();
  }

  Future<void> _clear() async {
    _user = null;
    _token = null;
    api.setToken(null);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kToken);
  }

  // ── Hak akses (samain logika dengan backend has_module_access) ──
  static const _umbrella = {
    'pm': 'product_management',
    'abs': 'absensi',
    'acc': 'accounting',
  };

  /// Akses ke modul stok (buat nampilin modul Stok di launcher).
  bool get canManageStock => hasModuleAccess('pm');

  /// True kalau punya akses APA PUN ke modul ber-prefix (mis. "pm"):
  /// admin, wildcard, umbrella lama, atau key granular ber-prefix.
  bool hasModuleAccess(String prefix) {
    final u = _user;
    if (u == null) return false;
    if (u.isAdmin || u.permissions.contains('*')) return true;
    final umb = _umbrella[prefix];
    if (umb != null && u.permissions.contains(umb)) return true;
    return u.permissions.any((p) => p.startsWith('$prefix.'));
  }

  /// Cek aksi granular (mis. "pm.opname.create").
  bool can(String key) {
    final u = _user;
    if (u == null) return false;
    if (u.isAdmin || u.permissions.contains('*')) return true;
    if (u.permissions.contains(key)) return true;
    final umb = _umbrella[key.split('.').first];
    return umb != null && u.permissions.contains(umb);
  }
}
