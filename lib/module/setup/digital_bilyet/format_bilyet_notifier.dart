import 'package:cms_core/module/shared/banking_widgets.dart';
// lib/module/format_bilyet/format_bilyet_notifier.dart
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'format_bilyet_model.dart';
import 'package:cms_core/pref/pref.dart';
import 'format_bilyet_repository.dart';
import 'format_bilyet_paper.dart';

/// Format bilyet deposito milik BPR (disimpan di DB setup-service Core) + aksi simpan / hapus.
/// Aturannya satu BPR satu format, jadi halaman cukup memegang satu [format].
/// Form tambah/edit beserta preview-nya ada di format_bilyet_form.dart.
class FormatBilyetNotifier extends ChangeNotifier {
  FormatBilyetNotifier() {
    loadData();
  }

  BankingPermissions access = const BankingPermissions();
  bool isLoading = true;
  String? errorMessage;

  /// Format bilyet yang berlaku; null kalau belum dibuat.
  FormatBilyetModel? format;

  /// Gambar latar [format] yang sudah di-decode, untuk preview.
  Uint8List? bgBytes;

  /// Ukuran asli gambar latar (px), untuk peringatan rasio tidak sebanding dengan kertas.
  Size? bgSize;

  /// Tampilan preview latar: false = Fit (gambar utuh), true = Hasil Cetak (direntangkan).
  bool hasilCetak = false;

  void setHasilCetak(bool v) {
    hasilCetak = v;
    _notify();
  }

  /// Jumlah data di DB. Normalnya 0 atau 1; lebih dari 1 hanya sisa data lama sebelum
  /// aturan satu format berlaku.
  int jumlahFormat = 0;

  String _bprId = '';
  String _userLogin = '';
  bool _disposed = false;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<bool> _ensureSession() async {
    if (_bprId.isNotEmpty && _userLogin.isNotEmpty) return true;
    try {
      access = await BankingPermissions.load('/setup/format-bilyet');
      final users = await Pref().getUsers();
      _bprId = users.kodePt;
      _userLogin = users.userid;
    } catch (_) {}
    return _bprId.isNotEmpty && _userLogin.isNotEmpty;
  }

  Future<void> loadData() async {
    isLoading = true;
    errorMessage = null;
    _notify();

    if (!await _ensureSession()) {
      errorMessage = 'Sesi tidak valid, silakan login ulang';
      isLoading = false;
      _notify();
      return;
    }

    final res = await FormatBilyetRepository.list(bprId: _bprId, userLogin: _userLogin);
    if (res['success'] == true) {
      final items = List<FormatBilyetModel>.from(res['data'] as List);
      // setup-service Core mengurutkan dari yang terakhir disimpan/diedit -- sama dengan yang
      // dikirim /inquiry/format-bilyet ke Medfo mobile.
      format = items.isEmpty ? null : items.first;
      bgBytes = format?.bgBytes; // decode sekali, bukan tiap build
      bgSize = bgBytes == null ? null : await ukurGambar(bgBytes!);
      jumlahFormat = items.length;
    } else {
      errorMessage = (res['message'] ?? 'Gagal memuat format bilyet').toString();
    }

    isLoading = false;
    _notify();
  }

  /// Insert (id == 0) atau update. Return null kalau sukses, atau pesan error.
  Future<String?> simpan(FormatBilyetModel data) async {
    if (!await _ensureSession()) return 'Sesi tidak valid, silakan login ulang';
    if (data.id==0?!access.create:!access.update) return 'Akses ditolak';
    final res = await FormatBilyetRepository.simpan(
      bprId: _bprId,
      userLogin: _userLogin,
      data: data,
    );
    if (res['success'] != true) {
      return (res['message'] ?? 'Gagal menyimpan format bilyet').toString();
    }
    await loadData();
    return null;
  }

  /// Return null kalau sukses, atau pesan error.
  Future<String?> hapus(FormatBilyetModel data) async {
    if (!await _ensureSession()) return 'Sesi tidak valid, silakan login ulang';
    isLoading = true;
    _notify();

    if (!access.delete) {isLoading=false;_notify();return 'Akses ditolak';}
    final res = await FormatBilyetRepository.hapus(
      bprId: _bprId,
      userLogin: _userLogin,
      id: data.id,
    );
    if (res['success'] != true) {
      isLoading = false;
      _notify();
      return (res['message'] ?? 'Gagal menghapus format bilyet').toString();
    }
    await loadData();
    return null;
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
