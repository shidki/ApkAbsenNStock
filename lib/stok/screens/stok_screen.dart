// Tab STOK — perhitungan & pantauan stok produk.
//   • KPI ringkas (jumlah SKU, total unit, nilai modal, SKU bermasalah)
//   • Filter gudang + kategori + pencarian
//   • Daftar produk dengan status stok
//   • Ketuk produk → Kartu Stok (riwayat mutasi + saldo berjalan)
import 'package:flutter/material.dart';
import '../../api.dart';
import '../../config.dart';
import '../models.dart';
import '../panduan.dart';
import '../ui.dart';

class StokScreen extends StatefulWidget {
  const StokScreen({super.key});
  @override
  State<StokScreen> createState() => _StokScreenState();
}

class _StokScreenState extends State<StokScreen> {
  bool _loading = true;
  String? _error;
  List<Product> _all = [];
  List<Warehouse> _gudang = [];
  List<Category> _kategori = [];

  String _search = '';
  Warehouse? _fGudang;
  Category? _fKategori;

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
      final results = await Future.wait([
        api.products(),
        api.warehouses(),
        api.categories(tipe: 'produk'),
      ]);
      if (!mounted) return;
      setState(() {
        _all = results[0] as List<Product>;
        _gudang = results[1] as List<Warehouse>;
        _kategori = results[2] as List<Category>;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() { _error = e.message; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _error = 'Gagal terhubung ke server.'; _loading = false; });
    }
  }

  List<Product> get _filtered {
    final q = _search.trim().toLowerCase();
    return _all.where((p) {
      if (_fGudang != null && p.gudangId != _fGudang!.id) return false;
      if (_fKategori != null && p.kategoriId != _fKategori!.id) return false;
      if (q.isNotEmpty && !p.nama.toLowerCase().contains(q) && !p.sku.toLowerCase().contains(q)) return false;
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final list = _filtered;
    final totalUnit = list.fold<int>(0, (s, p) => s + p.stok);
    final nilaiModal = list.fold<double>(0, (s, p) => s + p.nilaiModal);
    final bermasalah = list.where((p) => p.stockState != 'aman').length;

    return Scaffold(
      body: Column(children: [
        ModernHeader(
          title: 'Stok Produk',
          subtitle: 'Perhitungan & kartu stok',
          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
            const PanduanButton(PanduanTopic.stok),
            IconButton(
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded, color: Colors.white),
              tooltip: 'Muat ulang',
            ),
          ]),
        ),
        Expanded(
          child: _loading
              ? const Loading(label: 'Memuat stok…')
              : _error != null
                  ? ErrorView(_error!, onRetry: _load)
                  : RefreshIndicator(
                      color: AppTheme.primary,
                      onRefresh: _load,
                      child: ListView(
                        padding: EdgeInsets.fromLTRB(16, 16, 16, listBottomInset(context)),
                        children: [
                          // KPI
                          Row(children: [
                            Expanded(child: StatCard(label: 'SKU', value: angka(list.length), icon: Icons.qr_code_2_rounded, color: AppTheme.primary)),
                            const SizedBox(width: 12),
                            Expanded(child: StatCard(label: 'Total Unit', value: angka(totalUnit), icon: Icons.inventory_2_rounded, color: AppTheme.info)),
                          ]),
                          const SizedBox(height: 12),
                          Row(children: [
                            Expanded(child: StatCard(label: 'Nilai Modal', value: rupiahRingkas(nilaiModal), icon: Icons.savings_outlined, color: AppTheme.success)),
                            const SizedBox(width: 12),
                            Expanded(child: StatCard(label: 'Perlu Perhatian', value: angka(bermasalah), icon: Icons.warning_amber_rounded, color: AppTheme.warning)),
                          ]),
                          const SizedBox(height: 18),
                          AppSearchField(hint: 'Cari produk / SKU…', onChanged: (v) => setState(() => _search = v)),
                          const SizedBox(height: 10),
                          // Filter chips
                          Row(children: [
                            Expanded(
                              child: TapField(
                                value: _fGudang?.nama,
                                hint: 'Semua Gudang',
                                leadingIcon: Icons.warehouse_outlined,
                                onTap: () async {
                                  final w = await pickFromSheet<Warehouse?>(
                                    context: context,
                                    title: 'Pilih Gudang',
                                    items: [null, ..._gudang],
                                    labelOf: (w) => w?.label ?? 'Semua Gudang',
                                    selectedOf: (w) => w?.id == _fGudang?.id,
                                  );
                                  if (w == null && _fGudang == null) return;
                                  setState(() => _fGudang = w);
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TapField(
                                value: _fKategori?.nama,
                                hint: 'Semua Kategori',
                                leadingIcon: Icons.category_outlined,
                                onTap: () async {
                                  final c = await pickFromSheet<Category?>(
                                    context: context,
                                    title: 'Pilih Kategori',
                                    items: [null, ..._kategori],
                                    labelOf: (c) => c?.nama ?? 'Semua Kategori',
                                    selectedOf: (c) => c?.id == _fKategori?.id,
                                  );
                                  if (c == null && _fKategori == null) return;
                                  setState(() => _fKategori = c);
                                },
                              ),
                            ),
                          ]),
                          if (_fGudang != null || _fKategori != null) ...[
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton.icon(
                                onPressed: () => setState(() { _fGudang = null; _fKategori = null; }),
                                icon: const Icon(Icons.filter_alt_off_outlined, size: 18),
                                label: const Text('Reset filter'),
                              ),
                            ),
                          ],
                          const SizedBox(height: 6),
                          if (list.isEmpty)
                            const Padding(padding: EdgeInsets.only(top: 40), child: EmptyView('Tidak ada produk'))
                          else
                            ...list.map((p) => Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: _ProductTile(p),
                                )),
                        ],
                      ),
                    ),
        ),
      ]),
    );
  }
}

