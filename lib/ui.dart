// Helper UI & format bersama.
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'config.dart';

// ── Helper responsif — nyesuaiin margin & skala ke lebar layar HP ──

/// Padding horizontal halaman: makin sempit layar makin kecil marginnya.
double screenPad(BuildContext c) {
  final w = MediaQuery.sizeOf(c).width;
  if (w < 340) return 14;
  if (w < 400) return 18;
  return 20;
}

/// Tinggi area aman atas (status bar / notch) — biar header pas di semua HP.
double topInset(BuildContext c) => MediaQuery.paddingOf(c).top;

/// Skala kecil untuk elemen agar tak kegedean di HP mungil (dibatasi 0.9–1.1).
double uiScale(BuildContext c) {
  final w = MediaQuery.sizeOf(c).width;
  return (w / 390).clamp(0.9, 1.1);
}

/// Ruang kosong bawah agar konten TIDAK ketutup bottom-nav yang melayang.
/// Menghitung tinggi navbar + area aman bawah (home indicator / gesture bar) tiap HP.
double bottomGap(BuildContext c) => 96 + MediaQuery.paddingOf(c).bottom;

String fmtTgl(String? iso) {
  if (iso == null || iso.isEmpty) return '—';
  try { return DateFormat('EEE, d MMM yyyy', 'id_ID').format(DateTime.parse(iso)); } catch (_) { return iso; }
}

String fmtTglPendek(String? iso) {
  if (iso == null || iso.isEmpty) return '—';
  try { return DateFormat('d MMM', 'id_ID').format(DateTime.parse(iso)); } catch (_) { return iso; }
}

String fmtJam(String? s) => (s == null || s.isEmpty) ? '—' : s;

String fmtDurasi(int menit) {
  if (menit <= 0) return '—';
  final h = menit ~/ 60, m = menit % 60;
  return h > 0 ? '${h}j ${m}m' : '${m}m';
}

/// Warna + label untuk status absensi.
({Color color, Color bg, String label}) statusStyle(String s) {
  ({Color color, Color bg, String label}) mk(Color c, String l) => (color: c, bg: c.withValues(alpha: 0.12), label: l);
  switch (s) {
    case 'hadir':
      return mk(AppTheme.success, 'Hadir');
    case 'terlambat':
      return mk(AppTheme.warning, 'Terlambat');
    case 'izin':
      return mk(AppTheme.info, 'Izin');
    case 'sakit':
      return mk(AppTheme.info, 'Sakit');
    case 'cuti':
      return mk(AppTheme.info, 'Cuti');
    case 'alpha':
      return mk(AppTheme.danger, 'Alpha');
    case 'libur':
      return (color: AppTheme.muted, bg: AppTheme.soft, label: 'Libur');
    default:
      return (color: AppTheme.muted, bg: AppTheme.soft, label: s);
  }
}

({Color color, Color bg, String label}) approvalStyle(String s) {
  ({Color color, Color bg, String label}) mk(Color c, String l) => (color: c, bg: c.withValues(alpha: 0.12), label: l);
  switch (s) {
    case 'disetujui':
      return mk(AppTheme.success, 'Disetujui');
    case 'ditolak':
      return mk(AppTheme.danger, 'Ditolak');
    default:
      return mk(AppTheme.warning, 'Diajukan');
  }
}

class Pill extends StatelessWidget {
  final String label;
  final Color color;
  final Color bg;
  const Pill(this.label, {super.key, required this.color, required this.bg});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w800)),
          ],
        ),
      );
}

/// Kartu "melayang" modern — pengganti Card berbingkai yang kaku.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  const AppCard({super.key, required this.child, this.padding = const EdgeInsets.all(18), this.onTap});
  @override
  Widget build(BuildContext context) {
    final content = Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.rLg),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.rLg),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
    return content;
  }
}

/// Kotak ikon dengan latar lembut berwarna — dipakai di kartu & tile.
class IconChip extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  final bool gradient;
  const IconChip(this.icon, {super.key, required this.color, this.size = 46, this.gradient = false});
  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: gradient ? null : color.withValues(alpha: 0.12),
          gradient: gradient ? AppTheme.brandGradient : null,
          borderRadius: BorderRadius.circular(size * 0.32),
        ),
        child: Icon(icon, color: gradient ? Colors.white : color, size: size * 0.5),
      );
}

/// Judul seksi kecil dengan aksen vertikal.
class SectionTitle extends StatelessWidget {
  final String text;
  const SectionTitle(this.text, {super.key});
  @override
  Widget build(BuildContext context) => Row(
        children: [
          Container(width: 4, height: 16, decoration: BoxDecoration(gradient: AppTheme.brandGradient, borderRadius: BorderRadius.circular(4))),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.ink, fontSize: 15.5, letterSpacing: -0.2)),
        ],
      );
}

/// Tampilan error yang seragam & ramah.
class ErrorView extends StatelessWidget {
  final String msg;
  final VoidCallback onRetry;
  const ErrorView({super.key, required this.msg, required this.onRetry});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(color: AppTheme.danger.withValues(alpha: 0.10), shape: BoxShape.circle),
              child: const Icon(Icons.cloud_off_rounded, size: 34, color: AppTheme.danger),
            ),
            const SizedBox(height: 16),
            const Text('Gagal memuat', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppTheme.ink)),
            const SizedBox(height: 6),
            Text(msg, textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.muted, fontSize: 13)),
            const SizedBox(height: 18),
            SizedBox(
              width: 180,
              child: OutlinedButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh_rounded, size: 18), label: const Text('Coba lagi')),
            ),
          ],
        ),
      );
}

/// Tampilan kosong yang seragam.
class EmptyView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const EmptyView({super.key, required this.icon, required this.title, required this.subtitle});
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(color: AppTheme.soft, shape: BoxShape.circle),
                child: Icon(icon, size: 38, color: AppTheme.faint),
              ),
              const SizedBox(height: 16),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppTheme.ink)),
              const SizedBox(height: 6),
              Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.faint, fontSize: 13)),
            ],
          ),
        ),
      );
}

void toast(BuildContext context, String msg, {bool error = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Row(children: [
        Icon(error ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded, color: Colors.white, size: 20),
        const SizedBox(width: 10),
        Expanded(child: Text(msg)),
      ]),
      backgroundColor: error ? AppTheme.danger : AppTheme.ink,
    ));
}
