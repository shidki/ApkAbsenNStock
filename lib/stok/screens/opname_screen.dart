// Tab OPNAME — koreksi stok ke jumlah fisik. Per produk, isi stok fisik tiap
// ukuran → sistem catat selisih (opname) & set stok = fisik.
// Riwayat = GET /moves?tipe=opname. Simpan = POST /opname.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../api.dart';
import '../../auth.dart';
import '../../config.dart';
import '../models.dart';
import '../ui.dart';
import 'mutasi_common.dart';

class OpnameScreen extends StatefulWidget {
  const OpnameScreen({super.key});
  @override
  State<OpnameScreen> createState() => _OpnameScreenState();
}

class _OpnameScreenState extends State<OpnameScreen> {
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
      final r = await api.moves(tipe: 'opname');
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
        title: const Text('Hapus koreksi opname?'),
        content: Text('Mutasi ${m.refNo} dihapus & stok kembali ke nilai sebelumnya.'),
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
      if (mounted) toast(context, 'Koreksi opname dihapus');
      _load();
    } on ApiException catch (e) {
      if (mounted) toast(context, e.message, error: true);
    }
  }

  Future<void> _openForm() async {
    final saved = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => const OpnameFormPage()));
    if (saved == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final canCreate = auth.can('pm.opname.create');
    final net = _rows.fold<int>(0, (s, m) => s + m.qty);

    return Scaffold(
      floatingActionButton: canCreate
          ? FloatingActionButton.extended(
              onPressed: _openForm,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Opname', style: TextStyle(fontWeight: FontWeight.w700)),
            )
          : null,
      body: Column(children: [
        const ModernHeader(title: 'Stock Opname', subtitle: 'Koreksi stok sesuai fisik'),
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
                            Expanded(child: StatCard(label: 'Koreksi', value: angka(_rows.length), icon: Icons.fact_check_outlined, color: AppTheme.warning)),
                            const SizedBox(width: 12),
                            Expanded(child: StatCard(
                              label: 'Net Selisih',
                              value: '${net >= 0 ? '+' : ''}${angka(net)}',
                              icon: net >= 0 ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                              color: net >= 0 ? AppTheme.success : AppTheme.danger,
                            )),
                          ]),
                          const SizedBox(height: 18),
                          if (_rows.isEmpty)
                            const Padding(padding: EdgeInsets.only(top: 40), child: EmptyView('Belum ada opname'))
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
class _OpnameLine {
  final String ukuran;
  final int sistem;
  final TextEditingController fisik;
  _OpnameLine(this.ukuran, this.sistem) : fisik = TextEditingController(text: '$sistem');
  int get fisikVal => int.tryParse(fisik.text.trim()) ?? 0;
  int get selisih => fisikVal - sistem;
}

class OpnameFormPage extends StatefulWidget {
  const OpnameFormPage({super.key});
  @override
  State<OpnameFormPage> createState() => _OpnameFormPageState();
}

class _OpnameFormPageState extends State<OpnameFormPage> {
  bool _loadingRef = true;
  bool _saving = false;
  String? _refError;

  List<Warehouse> _gudang = [];
  List<Product> _products = [];

  Warehouse? _selGudang;
  Product? _selProduct;
  List<_OpnameLine> _lines = [];
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
      l.fisik.dispose();
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
      l.fisik.dispose();
    }
    final lines = <_OpnameLine>[];
    if (p.bervariant) {
      for (final v in p.variants) {
        lines.add(_OpnameLine(v.ukuran, v.stok));
      }
    } else {
      lines.add(_OpnameLine('', p.stok));
    }
    setState(() {
      _selProduct = p;
      _lines = lines;
    });
  }

  bool get _adaPerubahan => _lines.any((l) => l.selisih != 0);

  Future<void> _submit() async {
    final p = _selProduct;
    if (_selGudang == null) return toast(context, 'Pilih gudang dulu', error: true);
    if (p == null) return toast(context, 'Pilih produk dulu', error: true);
    if (!_adaPerubahan) return toast(context, 'Tidak ada selisih untuk disimpan', error: true);

    setState(() => _saving = true);
    try {
      final res = await api.opname({
        'product_id': p.id,
        'gudang_id': _selGudang!.id,
        'tanggal': isoDate(_tanggal),
        'petugas': _petugas.text.trim().isEmpty ? null : _petugas.text.trim(),
        'keterangan': _keterangan.text.trim().isEmpty ? null : _keterangan.text.trim(),
        'lines': [
          for (final l in _lines) {'ukuran': p.bervariant ? l.ukuran : null, 'fisik': l.fisikVal},
        ],
      });
      if (!mounted) return;
      toast(context, 'Opname tersimpan (${res.created} koreksi)');
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
          title: 'Stock Opname',
          subtitle: 'Sesuaikan stok ke fisik',
          trailing: IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded, color: Colors.white)),
        ),
        Expanded(
          child: _loadingRef
              ? const Loading(label: 'Menyiapkan form…')
              : _refError != null
                  ? ErrorView(_refError!, onRetry: () { setState(() => _loadingRef = true); _loadRef(); })
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 18, 16, 30),
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
                          hint: _selGudang == null ? 'Pilih gudang dulu' : 'Pilih produk',
                          leadingIcon: Icons.inventory_2_outlined,
                          onTap: _selGudang == null
                              ? null
                              : () async {
                                  final sel = await pickFromSheet<Product>(
                                    context: context, title: 'Pilih Produk', items: _productsInGudang,
                                    labelOf: (x) => x.nama,
                                    subOf: (x) => '${x.sku} • stok ${angka(x.stok)}',
                                    selectedOf: (x) => x.id == _selProduct?.id,
                                  );
                                  if (sel != null) _pickProduct(sel);
                                },
                        )),
                        if (p != null) ...[
                          const SectionHeader('Hitung Fisik per Ukuran', icon: Icons.checklist_rounded),
                          const SizedBox(height: 8),
                          _OpnameTable(lines: _lines, onChanged: () => setState(() {})),
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
                          decoration: const InputDecoration(hintText: 'Catatan opname', prefixIcon: Icon(Icons.notes_rounded)),
                        )),
                        const SizedBox(height: 6),
                        FilledButton.icon(
                          onPressed: (_saving || !_adaPerubahan) ? null : _submit,
                          style: FilledButton.styleFrom(backgroundColor: AppTheme.warning),
                          icon: _saving
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                              : const Icon(Icons.save_rounded),
                          label: Text(_saving ? 'Menyimpan…' : (_adaPerubahan ? 'Simpan Koreksi' : 'Belum ada selisih')),
                        ),
                      ],
                    ),
        ),
      ]),
    );
  }
}