class _ProductTile extends StatelessWidget {
  final Product p;
  const _ProductTile(this.p);
  @override
  Widget build(BuildContext context) {
    return SoftCard(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => KartuStokPage(sku: p.sku, nama: p.nama))),
      child: Row(children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(12)),
          alignment: Alignment.center,
          child: const Icon(Icons.inventory_2_outlined, color: AppTheme.primary, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(namaPendek(p.nama), maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5, color: AppTheme.ink)),
            const SizedBox(height: 4),
            Wrap(spacing: 6, runSpacing: 6, children: [
              MiniChip(p.sku, icon: Icons.qr_code_rounded),
              if (p.gudang != null && p.gudang!.isNotEmpty) MiniChip(p.gudang!, icon: Icons.warehouse_outlined),
              if (p.warna != null && p.warna!.isNotEmpty) MiniChip(p.warna!),
            ]),
          ]),
        ),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(angka(p.stok), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppTheme.ink)),
          Text(p.satuan, style: const TextStyle(color: AppTheme.faint, fontSize: 11)),
          const SizedBox(height: 4),
          StockBadge(p.stockState),
        ]),
      ]),
    );
  }
}

// ─────────────────────────── KARTU STOK ───────────────────────────
class KartuStokPage extends StatefulWidget {
  final String sku;
  final String nama;
  const KartuStokPage({required this.sku, required this.nama, super.key});
  @override
  State<KartuStokPage> createState() => _KartuStokPageState();
}

