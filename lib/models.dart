// Model data — ngikutin JSON dari backend absensi (app/absensi/router.py).

int _asInt(dynamic v) => v == null ? 0 : (v is int ? v : (v is num ? v.toInt() : int.tryParse('$v') ?? 0));
String? _asStr(dynamic v) => v?.toString();
List<String> _asStrList(dynamic v) => (v as List?)?.map((e) => e.toString()).toList() ?? [];

class AppUser {
  final int id;
  final String? nama;
  final String email;
  final String? role;
  final bool isAdmin;
  final List<String> permissions;
  AppUser({required this.id, this.nama, required this.email, this.role, required this.isAdmin, required this.permissions});
  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(
        id: _asInt(j['id']),
        nama: _asStr(j['nama']),
        email: j['email']?.toString() ?? '',
        role: _asStr(j['role']),
        isAdmin: j['is_admin'] == true,
        permissions: _asStrList(j['permissions']),
      );
}

/// Info karyawan yang login + status hari ini (GET /absensi/me).
/// Shift kerja (Pagi/Siang/Sore). Dipilih karyawan saat clock-in.
class Shift {
  final int id;
  final String nama;
  final String jamMasuk;
  final String jamPulang;
  final int toleransiMenit;
  final int urutan;
  final bool aktif;
  Shift({required this.id, required this.nama, this.jamMasuk = '', this.jamPulang = '',
    this.toleransiMenit = 0, this.urutan = 0, this.aktif = true});
  factory Shift.fromJson(Map<String, dynamic> j) => Shift(
        id: _asInt(j['id']), nama: j['nama']?.toString() ?? '',
        jamMasuk: j['jam_masuk']?.toString() ?? '', jamPulang: j['jam_pulang']?.toString() ?? '',
        toleransiMenit: _asInt(j['toleransi_menit']), urutan: _asInt(j['urutan']),
        aktif: j['aktif'] != false,
      );
}

class AbsenMe {
  final bool linked;
  final String? nama;
  final String? kode;
  final String? jabatan;
  final String berikutnya; // masuk | pulang | selesai
  final String? jamMasuk;
  final String? jamPulang;
  final bool shiftWajib;
  final int? shiftId;
  final List<Shift> shifts;
  AbsenMe({required this.linked, this.nama, this.kode, this.jabatan, this.berikutnya = 'masuk',
    this.jamMasuk, this.jamPulang, this.shiftWajib = false, this.shiftId, this.shifts = const []});
  factory AbsenMe.fromJson(Map<String, dynamic> j) => AbsenMe(
        linked: j['linked'] == true,
        nama: _asStr(j['nama']), kode: _asStr(j['kode']), jabatan: _asStr(j['jabatan']),
        berikutnya: j['berikutnya']?.toString() ?? 'masuk',
        jamMasuk: _asStr(j['jam_masuk']), jamPulang: _asStr(j['jam_pulang']),
        shiftWajib: j['shift_wajib'] == true,
        shiftId: j['shift_id'] == null ? null : _asInt(j['shift_id']),
        shifts: ((j['shifts'] as List?) ?? []).map((e) => Shift.fromJson(e as Map<String, dynamic>)).toList(),
      );
}

/// Hasil clock in/out (POST /absensi/clock).
class ClockResult {
  final String action; // masuk | pulang | sudah_lengkap
  final String karyawan;
  final String jam;
  final String status;
  final String? shift;
  final int menitTelat;
  final int menitPulangCepat;
  final int durasiMenit;
  final String message;
  ClockResult({required this.action, required this.karyawan, required this.jam, required this.status,
    this.shift, this.menitTelat = 0, this.menitPulangCepat = 0, this.durasiMenit = 0, this.message = ''});
  factory ClockResult.fromJson(Map<String, dynamic> j) => ClockResult(
        action: j['action']?.toString() ?? '', karyawan: j['karyawan']?.toString() ?? '',
        jam: j['jam']?.toString() ?? '', status: j['status']?.toString() ?? '',
        shift: _asStr(j['shift']),
        menitTelat: _asInt(j['menit_telat']), menitPulangCepat: _asInt(j['menit_pulang_cepat']),
        durasiMenit: _asInt(j['durasi_menit']), message: j['message']?.toString() ?? '',
      );
}

