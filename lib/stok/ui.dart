// Helper UI bersama: format angka/uang/tanggal + widget modern yang dipakai
// di banyak layar (kartu lembut, header seksi, stat card, badge, empty state).
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../config.dart';

final _rp = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
final _num = NumberFormat.decimalPattern('id_ID');

String rupiah(num v) => _rp.format(v);
String angka(num v) => _num.format(v);

/// Rupiah ringkas: 1,2jt / 950rb (buat KPI biar gak kepanjangan).
String rupiahRingkas(num v) {
  if (v.abs() >= 1000000000) return 'Rp ${(v / 1000000000).toStringAsFixed(1)}M';
  if (v.abs() >= 1000000) return 'Rp ${(v / 1000000).toStringAsFixed(1)}jt';
  if (v.abs() >= 1000) return 'Rp ${(v / 1000).toStringAsFixed(0)}rb';
  return rupiah(v);
}

/// Nama produk ringkas buat list.
String namaPendek(String nama, {int kata = 4}) {
  final parts = nama.trim().split(RegExp(r'\s+'));
  if (parts.length <= kata) return nama.trim();
  return '${parts.take(kata).join(' ')}…';
}

String tanggalID(String? iso) {
  if (iso == null || iso.isEmpty) return '-';
  try {
    return DateFormat('d MMM yyyy', 'id_ID').format(DateTime.parse(iso));
  } catch (_) {
    return iso;
  }
}

/// Snackbar pesan singkat (sukses/error) dengan ikon.
void toast(BuildContext ctx, String msg, {bool error = false}) {
  ScaffoldMessenger.of(ctx)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Row(children: [
        Icon(error ? Icons.error_outline : Icons.check_circle_outline,
            color: error ? const Color(0xFFFCA5A5) : const Color(0xFF6EE7B7), size: 20),
        const SizedBox(width: 10),
        Expanded(child: Text(msg)),
      ]),
      backgroundColor: AppTheme.ink,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 3),
    ));
}

/// Kartu putih dengan sudut membulat + bayangan lembut.
class SoftCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;
  const SoftCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.color,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color ?? AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.softShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// Judul seksi: ikon dalam chip + teks + aksi opsional di kanan.
class SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color? color;
  final Widget? trailing;
  const SectionHeader(this.title, {required this.icon, this.color, this.trailing, super.key});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppTheme.primary;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(color: c.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 17, color: c),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.ink)),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// Kartu statistik/KPI dengan ikon berwarna.
class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String? sub;
  const StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.sub,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 10),
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.ink, height: 1.1)),
          const SizedBox(height: 2),
          Text(sub ?? label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppTheme.muted, fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class Loading extends StatelessWidget {
  final String? label;
  const Loading({this.label, super.key});
  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              height: 34,
              width: 34,
              child: CircularProgressIndicator(strokeWidth: 3, color: AppTheme.primary),
            ),
            if (label != null) ...[
              const SizedBox(height: 14),
              Text(label!, style: const TextStyle(color: AppTheme.muted)),
            ],
          ],
        ),
      );
}

class ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  const ErrorView(this.message, {this.onRetry, super.key});
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(color: AppTheme.danger.withValues(alpha: 0.10), shape: BoxShape.circle),
                child: const Icon(Icons.cloud_off_rounded, size: 40, color: AppTheme.danger),
              ),
              const SizedBox(height: 16),
              const Text('Gagal memuat data',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppTheme.ink)),
              const SizedBox(height: 6),
              Text(message, textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.muted, fontSize: 13)),
              if (onRetry != null) ...[
                const SizedBox(height: 18),
                OutlinedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Coba lagi'),
                  style: OutlinedButton.styleFrom(minimumSize: const Size(160, 46)),
                ),
              ],
            ],
          ),
        ),
      );
}

class EmptyView extends StatelessWidget {
  final String message;
  final IconData icon;
  const EmptyView(this.message, {this.icon = Icons.inbox_outlined, super.key});
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: AppTheme.soft, shape: BoxShape.circle),
              child: Icon(icon, size: 40, color: AppTheme.faint),
            ),
            const SizedBox(height: 14),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.muted, fontSize: 14)),
          ]),
        ),
      );
}

/// Badge status stok (aman/menipis/habis) dengan titik indikator.
class StockBadge extends StatelessWidget {
  final String state;
  const StockBadge(this.state, {super.key});
  @override
  Widget build(BuildContext context) {
    final (Color c, String label) = switch (state) {
      'habis' => (AppTheme.danger, 'Habis'),
      'menipis' => (AppTheme.warning, 'Menipis'),
      _ => (AppTheme.success, 'Aman'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(color: c.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 6, height: 6, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(color: c, fontSize: 11, fontWeight: FontWeight.w700)),
      ]),
    );
  }
}

