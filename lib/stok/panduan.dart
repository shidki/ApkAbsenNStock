// Panduan kontekstual modul Stok.
//
// Tiap menu (tab) punya tombol "buku" di kanan atas header. Ditekan → muncul
// bottom-sheet berisi panduan KHUSUS menu itu. Konten disimpan di _guides,
// tombolnya pakai PanduanButton, popup-nya lewat showPanduan().
import 'package:flutter/material.dart';
import '../config.dart';

/// Menu mana panduannya.
enum PanduanTopic { stok, masuk, opname, transfer, akun }

// ─────────────────────── MODEL KONTEN ───────────────────────
class _Section {
  final String heading;
  final IconData icon;
  final List<String> items;
  final bool numbered; // true → langkah bernomor, false → poin bullet
  const _Section(this.heading, this.icon, this.items, {this.numbered = false});
}

class _Guide {
  final String title;
  final IconData icon;
  final String intro;
  final List<_Section> sections;
  const _Guide({required this.title, required this.icon, required this.intro, required this.sections});
}

// ─────────────────────── ISI PANDUAN ───────────────────────
const _guides = <PanduanTopic, _Guide>{
  PanduanTopic.stok: _Guide(
    title: 'Panduan: Stok',
    icon: Icons.inventory_2_rounded,
    intro: 'Menu ini untuk melihat & memantau seluruh stok produk.',
    sections: [
      _Section('Ringkasan Angka (atas)', Icons.bar_chart_rounded, [
        'SKU — jumlah jenis produk yang tampil.',
        'Total Unit — total semua barang (stok digabung).',
        'Nilai Modal — total nilai stok (harga beli × stok).',
        'Perlu Perhatian — jumlah produk yang stoknya menipis / habis.',
      ]),
      _Section('Cara Pakai', Icons.touch_app_rounded, [
        'Ketik di kolom pencarian untuk cari nama produk atau SKU.',
        'Ketuk "Semua Gudang" / "Semua Kategori" untuk menyaring. Tombol "Reset filter" muncul untuk kembali ke semua.',
        'Tarik layar ke bawah atau ketuk ikon 🔄 untuk memuat data terbaru.',
      ], numbered: true),
      _Section('Kartu Stok (per produk)', Icons.history_rounded, [
        'Ketuk salah satu produk di daftar.',
        'Lihat Stok Saat Ini, Stok Min, Nilai Modal, dan stok per ukuran (kalau ada).',
        'Bagian Riwayat Mutasi menampilkan semua pergerakan stok + Saldo berjalan.',
      ], numbered: true),
      _Section('Arti Status', Icons.circle, [
        'Aman — stok masih cukup.',
        'Menipis — stok di bawah / di batas minimum.',
        'Habis — stok 0.',
      ]),
    ],
  ),
  PanduanTopic.masuk: _Guide(
    title: 'Panduan: Barang Masuk',
    icon: Icons.south_west_rounded,
    intro: 'Dipakai saat barang datang / stok bertambah (produksi selesai, beli dari supplier).',
    sections: [
      _Section('Langkah Menambah Stok', Icons.playlist_add_check_rounded, [
        'Tekan tombol ➕ Tambah Stok di kanan bawah.',
        'Pilih Gudang tempat barang masuk.',
        'Pilih Produk (hanya produk milik gudang itu yang muncul).',
        'Isi kolom "Masuk" pada ukuran yang bertambah — boleh beberapa ukuran sekaligus.',
        'Butuh ukuran yang belum ada? Ketuk "+ Ukuran", ketik ukurannya, lalu isi jumlah.',
        'Atur Tanggal (default hari ini). Petugas & Keterangan opsional.',
        'Tekan "Simpan Stok Masuk" — stok otomatis bertambah.',
      ], numbered: true),
      _Section('Perlu Diingat', Icons.info_outline_rounded, [
        'Minimal isi jumlah di 1 ukuran, kalau tidak tidak bisa disimpan.',
        'Menghapus penerimaan dari riwayat = stok dikurangi lagi sesuai jumlah tadi.',
      ]),
    ],
  ),
  PanduanTopic.opname: _Guide(
    title: 'Panduan: Stock Opname',
    icon: Icons.fact_check_outlined,
    intro: 'Untuk menyamakan stok di sistem dengan hasil hitung fisik di gudang. Selisih dicatat otomatis.',
    sections: [
      _Section('Langkah Opname', Icons.checklist_rounded, [
        'Tekan tombol ➕ Opname di kanan bawah.',
        'Pilih Gudang, lalu pilih Produk.',
        'Di kolom "Fisik", isi jumlah asli hasil hitung fisik kamu.',
        'Kolom "Selisih" terisi otomatis (hijau = lebih, merah = kurang).',
        'Atur Tanggal. Petugas & Keterangan opsional.',
        'Tekan "Simpan Koreksi" — stok otomatis diset sama dengan fisik.',
      ], numbered: true),
      _Section('Perlu Diingat', Icons.info_outline_rounded, [
        'Tombol simpan hanya aktif kalau ada selisih. Kalau fisik = sistem, tidak perlu disimpan.',
        'Menghapus koreksi dari riwayat = stok kembali ke nilai sebelum opname.',
      ]),
    ],
  ),
  PanduanTopic.transfer: _Guide(
    title: 'Panduan: Pindah Gudang',
    icon: Icons.swap_horiz_rounded,
    intro: 'Untuk memindahkan stok antar gudang. Stok gudang asal berkurang, gudang tujuan bertambah.',
    sections: [
      _Section('Langkah Transfer', Icons.local_shipping_outlined, [
        'Tekan tombol ➕ Pindah di kanan bawah.',
        'Pilih Gudang Asal (dari mana barang diambil).',
        'Pilih Gudang Tujuan (tidak boleh sama dengan asal).',
        'Pilih Produk (hanya produk di gudang asal).',
        'Isi jumlah pada ukuran yang dipindah — boleh beberapa ukuran sekaligus.',
        'Atur Tanggal. Petugas & Keterangan opsional.',
        'Tekan "Simpan Transfer".',
      ], numbered: true),
      _Section('Perlu Diingat', Icons.info_outline_rounded, [
        'Jumlah pindah tidak boleh melebihi stok di gudang asal.',
        'Menghapus transfer dari riwayat = stok dikembalikan ke gudang asal.',
      ]),
    ],
  ),
  PanduanTopic.akun: _Guide(
    title: 'Panduan: Akun',
    icon: Icons.person_rounded,
    intro: 'Berisi profil, daftar akses, dan tombol keluar.',
    sections: [
      _Section('Isi Menu', Icons.badge_outlined, [
        'Profil — nama, email, dan role kamu.',
        'Akses Kamu — daftar izin yang kamu miliki di modul stok.',
        'Ganti Modul — kembali ke pemilih modul (mis. pindah ke Absensi).',
        'Keluar — logout dari aplikasi (ada konfirmasi dulu).',
      ]),
    ],
  ),
};

