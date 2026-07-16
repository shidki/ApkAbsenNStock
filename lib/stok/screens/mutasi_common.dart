// Komponen & helper bersama untuk layar mutasi (keluar / opname / transfer).
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config.dart';
import '../models.dart';
import '../ui.dart';

/// Format tanggal untuk dikirim ke backend (YYYY-MM-DD).
String isoDate(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

/// Stok pada ukuran tertentu untuk produk (fallback ke stok global bila tanpa varian).
int variantStock(Product p, String? ukuran) {
  if (!p.bervariant) return p.stok;
  final v = p.variants.where((v) => v.ukuran == (ukuran ?? '')).firstOrNull;
  return v?.stok ?? 0;
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}

/// Baris riwayat mutasi (dipakai di tab keluar/opname/transfer).
class MoveHistoryTile extends StatelessWidget {
  final StockMove m;
  final VoidCallback? onDelete;
  final bool showGudangRoute; // tampilkan asal→tujuan (untuk transfer)
  const MoveHistoryTile(this.m, {this.onDelete, this.showGudangRoute = false, super.key});

  @override
  Widget build(BuildContext context) {
    final judul = (m.item != null && m.item!.isNotEmpty) ? m.item! : (m.sku ?? 'Produk');
    final signed = m.tipe == 'opname'
        ? (m.qty >= 0 ? '+${angka(m.qty)}' : angka(m.qty))
        : (m.tipe == 'masuk' ? '+${angka(m.qty)}' : '-${angka(m.qty)}');
    final signColor = m.tipe == 'masuk'
        ? AppTheme.success
        : m.tipe == 'opname'
            ? (m.qty >= 0 ? AppTheme.success : AppTheme.danger)
            : m.tipe == 'transfer'
                ? AppTheme.info
                : AppTheme.danger;

    return SoftCard(
      padding: const EdgeInsets.all(13),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        MoveAvatar(m.tipe),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(namaPendek(judul, kata: 5),
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.ink)),
            const SizedBox(height: 5),
            Wrap(spacing: 6, runSpacing: 6, children: [
              MiniChip(tanggalID(m.tanggal), icon: Icons.event_outlined),
              if (m.ukuran != null && m.ukuran!.isNotEmpty) MiniChip('Uk. ${m.ukuran}'),
              if (m.warna != null && m.warna!.isNotEmpty) MiniChip(m.warna!),
              if (showGudangRoute)
                MiniChip('${m.gudang ?? '?'} → ${m.gudangTujuan ?? '?'}', icon: Icons.swap_horiz_rounded, color: AppTheme.info)
              else if (m.gudang != null && m.gudang!.isNotEmpty)
                MiniChip(m.gudang!, icon: Icons.warehouse_outlined),
            ]),
            const SizedBox(height: 6),
            Text(m.refNo + (m.petugas != null && m.petugas!.isNotEmpty ? '  •  ${m.petugas}' : ''),
                style: const TextStyle(color: AppTheme.faint, fontSize: 11)),
            if (m.keterangan != null && m.keterangan!.isNotEmpty) ...[
              const SizedBox(height: 3),
              Text(m.keterangan!, maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppTheme.muted, fontSize: 12)),
            ],
          ]),
        ),
        const SizedBox(width: 8),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('$signed ${m.satuan ?? ''}'.trim(),
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: signColor)),
          if (onDelete != null) ...[
            const SizedBox(height: 4),
            InkWell(
              onTap: onDelete,
              borderRadius: BorderRadius.circular(8),
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(Icons.delete_outline_rounded, size: 20, color: AppTheme.danger),
              ),
            ),
          ],
        ]),
      ]),
    );
  }
}

/// Field tanggal reusable (dipakai semua form mutasi).
class DateTapField extends StatelessWidget {
  final DateTime value;
  final ValueChanged<DateTime> onPick;
  const DateTapField({required this.value, required this.onPick, super.key});
  @override
  Widget build(BuildContext context) {
    return TapField(
      value: tanggalID(isoDate(value)),
      hint: 'Pilih tanggal',
      leadingIcon: Icons.event_outlined,
      trailingIcon: Icons.calendar_today_rounded,
      onTap: () async {
        final d = await showDatePicker(
          context: context,
          initialDate: value,
          firstDate: DateTime(2020),
          lastDate: DateTime(2100),
        );
        if (d != null) onPick(d);
      },
    );
  }
}

