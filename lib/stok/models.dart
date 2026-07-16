// Model data — mengikuti JSON dari backend Product Management
// (backend/app/product_management/router.py). Semua pakai factory fromJson.

// Catatan: AppUser dipakai bersama dari lib/models.dart (satu sumber untuk
// seluruh app gabungan). File ini hanya model khusus stok.

int _asInt(dynamic v) => v == null ? 0 : (v is int ? v : (v is num ? v.toInt() : int.tryParse('$v') ?? 0));
double _asDouble(dynamic v) => v == null ? 0 : (v is num ? v.toDouble() : double.tryParse('$v') ?? 0);
String? _asStr(dynamic v) => v?.toString();
int? _asIntN(dynamic v) => v == null ? null : _asInt(v);

// ─────────────────────── MASTER / REFERENSI ───────────────────────
class Warehouse {
  final int id;
  final String nama;
  final String? kode;
  final String? lokasi;
  Warehouse({required this.id, required this.nama, this.kode, this.lokasi});
  factory Warehouse.fromJson(Map<String, dynamic> j) => Warehouse(
        id: _asInt(j['id']), nama: j['nama']?.toString() ?? '',
        kode: _asStr(j['kode']), lokasi: _asStr(j['lokasi']),
      );
  String get label => kode == null || kode!.isEmpty ? nama : '$nama ($kode)';
}

class Category {
  final int id;
  final String nama;
  final String tipe; // produk | bahan
  Category({required this.id, required this.nama, this.tipe = 'produk'});
  factory Category.fromJson(Map<String, dynamic> j) =>
      Category(id: _asInt(j['id']), nama: j['nama']?.toString() ?? '', tipe: j['tipe']?.toString() ?? 'produk');
}

class Variant {
  final String ukuran;
  final int stok;
  Variant({this.ukuran = '', this.stok = 0});
  factory Variant.fromJson(Map<String, dynamic> j) =>
      Variant(ukuran: j['ukuran']?.toString() ?? '', stok: _asInt(j['stok']));
}

/// Produk lengkap (dari GET /products). `stok` = jumlah semua variant bila bervariant.
class Product {
  final int id;
  final String sku;
  final String nama;
  final int? kategoriId;
  final String? kategori;
  final String? warna;
  final String satuan;
  final double hargaBeli;
  final double hargaJual;
  final int stok;
  final int stokMin;
  final int? gudangId;
  final String? gudang;
  final List<Variant> variants;
  final String status;

  Product({
    required this.id,
    required this.sku,
    required this.nama,
    this.kategoriId,
    this.kategori,
    this.warna,
    this.satuan = 'pcs',
    this.hargaBeli = 0,
    this.hargaJual = 0,
    this.stok = 0,
    this.stokMin = 0,
    this.gudangId,
    this.gudang,
    this.variants = const [],
    this.status = 'aktif',
  });

  factory Product.fromJson(Map<String, dynamic> j) => Product(
        id: _asInt(j['id']),
        sku: j['sku']?.toString() ?? '',
        nama: j['nama']?.toString() ?? '',
        kategoriId: _asIntN(j['kategori_id']),
        kategori: _asStr(j['kategori']),
        warna: _asStr(j['warna']),
        satuan: j['satuan']?.toString() ?? 'pcs',
        hargaBeli: _asDouble(j['harga_beli']),
        hargaJual: _asDouble(j['harga_jual']),
        stok: _asInt(j['stok']),
        stokMin: _asInt(j['stok_min']),
        gudangId: _asIntN(j['gudang_id']),
        gudang: _asStr(j['gudang']),
        variants: (j['variants'] as List?)?.map((e) => Variant.fromJson(e as Map<String, dynamic>)).toList() ?? [],
        status: j['status']?.toString() ?? 'aktif',
      );

  bool get bervariant => variants.isNotEmpty;

  /// Status stok untuk badge: habis / menipis / aman.
  String get stockState {
    if (stok <= 0) return 'habis';
    if (stok <= stokMin) return 'menipis';
    return 'aman';
  }

  double get nilaiModal => hargaBeli * stok;
}

/// Satu baris mutasi stok (masuk|keluar|transfer|opname) dari GET /moves.
class StockMove {
  final int id;
  final String? tanggal; // ISO YYYY-MM-DD
  final String tipe;
  final String refNo;
  final int? productId;
  final String? item;
  final String? sku;
  final String? warna;
  final String? ukuran;
  final int qty;
  final String? satuan;
  final int? gudangId;
  final String? gudang;
  final int? gudangTujuanId;
  final String? gudangTujuan;
  final String? keterangan;
  final String? petugas;

  StockMove({
    required this.id,
    this.tanggal,
    this.tipe = 'masuk',
    this.refNo = '',
    this.productId,
    this.item,
    this.sku,
    this.warna,
    this.ukuran,
    this.qty = 0,
    this.satuan,
    this.gudangId,
    this.gudang,
    this.gudangTujuanId,
    this.gudangTujuan,
    this.keterangan,
    this.petugas,
  });

  factory StockMove.fromJson(Map<String, dynamic> j) => StockMove(
        id: _asInt(j['id']),
        tanggal: _asStr(j['tanggal']),
        tipe: j['tipe']?.toString() ?? 'masuk',
        refNo: j['ref_no']?.toString() ?? '',
        productId: _asIntN(j['product_id']),
        item: _asStr(j['item']),
        sku: _asStr(j['sku']),
        warna: _asStr(j['warna']),
        ukuran: _asStr(j['ukuran']),
        qty: _asInt(j['qty']),
        satuan: _asStr(j['satuan']),
        gudangId: _asIntN(j['gudang_id']),
        gudang: _asStr(j['gudang']),
        gudangTujuanId: _asIntN(j['gudang_tujuan_id']),
        gudangTujuan: _asStr(j['gudang_tujuan']),
        keterangan: _asStr(j['keterangan']),
        petugas: _asStr(j['petugas']),
      );
}

/// Satu baris kartu stok = mutasi + saldo berjalan (dihitung di client).
class KartuStokRow {
  final StockMove move;
  final int saldo;
  KartuStokRow(this.move, this.saldo);
}
