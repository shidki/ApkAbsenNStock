// Launcher modul aplikasi gabungan (Absensi + Stok).
//
// Aturan tampil:
//   • Modul Absensi selalu ada untuk semua akun yang login.
//   • Modul Stok muncul hanya kalau akun punya akses Product Management.
// Kalau akun cuma punya 1 modul (karyawan biasa) → langsung masuk modul itu,
// launcher di-skip supaya pengalaman lama nggak berubah. Kalau punya 2 modul,
// tampil pemilih modul; tiap modul dibuka dengan navigasinya sendiri.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'auth.dart';
import 'config.dart';
import 'update.dart';
import 'screens/home_shell.dart';
import 'stok/screens/stok_shell.dart';

class Launcher extends StatefulWidget {
  const Launcher({super.key});
  @override
  State<Launcher> createState() => _LauncherState();
}

class _LauncherState extends State<Launcher> {
  @override
  void initState() {
    super.initState();
    // Cek update sekali saat masuk (untuk semua tipe akun).
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final info = await checkForUpdate();
      if (info != null && mounted) showUpdateDialog(context, info);
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    // Modul Absensi & Stok selalu tampil untuk semua akun (tanpa cek role).
    final nama = auth.user?.nama ?? auth.user?.email ?? 'Pengguna';
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _header(nama),
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(20, 24, 20, 24 + MediaQuery.paddingOf(context).bottom),
              children: [
                Text('Pilih Modul',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.ink, letterSpacing: -0.3)),
                const SizedBox(height: 4),
                Text('Mau kerja di bagian mana hari ini?',
                    style: TextStyle(color: AppTheme.muted, fontSize: 13.5)),
                const SizedBox(height: 20),
                _ModuleCard(
                  icon: Icons.fingerprint_rounded,
                  title: 'Absensi',
                  subtitle: 'Clock in/out, riwayat & rekap kehadiran',
                  onTap: () => _open(const HomeShell()),
                ),
                const SizedBox(height: 14),
                _ModuleCard(
                  icon: Icons.inventory_2_rounded,
                  title: 'Stok',
                  subtitle: 'Perhitungan stok, barang masuk, opname & transfer',
                  onTap: () => _open(const StokShell()),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _open(Widget shell) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => shell));
  }

  Widget _header(String nama) {
    final top = MediaQuery.paddingOf(context).top;
    return Container(
      padding: EdgeInsets.fromLTRB(24, top + 28, 24, 30),
      decoration: const BoxDecoration(
        gradient: AppTheme.brandGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Halo, 👋',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 14)),
          const SizedBox(height: 4),
          Text(nama,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.4)),
          const SizedBox(height: 2),
          Text('Andromeda • Absensi & Stok',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12.5)),
        ],
      ),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _ModuleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.surface,
      borderRadius: BorderRadius.circular(AppTheme.rLg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.rLg),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.rLg),
            boxShadow: AppTheme.cardShadow,
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: AppTheme.brandGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: AppTheme.glow(AppTheme.primary, blur: 16, a: 0.28),
                ),
                child: Icon(icon, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w900, color: AppTheme.ink, letterSpacing: -0.2)),
                    const SizedBox(height: 3),
                    Text(subtitle,
                        style: TextStyle(color: AppTheme.muted, fontSize: 12.5, height: 1.3)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppTheme.faint),
            ],
          ),
        ),
      ),
    );
  }
}