/// Satu baris "ukuran + jumlah" untuk input mutasi banyak ukuran sekaligus
/// (dipakai di Masuk & Transfer). `stok` = stok saat ini pada ukuran itu
/// (untuk transfer jadi batas maksimum; untuk masuk cuma info).
class SizeQtyLine {
  final String ukuran;
  final int stok;
  final bool isNew; // ukuran baru yang ditambah manual (khusus masuk)
  final TextEditingController qty;
  SizeQtyLine(this.ukuran, this.stok, {this.isNew = false, String initial = ''})
      : qty = TextEditingController(text: initial);
  int get qtyVal => int.tryParse(qty.text.trim()) ?? 0;
  void dispose() => qty.dispose();
}

/// Tabel input banyak ukuran sekaligus: Ukuran | Stok | Jumlah (+hapus opsional).
class SizeQtyTable extends StatelessWidget {
  final List<SizeQtyLine> lines;
  final String qtyLabel; // 'Masuk' / 'Pindah'
  final bool showStok; // tampilkan kolom stok saat ini
  final Color accent;
  final VoidCallback onChanged;
  final void Function(int index)? onRemove; // hapus baris (khusus ukuran baru)
  const SizeQtyTable({
    required this.lines,
    required this.qtyLabel,
    required this.onChanged,
    this.showStok = true,
    this.accent = AppTheme.primary,
    this.onRemove,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(children: [
        Row(children: [
          const Expanded(flex: 3, child: Text('Ukuran', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.muted))),
          if (showStok)
            const Expanded(flex: 2, child: Text('Stok', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.muted))),
          Expanded(flex: 3, child: Text(qtyLabel, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.muted))),
          if (onRemove != null) const SizedBox(width: 34),
        ]),
        const Divider(height: 16),
        for (int i = 0; i < lines.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          _SizeQtyRow(
            line: lines[i],
            showStok: showStok,
            accent: accent,
            onChanged: onChanged,
            onRemove: onRemove == null ? null : () => onRemove!(i),
          ),
        ],
      ]),
    );
  }
}

class _SizeQtyRow extends StatelessWidget {
  final SizeQtyLine line;
  final bool showStok;
  final Color accent;
  final VoidCallback onChanged;
  final VoidCallback? onRemove;
  const _SizeQtyRow({required this.line, required this.showStok, required this.accent, required this.onChanged, this.onRemove});
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(
        flex: 3,
        child: Row(children: [
          Flexible(
            child: Text(line.ukuran.isEmpty ? '—' : line.ukuran,
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.ink)),
          ),
          if (line.isNew) ...[
            const SizedBox(width: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(color: AppTheme.success.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(5)),
              child: const Text('baru', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppTheme.success)),
            ),
          ],
        ]),
      ),
      if (showStok)
        Expanded(flex: 2, child: Text('${line.stok}', textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.muted, fontWeight: FontWeight.w600))),
      Expanded(
        flex: 3,
        child: SizedBox(
          height: 42,
          child: TextField(
            controller: line.qty,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            onChanged: (_) => onChanged(),
            decoration: const InputDecoration(hintText: '0', contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8)),
          ),
        ),
      ),
      if (onRemove != null)
        SizedBox(
          width: 34,
          child: IconButton(
            padding: EdgeInsets.zero,
            onPressed: onRemove,
            icon: const Icon(Icons.close_rounded, size: 18, color: AppTheme.danger),
          ),
        ),
    ]);
  }
}

/// Panel ringkas stok per-ukuran produk yang dipilih (dipakai di form).
class StockPerSizePanel extends StatelessWidget {
  final Product product;
  const StockPerSizePanel(this.product, {super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.15)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.inventory_2_outlined, size: 15, color: AppTheme.primary),
          const SizedBox(width: 6),
          Text('Stok saat ini: ${angka(product.stok)} ${product.satuan}',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, color: AppTheme.primaryDark)),
        ]),
        if (product.bervariant) ...[
          const SizedBox(height: 8),
          Wrap(spacing: 7, runSpacing: 7, children: [
            for (final v in product.variants)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppTheme.border)),
                child: Text('${v.ukuran.isEmpty ? '—' : v.ukuran}: ${angka(v.stok)}',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11.5, color: AppTheme.ink)),
              ),
          ]),
        ],
      ]),
    );
  }
}
