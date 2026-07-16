// Lapisan API — panggilan HTTP ke backend absensi. Token: Bearer user-<id>.
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'config.dart';
import 'models.dart';
import 'stok/models.dart';

class ApiException implements Exception {
  final int status;
  final String message;
  ApiException(this.status, this.message);
  @override
  String toString() => message;
}

class Api {
  String? _token;
  void setToken(String? t) => _token = t;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  Uri _uri(String base, String path, [Map<String, dynamic>? query]) {
    final q = <String, String>{};
    query?.forEach((k, v) {
      if (v != null && '$v'.isNotEmpty) q[k] = '$v';
    });
    return Uri.parse('$base$path').replace(queryParameters: q.isEmpty ? null : q);
  }

  Never _fail(http.Response r) {
    String msg = 'Terjadi kesalahan (${r.statusCode})';
    try {
      final body = jsonDecode(r.body);
      if (body is Map && body['detail'] != null) msg = body['detail'].toString();
    } catch (_) {}
    throw ApiException(r.statusCode, msg);
  }

  dynamic _decode(http.Response r) {
    if (r.statusCode >= 200 && r.statusCode < 300) {
      if (r.body.isEmpty) return null;
      return jsonDecode(r.body);
    }
    _fail(r);
  }

  Future<dynamic> _get(String base, String path, [Map<String, dynamic>? q]) async =>
      _decode(await http.get(_uri(base, path, q), headers: _headers));
  Future<dynamic> _post(String base, String path, [Object? body]) async =>
      _decode(await http.post(_uri(base, path), headers: _headers, body: jsonEncode(body ?? {})));
  Future<dynamic> _put(String base, String path, [Object? body]) async =>
      _decode(await http.put(_uri(base, path), headers: _headers, body: jsonEncode(body ?? {})));
  Future<dynamic> _delete(String base, String path) async =>
      _decode(await http.delete(_uri(base, path), headers: _headers));

  String get _b => Config.absBase;
  String get _pm => Config.pmBase;

  // ── AUTH ──
  Future<({String token, AppUser user})> login(String email, String password) async {
    final j = await _post(Config.authBase, '/apk/absensi-login', {'email': email, 'password': password});
    return (token: j['token'].toString(), user: AppUser.fromJson(j['user'] as Map<String, dynamic>));
  }

  Future<AppUser> me() async => AppUser.fromJson(await _get(Config.authBase, '/me') as Map<String, dynamic>);
  Future<void> logout() async {
    try { await _post(Config.authBase, '/logout'); } catch (_) {}
  }

  // ── ABSEN ──
  Future<AbsenMe> absenMe() async => AbsenMe.fromJson(await _get(_b, '/me') as Map<String, dynamic>);
  Future<ClockResult> clock(String kode, {int? shiftId}) async =>
      ClockResult.fromJson(await _post(_b, '/clock',
          {'kode': kode, 'shift_id': ?shiftId}) as Map<String, dynamic>);

  // ── RIWAYAT & DASHBOARD ──
  Future<List<Attendance>> myHistory({int? tahun, int? bulan}) async {
    final j = await _get(_b, '/my/history', {'tahun': tahun, 'bulan': bulan}) as List;
    return j.map((e) => Attendance.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<MySummary> mySummary({int? tahun, int? bulan}) async =>
      MySummary.fromJson(await _get(_b, '/my/summary', {'tahun': tahun, 'bulan': bulan}) as Map<String, dynamic>);

  // ── LEMBUR ──
  Future<List<Overtime>> myOvertime() async {
    final j = await _get(_b, '/my/overtime') as List;
    return j.map((e) => Overtime.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> createOvertime(Map<String, dynamic> body) async => _post(_b, '/my/overtime', body);

  // ══════════════════ MODUL STOK (Product Management) ══════════════════
  Future<List<Warehouse>> warehouses() async {
    final j = await _get(_pm, '/warehouses') as List;
    return j.map((e) => Warehouse.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<Category>> categories({String tipe = 'produk'}) async {
    final j = await _get(_pm, '/categories', {'tipe': tipe}) as List;
    return j.map((e) => Category.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<Product>> products({String? search, int? kategoriId, String? status}) async {
    final j = await _get(_pm, '/products',
        {'search': search, 'kategori_id': kategoriId, 'status': status}) as List;
    return j.map((e) => Product.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<StockMove>> moves({String? tipe, String? search, int limit = 1000}) async {
    final j = await _get(_pm, '/moves', {'tipe': tipe, 'search': search, 'limit': limit}) as List;
    return j.map((e) => StockMove.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<StockMove> createMove(Map<String, dynamic> body) async =>
      StockMove.fromJson(await _post(_pm, '/moves', body) as Map<String, dynamic>);
  Future<StockMove> updateMove(int id, Map<String, dynamic> body) async =>
      StockMove.fromJson(await _put(_pm, '/moves/$id', body) as Map<String, dynamic>);
  Future<void> deleteMove(int id) async => _delete(_pm, '/moves/$id');

  Future<({bool ok, int created})> opname(Map<String, dynamic> body) async {
    final j = await _post(_pm, '/opname', body) as Map<String, dynamic>;
    return (ok: j['ok'] == true, created: _asIntSafe(j['created']));
  }

  Future<({Product produk, List<KartuStokRow> rows})> stockCard(String sku) async {
    final prods = await products();
    final produk = prods.firstWhere(
      (p) => p.sku == sku,
      orElse: () => Product(id: 0, sku: sku, nama: sku),
    );
    final all = await moves();
    final mine = all.where((m) => m.sku == sku).toList()
      ..sort((a, b) => (a.tanggal ?? '').compareTo(b.tanggal ?? ''));
    int saldo = 0;
    final rows = <KartuStokRow>[];
    for (final m in mine) {
      switch (m.tipe) {
        case 'masuk':
          saldo += m.qty;
          break;
        case 'keluar':
        case 'transfer':
          saldo -= m.qty;
          break;
        case 'opname':
          saldo += m.qty; // qty opname bisa +/-
          break;
      }
      rows.add(KartuStokRow(m, saldo));
    }
    return (produk: produk, rows: rows.reversed.toList()); // terbaru di atas
  }
}

int _asIntSafe(dynamic v) => v == null ? 0 : (v is int ? v : (v is num ? v.toInt() : int.tryParse('$v') ?? 0));

/// Ambil nilai `kode` dari hasil scan QR. QR kantor berisi URL
/// `.../absensi/absen?kode=ABSEN-XXXX`; kalau bukan URL, pakai apa adanya.
String extractKode(String raw) {
  final s = raw.trim();
  try {
    final uri = Uri.parse(s);
    final k = uri.queryParameters['kode'];
    if (k != null && k.isNotEmpty) return k;
  } catch (_) {}
  return s;
}

final api = Api();
