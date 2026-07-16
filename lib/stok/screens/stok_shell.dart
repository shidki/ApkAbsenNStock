// Kerangka utama setelah login. Bottom navigation MUNCUL SESUAI PERAN user:
//   • Stok      → perhitungan stok + kartu stok (butuh akses modul pm apa pun)
//   • Masuk     → pemasukan / penerimaan stok (pm.penerimaan.create)
//   • Opname    → stock opname (pm.opname.create)
//   • Transfer  → pindah gudang (pm.transfer.create)
//   • Akun      → selalu ada (profil + logout)
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../auth.dart';
import '../../config.dart';
import '../ui.dart';
import 'stok_screen.dart';
import 'masuk_screen.dart';
import 'opname_screen.dart';
import 'transfer_screen.dart';

class _Tab {
  final String label;
  final IconData icon;
  final Widget screen;
  const _Tab(this.label, this.icon, this.screen);
}

class StokShell extends StatefulWidget {
  const StokShell({super.key});
  @override
  State<StokShell> createState() => _StokShellState();
}

class _StokShellState extends State<StokShell> {
  int _index = 0;

  // Semua menu stok selalu tampil (tanpa cek role akses).
  static const _tabs = <_Tab>[
    _Tab('Stok', Icons.inventory_2_rounded, StokScreen()),
    _Tab('Masuk', Icons.south_west_rounded, MasukScreen()),
    _Tab('Opname', Icons.fact_check_outlined, OpnameScreen()),
    _Tab('Transfer', Icons.swap_horiz_rounded, TransferScreen()),
    _Tab('Akun', Icons.person_rounded, _AkunScreen()),
  ];

  @override
  Widget build(BuildContext context) {
    final tabs = _tabs;

    if (_index >= tabs.length) _index = 0;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: IndexedStack(index: _index, children: tabs.map((t) => t.screen).toList()),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          backgroundColor: AppTheme.surface,
          indicatorColor: AppTheme.primary.withValues(alpha: 0.14),
          destinations: [
            for (final t in tabs)
              NavigationDestination(
                icon: Icon(t.icon, color: AppTheme.faint),
                selectedIcon: Icon(t.icon, color: AppTheme.primary),
                label: t.label,
              ),
          ],
        ),
      ),
    );
  }
}

/// Tab Akun — profil user + akses + tombol logout.
class _AkunScreen extends StatelessWidget {
  const _AkunScreen();
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final u = auth.user;
    final akses = <String>[
      if (auth.hasModuleAccess('pm')) 'Lihat Stok',
      if (auth.can('pm.penerimaan.create')) 'Barang Masuk',
      if (auth.can('pm.opname.create')) 'Stock Opname',
      if (auth.can('pm.transfer.create')) 'Pindah Gudang',
    ];
    return Scaffold(
      body: Column(children: [
        const ModernHeader(title: 'Akun', subtitle: 'Profil & keluar'),
        Expanded(
          child: ListView(padding: EdgeInsets.fromLTRB(16, 16, 16, listBottomInset(context)), children: [
            SoftCard(
              child: Row(children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(gradient: AppTheme.brandGradient, borderRadius: BorderRadius.circular(16)),
                  alignment: Alignment.center,
                  child: Text((u?.nama ?? u?.email ?? 'U').substring(0, 1).toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(u?.nama ?? 'User',
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppTheme.ink)),
                    const SizedBox(height: 2),
                    Text(u?.email ?? '', style: const TextStyle(color: AppTheme.muted, fontSize: 13)),
                    if (u?.role != null) ...[
                      const SizedBox(height: 2),
                      Text('Role: ${u!.role}', style: const TextStyle(color: AppTheme.faint, fontSize: 12)),
                    ],
                  ]),
                ),
              ]),
            ),
            const SizedBox(height: 14),
            if (akses.isNotEmpty) ...[
              const SectionHeader('Akses Kamu', icon: Icons.badge_outlined),
              const SizedBox(height: 8),
              SoftCard(
                child: Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final p in akses)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(20)),
                      child: Text(p, style: const TextStyle(color: AppTheme.primaryDark, fontWeight: FontWeight.w700, fontSize: 12.5)),
                    ),
                ]),
              ),
              const SizedBox(height: 18),
            ],
            const SectionHeader('Server', icon: Icons.dns_outlined),
            const SizedBox(height: 8),
            SoftCard(
              child: Row(children: [
                const Icon(Icons.cloud_done_outlined, color: AppTheme.muted, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(Config.baseHost.replaceAll(RegExp(r'https?://'), ''),
                      style: const TextStyle(color: AppTheme.ink, fontWeight: FontWeight.w600, fontSize: 13)),
                ),
              ]),
            ),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(Icons.grid_view_rounded, color: AppTheme.primaryDark),
              label: const Text('Ganti Modul',
                  style: TextStyle(color: AppTheme.primaryDark, fontWeight: FontWeight.w700)),
              style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.border), minimumSize: const Size.fromHeight(50)),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () async {
                final authP = context.read<AuthProvider>();
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Keluar?'),
                    content: const Text('Kamu akan logout dari aplikasi.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
                      FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Keluar')),
                    ],
                  ),
                );
                if (ok == true) await authP.logout();
              },
              icon: const Icon(Icons.logout_rounded, color: AppTheme.danger),
              label: const Text('Keluar', style: TextStyle(color: AppTheme.danger, fontWeight: FontWeight.w700)),
              style: OutlinedButton.styleFrom(side: const BorderSide(color: AppTheme.border), minimumSize: const Size.fromHeight(50)),
            ),
          ]),
        ),
      ]),
    );
  }
}