class _OpnameTable extends StatelessWidget {
  final List<_OpnameLine> lines;
  final VoidCallback onChanged;
  const _OpnameTable({required this.lines, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Column(children: [
        // header
        Row(children: const [
          Expanded(flex: 3, child: Text('Ukuran', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.muted))),
          Expanded(flex: 2, child: Text('Sistem', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.muted))),
          Expanded(flex: 3, child: Text('Fisik', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.muted))),
          Expanded(flex: 2, child: Text('Selisih', textAlign: TextAlign.right, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.muted))),
        ]),
        const Divider(height: 16),
        for (int i = 0; i < lines.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          _OpnameRow(line: lines[i], onChanged: onChanged),
        ],
      ]),
    );
  }
}

class _OpnameRow extends StatelessWidget {
  final _OpnameLine line;
  final VoidCallback onChanged;
  const _OpnameRow({required this.line, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    final s = line.selisih;
    final c = s == 0 ? AppTheme.muted : (s > 0 ? AppTheme.success : AppTheme.danger);
    return Row(children: [
      Expanded(flex: 3, child: Text(line.ukuran.isEmpty ? '—' : line.ukuran, style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.ink))),
      Expanded(flex: 2, child: Text('${line.sistem}', textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.muted, fontWeight: FontWeight.w600))),
      Expanded(
        flex: 3,
        child: SizedBox(
          height: 42,
          child: TextField(
            controller: line.fisik,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            onChanged: (_) => onChanged(),
            decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8)),
          ),
        ),
      ),
      Expanded(
        flex: 2,
        child: Text('${s > 0 ? '+' : ''}$s', textAlign: TextAlign.right,
            style: TextStyle(fontWeight: FontWeight.w800, color: c)),
      ),
    ]);
  }
}