/// Warna + label + ikon berdasarkan tipe mutasi.
({Color color, String label, IconData icon}) moveMeta(String tipe) => switch (tipe) {
      'masuk' => (color: AppTheme.success, label: 'Masuk', icon: Icons.south_west_rounded),
      'keluar' => (color: AppTheme.danger, label: 'Keluar', icon: Icons.north_east_rounded),
      'transfer' => (color: AppTheme.info, label: 'Transfer', icon: Icons.swap_horiz_rounded),
      'opname' => (color: AppTheme.warning, label: 'Opname', icon: Icons.fact_check_outlined),
      _ => (color: AppTheme.muted, label: tipe, icon: Icons.circle),
    };

/// Chip warna berdasarkan tipe mutasi.
class MoveTipeChip extends StatelessWidget {
  final String tipe;
  const MoveTipeChip(this.tipe, {super.key});
  @override
  Widget build(BuildContext context) {
    final m = moveMeta(tipe);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(color: m.color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(m.icon, size: 12, color: m.color),
        const SizedBox(width: 5),
        Text(m.label, style: TextStyle(color: m.color, fontSize: 11, fontWeight: FontWeight.w700)),
      ]),
    );
  }
}

/// Avatar bulat berisi ikon (leading list mutasi).
class MoveAvatar extends StatelessWidget {
  final String tipe;
  const MoveAvatar(this.tipe, {super.key});
  @override
  Widget build(BuildContext context) {
    final m = moveMeta(tipe);
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(color: m.color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
      child: Icon(m.icon, size: 20, color: m.color),
    );
  }
}

/// Chip kecil netral untuk info tambahan (ukuran, gudang, dsb).
class MiniChip extends StatelessWidget {
  final String text;
  final IconData? icon;
  final Color? color;
  const MiniChip(this.text, {this.icon, this.color, super.key});
  @override
  Widget build(BuildContext context) {
    final c = color ?? AppTheme.muted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: AppTheme.soft, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppTheme.border)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[Icon(icon, size: 12, color: c), const SizedBox(width: 4)],
        Text(text, style: TextStyle(color: c, fontSize: 11, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

/// Label + field untuk form (jarak konsisten).
class LabeledField extends StatelessWidget {
  final String label;
  final Widget child;
  const LabeledField(this.label, this.child, {super.key});
  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
          const SizedBox(height: 7),
          child,
          const SizedBox(height: 16),
        ],
      );
}

/// Header halaman modern: gradient, sudut bawah membulat, judul besar +
/// subtitle + widget kanan opsional. Dipakai semua tab (pengganti AppBar).
class ModernHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final bool compact;
  const ModernHeader({required this.title, this.subtitle, this.trailing, this.compact = false, super.key});

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, top + (compact ? 12 : 16), 20, compact ? 16 : 22),
      decoration: const BoxDecoration(
        gradient: AppTheme.brandGradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: 0.2)),
            if (subtitle != null) ...[
              const SizedBox(height: 3),
              Text(subtitle!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13)),
            ],
          ]),
        ),
        ?trailing,
      ]),
    );
  }
}

/// Field "ketuk untuk pilih" (produk/ukuran/tanggal/gudang) bergaya seragam.
class TapField extends StatelessWidget {
  final String? value;
  final String hint;
  final IconData trailingIcon;
  final IconData? leadingIcon;
  final VoidCallback? onTap;
  const TapField({
    required this.value,
    required this.hint,
    required this.onTap,
    this.trailingIcon = Icons.expand_more_rounded,
    this.leadingIcon,
    super.key,
  });
  @override
  Widget build(BuildContext context) {
    final filled = value != null && value!.isNotEmpty;
    final disabled = onTap == null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Opacity(
          opacity: disabled ? 0.55 : 1,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
            decoration: BoxDecoration(
              color: AppTheme.soft,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.border),
            ),
            child: Row(children: [
              if (leadingIcon != null) ...[Icon(leadingIcon, size: 18, color: AppTheme.muted), const SizedBox(width: 10)],
              Expanded(
                child: Text(
                  filled ? value! : hint,
                  style: TextStyle(
                      color: filled ? AppTheme.ink : AppTheme.faint,
                      fontWeight: filled ? FontWeight.w600 : FontWeight.w400),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(trailingIcon, size: 20, color: AppTheme.muted),
            ]),
          ),
        ),
      ),
    );
  }
}