class Attendance {
  final int id;
  final String tanggal;
  final String? shift;
  final String? jamMasuk;
  final String? jamPulang;
  final String status; // hadir|terlambat|izin|sakit|cuti|alpha|libur
  final int menitTelat;
  final int menitPulangCepat;
  final int durasiMenit;
  final String? source;
  Attendance({required this.id, required this.tanggal, this.shift, this.jamMasuk, this.jamPulang, this.status = 'hadir',
    this.menitTelat = 0, this.menitPulangCepat = 0, this.durasiMenit = 0, this.source});
  factory Attendance.fromJson(Map<String, dynamic> j) => Attendance(
        id: _asInt(j['id']), tanggal: j['tanggal']?.toString() ?? '',
        shift: _asStr(j['shift']),
        jamMasuk: _asStr(j['jam_masuk']), jamPulang: _asStr(j['jam_pulang']),
        status: j['status']?.toString() ?? 'hadir', menitTelat: _asInt(j['menit_telat']),
        menitPulangCepat: _asInt(j['menit_pulang_cepat']), durasiMenit: _asInt(j['durasi_menit']),
        source: _asStr(j['source']),
      );
}

class MySummary {
  final String periode;
  final int tahun, bulan;
  final String? karyawan, kode, jabatan;
  final int hariKerja, hadir, terlambat, izin, sakit, cuti, alpha, menitTelat, lemburMenit;
  final int kuotaCuti, cutiTerpakai;
  final String berikutnya;
  final String? jamMasuk, jamPulang, statusHariIni;
  MySummary({this.periode = '', this.tahun = 0, this.bulan = 0, this.karyawan, this.kode, this.jabatan,
    this.hariKerja = 0, this.hadir = 0, this.terlambat = 0, this.izin = 0, this.sakit = 0, this.cuti = 0,
    this.alpha = 0, this.menitTelat = 0, this.lemburMenit = 0, this.kuotaCuti = 0, this.cutiTerpakai = 0,
    this.berikutnya = 'masuk', this.jamMasuk, this.jamPulang, this.statusHariIni});
  factory MySummary.fromJson(Map<String, dynamic> j) {
    final hi = (j['hari_ini'] as Map?) ?? {};
    return MySummary(
      periode: j['periode']?.toString() ?? '', tahun: _asInt(j['tahun']), bulan: _asInt(j['bulan']),
      karyawan: _asStr(j['karyawan']), kode: _asStr(j['kode']), jabatan: _asStr(j['jabatan']),
      hariKerja: _asInt(j['hari_kerja']), hadir: _asInt(j['hadir']), terlambat: _asInt(j['terlambat']),
      izin: _asInt(j['izin']), sakit: _asInt(j['sakit']), cuti: _asInt(j['cuti']), alpha: _asInt(j['alpha']),
      menitTelat: _asInt(j['menit_telat']), lemburMenit: _asInt(j['lembur_menit']),
      kuotaCuti: _asInt(j['kuota_cuti']), cutiTerpakai: _asInt(j['cuti_terpakai']),
      berikutnya: hi['berikutnya']?.toString() ?? 'masuk',
      jamMasuk: _asStr(hi['jam_masuk']), jamPulang: _asStr(hi['jam_pulang']), statusHariIni: _asStr(hi['status']),
    );
  }
}

class Overtime {
  final int id;
  final String tanggal;
  final String? jamMulai, jamSelesai;
  final int durasiMenit;
  final String? alasan;
  final String status; // diajukan | disetujui | ditolak
  Overtime({required this.id, required this.tanggal, this.jamMulai, this.jamSelesai, this.durasiMenit = 0,
    this.alasan, this.status = 'diajukan'});
  factory Overtime.fromJson(Map<String, dynamic> j) => Overtime(
        id: _asInt(j['id']), tanggal: j['tanggal']?.toString() ?? '',
        jamMulai: _asStr(j['jam_mulai']), jamSelesai: _asStr(j['jam_selesai']),
        durasiMenit: _asInt(j['durasi_menit']), alasan: _asStr(j['alasan']),
        status: j['status']?.toString() ?? 'diajukan',
      );
}