// ─────────────────────── TOMBOL "BUKU" ───────────────────────
/// Tombol ikon buku (putih) untuk dipasang di `ModernHeader.trailing`.
class PanduanButton extends StatelessWidget {
  final PanduanTopic topic;
  const PanduanButton(this.topic, {super.key});
  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () => showPanduan(context, topic),
      icon: const Icon(Icons.menu_book_rounded, color: Colors.white),
      tooltip: 'Panduan',
    );
  }
}

// ─────────────────────── POPUP PANDUAN ───────────────────────
void showPanduan(BuildContext context, PanduanTopic topic) {
  final g = _guides[topic]!;
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => DraggableScrollableSheet(
      initialChildSize: 0.82,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (ctx, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(children: [
          _PanduanHeader(g),
          Expanded(
            child: ListView(
              controller: scrollCtrl,
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
              children: [
                Text(g.intro, style: const TextStyle(color: AppTheme.muted, fontSize: 13.5, height: 1.45)),
                const SizedBox(height: 18),
                for (final s in g.sections) ...[
                  _SectionBlock(s),
                  const SizedBox(height: 18),
                ],
              ],
            ),
          ),
        ]),
      ),
    ),
  );
}

class _PanduanHeader extends StatelessWidget {
  final _Guide g;
  const _PanduanHeader(this.g);
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 14, 12, 18),
      decoration: const BoxDecoration(gradient: AppTheme.brandGradient),
      child: Column(children: [
        Container(
          width: 38, height: 4,
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(4)),
        ),
        const SizedBox(height: 14),
        Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(13)),
            child: Icon(g.icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('PANDUAN', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
              const SizedBox(height: 2),
              Text(g.title.replaceFirst('Panduan: ', ''),
                  style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w900, letterSpacing: -0.3)),
            ]),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded, color: Colors.white),
          ),
        ]),
      ]),
    );
  }
}

class _SectionBlock extends StatelessWidget {
  final _Section s;
  const _SectionBlock(this.s);
  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(s.icon, size: 18, color: AppTheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(s.heading, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5, color: AppTheme.ink)),
        ),
      ]),
      const SizedBox(height: 12),
      for (int i = 0; i < s.items.length; i++) ...[
        if (i > 0) const SizedBox(height: 10),
        _ItemRow(index: i + 1, text: s.items[i], numbered: s.numbered),
      ],
    ]);
  }
}

class _ItemRow extends StatelessWidget {
  final int index;
  final String text;
  final bool numbered;
  const _ItemRow({required this.index, required this.text, required this.numbered});
  @override
  Widget build(BuildContext context) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (numbered)
        Container(
          width: 22, height: 22,
          margin: const EdgeInsets.only(top: 1),
          decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.12), shape: BoxShape.circle),
          alignment: Alignment.center,
          child: Text('$index', style: const TextStyle(color: AppTheme.primaryDark, fontSize: 11.5, fontWeight: FontWeight.w800)),
        )
      else
        Container(
          width: 6, height: 6,
          margin: const EdgeInsets.only(top: 7, right: 0),
          decoration: const BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle),
        ),
      const SizedBox(width: 11),
      Expanded(
        child: Text(text, style: const TextStyle(color: AppTheme.ink, fontSize: 13.5, height: 1.42)),
      ),
    ]);
  }
}