class _KartuStokPageState extends State<KartuStokPage> {
  bool _loading = true;
  String? _error;
  Product? _produk;
  List<KartuStokRow> _rows = [];

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
      final res = await api.stockCard(widget.sku);
      if (!mounted) return;
      setState(() {
        _produk = res.produk;
        _rows = res.rows;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() { _error = e.message; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _error = 'Gagal memuat kartu stok.'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = _produk;
    return Scaffold(
      body: Column(children: [
        ModernHeader(
          title: namaPendek(widget.nama, kata: 5),
          subtitle: 'Kartu Stok • ${widget.sku}',
          trailing: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded, color: Colors.white),
          ),
        ),
        Expanded(
          child: _loading
              ? const Loading(label: 'Menghitung saldo…')
              : _error != null
                  ? ErrorView(_error!, onRetry: _load)
                  : RefreshIndicator(
                      color: AppTheme.primary,
                      onRefresh: _load,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
                        children: [
                          if (p != null && p.id != 0) ...[
                            SoftCard(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Row(children: [
                                  Expanded(
                                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      Text(p.nama, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppTheme.ink)),
                                      const SizedBox(height: 4),
                                      Text('${p.sku}${p.gudang != null ? ' • ${p.gudang}' : ''}',
                                          style: const TextStyle(color: AppTheme.muted, fontSize: 12.5)),
                                    ]),
                                  ),
                                  StockBadge(p.stockState),
                                ]),
                                const SizedBox(height: 14),
                                Row(children: [
                                  _mini('Stok Saat Ini', angka(p.stok), AppTheme.primary),
                                  _mini('Stok Min', angka(p.stokMin), AppTheme.warning),
                                  _mini('Nilai Modal', rupiahRingkas(p.nilaiModal), AppTheme.success),
                                ]),
                                if (p.bervariant) ...[
                                  const SizedBox(height: 14),
                                  const Divider(height: 1),
                                  const SizedBox(height: 12),
                                  const Text('Stok per Ukuran', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.ink)),
                                  const SizedBox(height: 8),
                                  Wrap(spacing: 8, runSpacing: 8, children: [
                                    for (final v in p.variants)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                                        decoration: BoxDecoration(color: AppTheme.soft, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppTheme.border)),
                                        child: Text('${v.ukuran.isEmpty ? '—' : v.ukuran}: ${angka(v.stok)}',
                                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, color: AppTheme.ink)),
                                      ),
                                  ]),
                                ],
                              ]),
                            ),
                            const SizedBox(height: 18),
                          ],
                          const SectionHeader('Riwayat Mutasi', icon: Icons.history_rounded),
                          const SizedBox(height: 8),
                          if (_rows.isEmpty)
                            const Padding(padding: EdgeInsets.only(top: 30), child: EmptyView('Belum ada mutasi untuk produk ini'))
                          else
                            ..._rows.map((r) => Padding(padding: const EdgeInsets.only(bottom: 10), child: _KartuRowTile(r))),
                        ],
                      ),
                    ),
        ),
      ]),
    );
  }

  Widget _mini(String label, String value, Color c) => Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: c)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: AppTheme.muted, fontSize: 11.5)),
        ]),
      );
}

class _KartuRowTile extends StatelessWidget {
  final KartuStokRow r;
  const _KartuRowTile(this.r);
  @override
  Widget build(BuildContext context) {
    final m = r.move;
    final masuk = m.tipe == 'masuk' || (m.tipe == 'opname' && m.qty > 0);
    final keluar = m.tipe == 'keluar' || m.tipe == 'transfer' || (m.tipe == 'opname' && m.qty < 0);
    return SoftCard(
      padding: const EdgeInsets.all(13),
      child: Row(children: [
        MoveAvatar(m.tipe),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              MoveTipeChip(m.tipe),
              const SizedBox(width: 8),
              Text(tanggalID(m.tanggal), style: const TextStyle(color: AppTheme.muted, fontSize: 12)),
            ]),
            const SizedBox(height: 5),
            Text(m.refNo + (m.ukuran != null && m.ukuran!.isNotEmpty ? '  •  Uk. ${m.ukuran}' : ''),
                style: const TextStyle(color: AppTheme.faint, fontSize: 11.5)),
          ]),
        ),
        const SizedBox(width: 8),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(
            masuk ? '+${angka(m.qty.abs())}' : (keluar ? '-${angka(m.qty.abs())}' : angka(m.qty)),
            style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 15,
                color: masuk ? AppTheme.success : (keluar ? AppTheme.danger : AppTheme.ink)),
          ),
          const SizedBox(height: 2),
          Text('Saldo ${angka(r.saldo)}', style: const TextStyle(color: AppTheme.muted, fontSize: 11.5, fontWeight: FontWeight.w600)),
        ]),
      ]),
    );
  }
}