/// SearchBar sederhana bergaya app.
class AppSearchField extends StatelessWidget {
  final String hint;
  final ValueChanged<String> onChanged;
  final TextEditingController? controller;
  const AppSearchField({required this.hint, required this.onChanged, this.controller, super.key});
  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(Icons.search_rounded),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }
}

/// Bottom-sheet picker generik: pilih 1 item dari daftar.
/// Otomatis punya kotak SEARCH (kalau daftar > 5 item) & tahan keyboard —
/// responsif di semua ukuran HP.
Future<T?> pickFromSheet<T>({
  required BuildContext context,
  required String title,
  required List<T> items,
  required String Function(T) labelOf,
  String Function(T)? subOf,
  bool Function(T)? selectedOf,
  bool searchable = true,
  String searchHint = 'Cari…',
}) {
  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: AppTheme.surface,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (ctx) => _PickerSheet<T>(
      title: title,
      items: items,
      labelOf: labelOf,
      subOf: subOf,
      selectedOf: selectedOf,
      searchable: searchable,
      searchHint: searchHint,
    ),
  );
}

class _PickerSheet<T> extends StatefulWidget {
  final String title;
  final List<T> items;
  final String Function(T) labelOf;
  final String Function(T)? subOf;
  final bool Function(T)? selectedOf;
  final bool searchable;
  final String searchHint;
  const _PickerSheet({
    required this.title,
    required this.items,
    required this.labelOf,
    this.subOf,
    this.selectedOf,
    required this.searchable,
    required this.searchHint,
  });
  @override
  State<_PickerSheet<T>> createState() => _PickerSheetState<T>();
}

class _PickerSheetState<T> extends State<_PickerSheet<T>> {
  String _q = '';

  List<T> get _filtered {
    final q = _q.trim().toLowerCase();
    if (q.isEmpty) return widget.items;
    return widget.items.where((it) {
      final l = widget.labelOf(it).toLowerCase();
      final s = widget.subOf?.call(it).toLowerCase() ?? '';
      return l.contains(q) || s.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final list = _filtered;
    final mq = MediaQuery.of(context);
    final kb = mq.viewInsets.bottom; // tinggi keyboard
    // Sheet dibuka TINGGI biar konten gak mepet/kepotong: minimal ~55% layar
    // (turun otomatis saat keyboard muncul), maksimal 90%.
    final maxH = mq.size.height * 0.9;
    final minH = kb > 0 ? 0.0 : mq.size.height * 0.55;
    return Padding(
      padding: EdgeInsets.only(bottom: kb),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: minH, maxHeight: maxH),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(width: 44, height: 5, decoration: BoxDecoration(color: AppTheme.border, borderRadius: BorderRadius.circular(3))),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 12, 6),
              child: Row(children: [
                Expanded(child: Text(widget.title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppTheme.ink))),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded, color: AppTheme.muted)),
              ]),
            ),
            if (widget.searchable)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: TextField(
                  autofocus: false,
                  onChanged: (v) => setState(() => _q = v),
                  decoration: InputDecoration(
                    hintText: widget.searchHint,
                    prefixIcon: const Icon(Icons.search_rounded),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                ),
              ),
            const Divider(height: 1),
            Flexible(
              child: list.isEmpty
                  ? const Padding(padding: EdgeInsets.symmetric(vertical: 40), child: EmptyView('Tidak ada hasil'))
                  : ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.only(top: 4, bottom: 12),
                      itemCount: list.length,
                      separatorBuilder: (_, _) => const Divider(height: 1, indent: 20, endIndent: 20),
                      itemBuilder: (_, i) {
                        final it = list[i];
                        final selected = widget.selectedOf?.call(it) ?? false;
                        return ListTile(
                          title: Text(widget.labelOf(it), style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.ink)),
                          subtitle: widget.subOf != null ? Text(widget.subOf!(it), style: const TextStyle(color: AppTheme.muted, fontSize: 12.5)) : null,
                          trailing: selected ? const Icon(Icons.check_circle_rounded, color: AppTheme.primary) : null,
                          onTap: () => Navigator.pop(context, it),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Padding bawah aman untuk ListView di layar ber-FAB + gesture bar HP.
double listBottomInset(BuildContext context, {bool hasFab = false}) =>
    24 + MediaQuery.of(context).padding.bottom + (hasFab ? 76 : 0);
