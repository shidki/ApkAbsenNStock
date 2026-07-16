// Tab MASUK — pemasukan / penerimaan stok (menambah stok). Bisa isi BANYAK
// ukuran sekaligus dalam satu form. Riwayat = GET /moves?tipe=masuk.
// Simpan = 1 POST /moves (tipe "masuk") per ukuran yang diisi.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../api.dart';
import '../../auth.dart';
import '../../config.dart';
import '../models.dart';
import '../panduan.dart';
import '../ui.dart';
import 'mutasi_common.dart';

class MasukScreen extends StatefulWidget {
  const MasukScreen({super.key});
  @override
  State<MasukScreen> createState() => _MasukScreenState();
}

class _MasukScreenState extends State<MasukScreen> {
  bool _loading = true;
  String? _error;
  List<StockMove> _rows = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final r = await api.moves(tipe: 'masuk');
      if (!mounted) return;
      setState(() { _rows = r; _loading = false; });
    } on ApiException catch (e) {
      if (mounted) setState(() { _error = e.message; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _error = 'Gagal terhubung ke server.'; _loading = false; });
    }
  }

  Future<void> _delete(StockMove m) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus penerimaan?'),
        content: Text('Mutasi ${m.refNo} dihapus & stok dikurangi lagi.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await api.deleteMove(m.id);
      if (mounted) toast(context, 'Penerimaan dihapus');
      _load();
    } on ApiException catch (e) {
      if (mounted) toast(context, e.message, error: true);
    }
  }

  Future<void> _openForm() async {
    final saved = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => const MasukFormPage()));
    if (saved == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final canCreate = auth.can('pm.penerimaan.create');
    final totalQty = _rows.fold<int>(0, (s, m) => s + m.qty);

    return Scaffold(
      floatingActionButton: canCreate
          ? FloatingActionButton.extended(
              onPressed: _openForm,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Tambah Stok', style: TextStyle(fontWeight: FontWeight.w700)),
            )
          : null,
      body: Column(children: [
        const ModernHeader(title: 'Barang Masuk', subtitle: 'Pemasukan / penerimaan stok',
            trailing: PanduanButton(PanduanTopic.masuk)),
        Expanded(
          child: _loading
              ? const Loading(label: 'Memuat…')
              : _error != null
                  ? ErrorView(_error!, onRetry: _load)
                  : RefreshIndicator(
                      color: AppTheme.primary,
                      onRefresh: _load,
                      child: ListView(
                        padding: EdgeInsets.fromLTRB(16, 16, 16, listBottomInset(context, hasFab: canCreate)),
                        children: [
                          Row(children: [
                            Expanded(child: StatCard(label: 'Transaksi', value: angka(_rows.length), icon: Icons.receipt_long_outlined, color: AppTheme.primary)),
                            const SizedBox(width: 12),
                            Expanded(child: StatCard(label: 'Total Masuk', value: angka(totalQty), icon: Icons.south_west_rounded, color: AppTheme.success)),
                          ]),
                          const SizedBox(height: 18),
                          if (_rows.isEmpty)
                            const Padding(padding: EdgeInsets.only(top: 40), child: EmptyView('Belum ada penerimaan'))
                          else
                            ..._rows.map((m) => Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: MoveHistoryTile(m, onDelete: canCreate ? () => _delete(m) : null),
                                )),
                        ],
                      ),
                    ),
        ),
      ]),
    );
  }
}

// ─────────────────────────── FORM ───────────────────────────
class MasukFormPage extends StatefulWidget {
  const MasukFormPage({super.key});
  @override
  State<MasukFormPage> createState() => _MasukFormPageState();
}

class _MasukFormPageState extends State<MasukFormPage> {
  bool _loadingRef = true;
  bool _saving = false;
  String? _refError;

  List<Warehouse> _gudang = [];
  List<Product> _products = [];

