// Tab TRANSFER — pindah gudang (mutasi antar gudang). Bisa memindah BANYAK
// ukuran sekaligus dari satu produk dalam satu form.
// Riwayat = GET /moves?tipe=transfer. Simpan = 1 POST /moves (transfer) per ukuran.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../api.dart';
import '../../auth.dart';
import '../../config.dart';
import '../models.dart';
import '../panduan.dart';
import '../ui.dart';
import 'mutasi_common.dart';

class TransferScreen extends StatefulWidget {
  const TransferScreen({super.key});
  @override
  State<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen> {
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
      final r = await api.moves(tipe: 'transfer');
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
        title: const Text('Hapus transfer?'),
        content: Text('Mutasi ${m.refNo} dihapus & stok dikembalikan ke gudang asal.'),
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
      if (mounted) toast(context, 'Transfer dihapus');
      _load();
    } on ApiException catch (e) {
      if (mounted) toast(context, e.message, error: true);
    }
  }

  Future<void> _openForm() async {
    final saved = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => const TransferFormPage()));
    if (saved == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final canCreate = auth.can('pm.transfer.create');
    final totalQty = _rows.fold<int>(0, (s, m) => s + m.qty);

    return Scaffold(
      floatingActionButton: canCreate
          ? FloatingActionButton.extended(
              onPressed: _openForm,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Pindah', style: TextStyle(fontWeight: FontWeight.w700)),
            )
          : null,
      body: Column(children: [
        const ModernHeader(title: 'Pindah Gudang', subtitle: 'Transfer stok antar gudang',
            trailing: PanduanButton(PanduanTopic.transfer)),
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
                            Expanded(child: StatCard(label: 'Transfer', value: angka(_rows.length), icon: Icons.swap_horiz_rounded, color: AppTheme.info)),
                            const SizedBox(width: 12),
                            Expanded(child: StatCard(label: 'Total Dipindah', value: angka(totalQty), icon: Icons.local_shipping_outlined, color: AppTheme.primary)),
                          ]),
                          const SizedBox(height: 18),
                          if (_rows.isEmpty)
                            const Padding(padding: EdgeInsets.only(top: 40), child: EmptyView('Belum ada transfer'))
                          else
                            ..._rows.map((m) => Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: MoveHistoryTile(m, showGudangRoute: true, onDelete: canCreate ? () => _delete(m) : null),
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
class TransferFormPage extends StatefulWidget {
  const TransferFormPage({super.key});
  @override
  State<TransferFormPage> createState() => _TransferFormPageState();
}

class _TransferFormPageState extends State<TransferFormPage> {
  bool _loadingRef = true;
  bool _saving = false;
  String? _refError;

  List<Warehouse> _gudang = [];
  List<Product> _products = [];

  Warehouse? _asal;
  Warehouse? _tujuan;
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

  List<Product> get _productsInAsal =>
      _asal == null ? [] : _products.where((p) => p.gudangId == _asal!.id).toList();

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

  Future<void> _submit() async {
    final p = _selProduct;
    if (_asal == null) return toast(context, 'Pilih gudang asal dulu', error: true);
    if (_tujuan == null) return toast(context, 'Pilih gudang tujuan dulu', error: true);
    if (_asal!.id == _tujuan!.id) return toast(context, 'Gudang asal & tujuan tidak boleh sama', error: true);
    if (p == null) return toast(context, 'Pilih produk dulu', error: true);

    final isi = _lines.where((l) => l.qtyVal > 0).toList();
    if (isi.isEmpty) return toast(context, 'Isi jumlah minimal 1 ukuran', error: true);
    for (final l in isi) {
      if (l.qtyVal > l.stok) {
        return toast(context, 'Ukuran ${l.ukuran.isEmpty ? '—' : l.ukuran}: stok cuma ${l.stok}', error: true);
      }
    }

    setState(() => _saving = true);
    try {
      for (final l in isi) {
        await api.createMove({
          'tipe': 'transfer',
          'tanggal': isoDate(_tanggal),
          'product_id': p.id,
          'ukuran': p.bervariant ? l.ukuran : null,
          'qty': l.qtyVal,
          'gudang_id': _asal!.id,
          'gudang_tujuan_id': _tujuan!.id,
          'petugas': _petugas.text.trim().isEmpty ? null : _petugas.text.trim(),
          'keterangan': _keterangan.text.trim().isEmpty ? null : _keterangan.text.trim(),
        });
      }
      if (!mounted) return;
      toast(context, 'Transfer tersimpan (${isi.length} ukuran)');
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
          title: 'Pindah Gudang',
          subtitle: 'Transfer beberapa ukuran sekaligus',
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
                        // Asal & tujuan di-stack vertikal → aman di HP sempit.
                        LabeledField('Gudang Asal', TapField(
                          value: _asal?.label,
                          hint: 'Pilih gudang asal',
                          leadingIcon: Icons.warehouse_outlined,
                          onTap: () async {
                            final w = await pickFromSheet<Warehouse>(
                              context: context, title: 'Gudang Asal', items: _gudang,
                              labelOf: (w) => w.label, subOf: (w) => w.lokasi ?? '',
                              selectedOf: (w) => w.id == _asal?.id,
                            );
                            if (w != null) setState(() { _asal = w; _selProduct = null; _lines = []; });
                          },
                        )),
                        const Padding(
                          padding: EdgeInsets.only(bottom: 8),
                          child: Center(child: Icon(Icons.south_rounded, color: AppTheme.info)),
                        ),
                        LabeledField('Gudang Tujuan', TapField(
                          value: _tujuan?.label,
                          hint: 'Pilih gudang tujuan',
                          leadingIcon: Icons.warehouse_rounded,
                          onTap: () async {
                            final opsi = _gudang.where((w) => w.id != _asal?.id).toList();
                            final w = await pickFromSheet<Warehouse>(
                              context: context, title: 'Gudang Tujuan', items: opsi,
                              labelOf: (w) => w.label, subOf: (w) => w.lokasi ?? '',
                              selectedOf: (w) => w.id == _tujuan?.id,
                            );
                            if (w != null) setState(() => _tujuan = w);
                          },
                        )),
                        LabeledField('Produk (di gudang asal)', TapField(
                          value: p == null ? null : '${p.nama}${p.warna != null && p.warna!.isNotEmpty ? ' • ${p.warna}' : ''} (${p.sku})',
                          hint: _asal == null ? 'Pilih gudang asal dulu' : 'Cari & pilih produk',
                          leadingIcon: Icons.inventory_2_outlined,
                          onTap: _asal == null
                              ? null
                              : () async {
                                  final sel = await pickFromSheet<Product>(
                                    context: context, title: 'Pilih Produk', items: _productsInAsal,
                                    labelOf: (x) => '${x.nama}${x.warna != null && x.warna!.isNotEmpty ? ' • ${x.warna}' : ''}',
                                    subOf: (x) => '${x.sku} • stok ${angka(x.stok)}',
                                    selectedOf: (x) => x.id == _selProduct?.id,
                                    searchHint: 'Cari nama / SKU / warna…',
                                  );
                                  if (sel != null) _pickProduct(sel);
                                },
                        )),
                        if (p != null) ...[
                          const SectionHeader('Ukuran & Jumlah Dipindah', icon: Icons.swap_vert_rounded),
                          const SizedBox(height: 4),
                          const Text('Isi jumlah pada ukuran yang mau dipindah (boleh lebih dari satu).',
                              style: TextStyle(color: AppTheme.muted, fontSize: 12)),
                          const SizedBox(height: 10),
                          SizeQtyTable(
                            lines: _lines,
                            qtyLabel: 'Pindah',
                            accent: AppTheme.info,
                            onChanged: () => setState(() {}),
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
                          decoration: const InputDecoration(hintText: 'Catatan transfer', prefixIcon: Icon(Icons.notes_rounded)),
                        )),
                        const SizedBox(height: 6),
                        FilledButton.icon(
                          onPressed: _saving ? null : _submit,
                          style: FilledButton.styleFrom(backgroundColor: AppTheme.info),
                          icon: _saving
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                              : const Icon(Icons.swap_horiz_rounded),
                          label: Text(_saving ? 'Menyimpan…' : 'Simpan Transfer'),
                        ),
                      ],
                    ),
        ),
      ]),
    );
  }
}