  Warehouse? _selGudang;
  Product? _selProduct;
  List<SizeQtyLine> _lines = [];
  DateTime _tanggal = DateTime.now();
  final _petugas = TextEditingController();
  final _keterangan = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadRef();
  }

  @override
  void dispose() {
    for (final l in _lines) {
      l.dispose();
    }
    _petugas.dispose();
    _keterangan.dispose();
    super.dispose();
  }

  Future<void> _loadRef() async {
    try {
      final res = await Future.wait([api.warehouses(), api.products()]);
      if (!mounted) return;
      setState(() {
        _gudang = res[0] as List<Warehouse>;
        _products = res[1] as List<Product>;
        _loadingRef = false;
      });
    } catch (_) {
      if (mounted) setState(() { _refError = 'Gagal memuat data acuan.'; _loadingRef = false; });
    }
  }

  List<Product> get _productsInGudang =>
      _selGudang == null ? [] : _products.where((p) => p.gudangId == _selGudang!.id).toList();

  void _pickProduct(Product p) {
    for (final l in _lines) {
      l.dispose();
    }
    final lines = <SizeQtyLine>[];
    if (p.bervariant) {
      for (final v in p.variants) {
        lines.add(SizeQtyLine(v.ukuran, v.stok));
      }
    } else {
      lines.add(SizeQtyLine('', p.stok));
    }
    setState(() {
      _selProduct = p;
      _lines = lines;
    });
  }

  Future<void> _addUkuranBaru() async {
    final ctrl = TextEditingController();
    final ukuran = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ukuran Baru'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'mis. XXL, 34, All Size'),
          onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(ctx, ctrl.text.trim()), child: const Text('Tambah')),
        ],
      ),
    );
    ctrl.dispose();
    if (ukuran == null || ukuran.isEmpty) return;
    if (_lines.any((l) => l.ukuran.toLowerCase() == ukuran.toLowerCase())) {
      if (mounted) toast(context, 'Ukuran "$ukuran" sudah ada', error: true);
      return;
    }
    setState(() => _lines.add(SizeQtyLine(ukuran, 0, isNew: true)));
  }

  Future<void> _submit() async {
    final p = _selProduct;
    if (_selGudang == null) return toast(context, 'Pilih gudang dulu', error: true);
    if (p == null) return toast(context, 'Pilih produk dulu', error: true);
    final isi = _lines.where((l) => l.qtyVal > 0).toList();
    if (isi.isEmpty) return toast(context, 'Isi jumlah minimal 1 ukuran', error: true);

    setState(() => _saving = true);
    try {
      // 1 mutasi "masuk" per ukuran (sekuensial biar ref_no server tidak balapan).
      for (final l in isi) {
        await api.createMove({
          'tipe': 'masuk',
          'tanggal': isoDate(_tanggal),
          'product_id': p.id,
          'ukuran': p.bervariant ? l.ukuran : null,
          'qty': l.qtyVal,
          'gudang_id': _selGudang!.id,
          'petugas': _petugas.text.trim().isEmpty ? null : _petugas.text.trim(),
          'keterangan': _keterangan.text.trim().isEmpty ? null : _keterangan.text.trim(),
        });
      }
      if (!mounted) return;
      toast(context, 'Stok masuk tersimpan (${isi.length} ukuran)');
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (mounted) toast(context, e.message, error: true);
    } catch (_) {
      if (mounted) toast(context, 'Gagal menyimpan.', error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = _selProduct;
    return Scaffold(
      body: Column(children: [
        ModernHeader(
          title: 'Barang Masuk',
          subtitle: 'Tambah stok produk',
          trailing: IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded, color: Colors.white)),
        ),
        Expanded(
          child: _loadingRef
              ? const Loading(label: 'Menyiapkan form…')
              : _refError != null
                  ? ErrorView(_refError!, onRetry: () { setState(() => _loadingRef = true); _loadRef(); })
                  : ListView(
                      padding: EdgeInsets.fromLTRB(16, 18, 16, listBottomInset(context)),
                      children: [
                        LabeledField('Gudang', TapField(
                          value: _selGudang?.label,
                          hint: 'Pilih gudang',
                          leadingIcon: Icons.warehouse_outlined,
                          onTap: () async {
                            final w = await pickFromSheet<Warehouse>(
                              context: context, title: 'Pilih Gudang', items: _gudang,
                              labelOf: (w) => w.label, subOf: (w) => w.lokasi ?? '',
                              selectedOf: (w) => w.id == _selGudang?.id,
                            );
                            if (w != null) setState(() { _selGudang = w; _selProduct = null; _lines = []; });
                          },
                        )),
                        LabeledField('Produk', TapField(
                          value: p == null ? null : '${p.nama} (${p.sku})',
                          hint: _selGudang == null ? 'Pilih gudang dulu' : 'Cari & pilih produk',
                          leadingIcon: Icons.inventory_2_outlined,
                          onTap: _selGudang == null
                              ? null
                              : () async {
                                  final sel = await pickFromSheet<Product>(
                                    context: context, title: 'Pilih Produk', items: _productsInGudang,
                                    labelOf: (x) => '${x.nama}${x.warna != null && x.warna!.isNotEmpty ? ' • ${x.warna}' : ''}',
                                    subOf: (x) => '${x.sku} • stok ${angka(x.stok)}',
                                    selectedOf: (x) => x.id == _selProduct?.id,
                                    searchHint: 'Cari nama / SKU / warna…',
                                  );
                                  if (sel != null) _pickProduct(sel);
                                },
                        )),
                        if (p != null) ...[
                          Row(children: [
                            const Expanded(child: SectionHeader('Ukuran & Jumlah Masuk', icon: Icons.add_box_outlined)),
                            if (p.bervariant)
                              TextButton.icon(
                                onPressed: _addUkuranBaru,
                                icon: const Icon(Icons.add_rounded, size: 18),
                                label: const Text('Ukuran'),
                              ),
                          ]),
                          const SizedBox(height: 8),
                          SizeQtyTable(
                            lines: _lines,
                            qtyLabel: 'Masuk',
                            accent: AppTheme.success,
                            onChanged: () => setState(() {}),
                            onRemove: (i) => setState(() { _lines[i].dispose(); _lines.removeAt(i); }),
                          ),
                          const SizedBox(height: 16),
                        ],
                        LabeledField('Tanggal', DateTapField(value: _tanggal, onPick: (d) => setState(() => _tanggal = d))),
                        LabeledField('Petugas (opsional)', TextField(
                          controller: _petugas,
                          decoration: const InputDecoration(hintText: 'Nama petugas', prefixIcon: Icon(Icons.badge_outlined)),
                        )),
                        LabeledField('Keterangan (opsional)', TextField(
                          controller: _keterangan,
                          maxLines: 2,
                          decoration: const InputDecoration(hintText: 'Catatan tambahan', prefixIcon: Icon(Icons.notes_rounded)),
                        )),
                        const SizedBox(height: 6),
                        FilledButton.icon(
                          onPressed: _saving ? null : _submit,
                          style: FilledButton.styleFrom(backgroundColor: AppTheme.success),
                          icon: _saving
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                              : const Icon(Icons.south_west_rounded),
                          label: Text(_saving ? 'Menyimpan…' : 'Simpan Stok Masuk'),
                        ),
                      ],
                    ),
        ),
      ]),
    );
  }
}
