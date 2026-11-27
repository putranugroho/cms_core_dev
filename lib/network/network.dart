const token = "715f8ab555438f985b579844ea227767";
const xusername = "core@2023";
const xpassword = "corevalue@20231234";

const dev = false;

const url = dev ? "https://api-core.medtrans.id" : "https://api-core.medtrans.id";

const url2 = "https://core.metimes.id";

class NetworkURL {
  static String login() {
    return "$url/sign-in";
  }

  static String gerPerusahaan() {
    return "$url/perusahaan";
  }

  static String getKantor() {
    return "$url/setup/office/list";
  }

  static String hrisInquiryKantor() {
    return "$url/hris/kantor";
  }

  static String hrisInquiryEmployee() {
    return "$url/hris/employee";
  }

  static String addKantor() {
    return "$url/setup/office/create";
  }

  static String updateKantor() {
    return "$url/setup/office/update";
  }

  static String deletedKantor() {
    return "$url/setup/office/delete";
  }

  static String getLevelJabatan() {
    return "$url/leveljabatan";
  }

  static String addLevelJabatan() {
    return "$url/leveljabatan/add";
  }

  static String updateLevelJabatan() {
    return "$url/leveljabatan/update";
  }

  static String deletedLevelJabatan() {
    return "$url/leveljabatan/deleted";
  }

  static String getjabatan() {
    return "$url/jabatan";
  }

  static String addJabatan() {
    return "$url/jabatan/add";
  }

  static String updatedJabatan() {
    return "$url/jabatan/update";
  }

  static String deletedJabatan() {
    return "$url/jabatan/deleted";
  }

  static String getPejabat() {
    return "$url/pejabat";
  }

  static String getInventaris() {
    return "$url/inventaris";
  }

  static String addInventaris() {
    return "$url/inventaris/add";
  }

  static String editInventaris() {
    return "$url/inventaris/update";
  }

  static String deleteInventaris() {
    return "$url/inventaris/deleted";
  }

  static String penempatan() {
    return "$url/inventaris/penempatan";
  }

  static String revaluasi() {
    return "$url/inventaris/revaluasi";
  }

  static String jual() {
    return "$url/inventaris/jual";
  }

  static String hapusaset() {
    return "$url/inventaris/hapusaset";
  }

  static String cariInventaris() {
    return "$url/inventaris/cari";
  }

  static String addPejabat() {
    return "$url/pejabat/add";
  }

  static String updatedPejabat() {
    return "$url/pejabat/update";
  }

  static String deletedPejabat() {
    return "$url/pejabat/deleted";
  }

  static String getMasterGl() {
    return "$url/setup/coa/list";
  }

  static String getMasterGlSubtree() {
    return "$url/setup/coa/list";
  }

  static String addMasterGl() {
    return "$url/setup/coa/create";
  }

  static String editMasterGl() {
    return "$url/setup/coa/update";
  }

  static String deleteMasterGl() {
    return "$url/setup/coa/delete";
  }

  static String tutup() {
    return "$url/mastergl/tutup";
  }

  static String getMetodePenyusutan() {
    return "$url/metode_penyusutan";
  }

  static String editMetodePenyusutan() {
    return "$url/metode_penyusutan/update";
  }

  static String getKelompokAset() {
    return "$url/kelompokaset";
  }

  static String addKelompokAset() {
    return "$url/kelompokaset/add";
  }

  static String editKelompokAset() {
    return "$url/kelompokaset/update";
  }

  static String deleteKelompokAset() {
    return "$url/kelompokaset/deleted";
  }

  static String getGolonganAset() {
    return "$url/golonganaset";
  }

  static String addGolonganAset() {
    return "$url/golonganaset/add";
  }

  static String editGolonganAset() {
    return "$url/golonganaset/update";
  }

  static String deleteGolonganAset() {
    return "$url/golonganaset/deleted";
  }

  static String getGolonganSbb() {
    return "$url/golongansbb";
  }

  static String addGolonganSbb() {
    return "$url/golongansbb/add";
  }

  static String editGolonganSbb() {
    return "$url/golongansbb/update";
  }

  static String deleteGolonganSbb() {
    return "$url/golongansbb/deleted";
  }

  static String getInqueryGL() {
    return "$url/setup/coa/list";
  }

  static String getSbbKhusus() {
    return "$url/sbbkhusus";
  }

  static String perantara() {
    return "$url/perantara";
  }

  static String transaksiHutangPiutang() {
    return "$url/transaksiHutangPiutang";
  }

  static String addSbbKhusus() {
    return "$url/sbbkhusus/add";
  }

  static String editSbbKhusus() {
    return "$url/sbbkhusus/update";
  }

  static String deleteSbbKhusus() {
    return "$url/sbbkhusus/deleted";
  }

  static String getSetupTrans() {
    return "$url/setuptrans";
  }

  static String getSetupPajak() {
    return "$url/setuppajak";
  }

  static String editSetupPajak() {
    return "$url/setuppajak/update";
  }

  static String addSetupPajak() {
    return "$url/setuppajak/add";
  }

  static String deleteSetupPajak() {
    return "$url/setuppajak/deleted";
  }

  static String addSetupTrans() {
    return "$url/setuptrans/add";
  }

  static String editSetupTrans() {
    return "$url/setuptrans/update";
  }

  static String deleteSetupTrans() {
    return "$url/setuptrans/deleted";
  }

  static String getSetupKasKecil() {
    return "$url/setupkaskecil";
  }

  static String addSetupKasKecil() {
    return "$url/setupkaskecil/add";
  }

  static String bayarHutangPiutang() {
    return "$url/hutangpiutangdetail/bayar";
  }

  static String getSetupHutangPiutang() {
    return "$url/setuphutangpiutang";
  }

  static String addSetupHutangPiutang() {
    return "$url/setuphutangpiutang/add";
  }

  static String getusers() {
    return "$url/users";
  }

  static String addusers() {
    return "$url/users/add";
  }

  static String editusers() {
    return "$url/users/update";
  }

  static String deleteusers() {
    return "$url/users/deleted";
  }

  static String getAktivasi() {
    return "$url/aktivasi";
  }

  static String addAktivasi() {
    return "$url/aktivasi/add";
  }

  static String editAktivasi() {
    return "$url/aktivasi/update";
  }

  static String deleteAktivasi() {
    return "$url/aktivasi/deleted";
  }

  static String getCustomer() {
    return "$url/customerssupplier";
  }

  static String addCustomer() {
    return "$url/customerssupplier/add";
  }

  static String editCustomer() {
    return "$url/customerssupplier/update";
  }

  static String deleteCustomer() {
    return "$url/customerssupplier/deleted";
  }

  static String getAoMarketing() {
    return "$url/aomarketing";
  }

  static String addAoMarketing() {
    return "$url/aomarketing/add";
  }

  static String editAoMarketing() {
    return "$url/aomarketing/update";
  }

  static String deleteAoMarketing() {
    return "$url/aomarketing/deleted";
  }

  static String nonaktif() {
    return "$url/aomarketing/nonaktif";
  }

  static String getHutangPiutang() {
    return "$url/hutangpiutang";
  }

  static String addHutangPiutang() {
    return "$url/hutangpiutang/add";
  }

  static String editHutangPiutang() {
    return "$url/hutangpiutang/update";
  }

  static String deleteHutangPiutang() {
    return "$url/hutangpiutang/deleted";
  }

  static String searchHutangPiutang() {
    return "$url/hutangpiutangdetail/search";
  }

  static String getBank() {
    return "$url/bank";
  }

  static String getSandiBank() {
    return "$url/sandi-bank";
  }

  static String addBank() {
    return "$url/bank/add";
  }

  static String editBank() {
    return "$url/bank/update";
  }

  static String deleteBank() {
    return "$url/bank/deleted";
  }

  static String getClosingEom() {
    return "$url/closingeomsetup";
  }

  static String addClosingEom() {
    return "$url/closingeomsetup/add";
  }

  static String editClosingEom() {
    return "$url/closingeomsetup/update";
  }

  static String getModul() {
    return "$url/modul";
  }

  static String getLevelUsers() {
    return "$url/leveluser";
  }

  static String addLevelUsers() {
    return "$url/leveluser/add";
  }

  static String editLevelUsers() {
    return "$url/leveluser/update";
  }

  static String editLevelUsersModul() {
    return "$url/leveluser/updatemodul";
  }

  static String deletdLevelUsers() {
    return "$url/leveluser/deleted";
  }

  static String getKaryawan() {
    return "$url/karyawan";
  }

  static String getUserAksesPoint() {
    return "$url/user-akses-point";
  }

  static String addUserAksesPoint() {
    return "$url/user-akses-point/add";
  }

  static String deletedUserAksesPoint() {
    return "$url/user-akses-point/deleted";
  }

  static String getUsersAksesPointAll() {
    return "$url/user-akses-point/viewall";
  }

  static String otorisasi() {
    return "$url/General-ledger/otorisasi";
  }

  static String neracaBerjalan() {
    return "$url/report";
  }

  static String neracaBerjalanV2() {
    return "$url/neraca-berjalan";
  }

  static String labaRugiBerjalan() {
    return "$url/labarugi-berjalan";
  }

  static String saldoGl() {
    return "$url/saldo-gl";
  }

  static String transaksi() {
    return "$url/transaksi";
  }

  static String search() {
    return "$url/transaksi/search";
  }

  static String bayardimuka() {
    return "$url/transaksi/bayardimuka";
  }

  static String bayardimukahapus() {
    return "$url/transaksi/bayardimukahapus";
  }

  static String bayardimukaubah() {
    return "$url/transaksi/bayardimukaubah";
  }

  static String viewbayardimuka() {
    return "$url/bayardimuka";
  }

  static String view() {
    return "$url/transaksi/view";
  }

  static String viewnokontrak() {
    return "$url/viewnokontrak";
  }

  static String otorisasiTransaksi() {
    return "$url/transaksi/otorisasi";
  }

  static String batal() {
    return "$url/transaksi/batal";
  }

  static String auth() {
    return "$url/auth/login";
  }

  static String authLogin() {
    return "$url/auth/login";
  }

  static String authLogout() {
    return "$url/auth/logout";
  }

  static String sessionCheck() {
    return "$url/auth/session/check";
  }

  static String sessionHeartbeat() {
    return "$url/auth/session/heartbeat";
  }

  static String cmsCoreStatus() {
    return "$url/system/cms-core/status";
  }

  static String cmsCoreToggle() {
    return "$url/system/cms-core/toggle";
  }

  static String coreMasterMenu() {
    return "$url/core/master_menu";
  }

  static String setupKodeTransaksiTabungan() {
    return "$url/core/setup_kode_transaksi_tabungan";
  }

  static String coreUsersList() {
    return "$url/users/list";
  }

  static String coreUsersDetail() {
    return "$url/users/detail";
  }

  static String coreUsersSave() {
    return "$url/users/save";
  }

  static String coreUsersAccess() {
    return "$url/users/access";
  }

  static String coreUsersNonaktif() {
    return "$url/users/nonaktif";
  }

  static String coreUsersAktif() {
    return "$url/users/aktif";
  }

  static String coreUsersForceLogout() {
    return "$url/users/force-logout";
  }

  static String coreUsersUnlock() {
    return "$url/users/unlock";
  }

  static String aoList() {
    return "$url/master/ao/list";
  }

  static String aoDetail() {
    return "$url/master/ao/detail";
  }

  static String aoCreate() {
    return "$url/master/ao/create";
  }

  static String aoUpdate() {
    return "$url/master/ao/update";
  }

  static String aoDelete() {
    return "$url/master/ao/delete";
  }

  static String sandiList() {
    return "$url/setup/sandi/list";
  }

  static String sandiDetail() {
    return "$url/setup/sandi/detail";
  }

  static String sandiCreate() {
    return "$url/setup/sandi/create";
  }

  static String sandiUpdate() {
    return "$url/setup/sandi/update";
  }

  static String sandiDelete() {
    return "$url/setup/sandi/delete";
  }

  static String sandiGroupList() {
    return "$url/setup/sandi/group/list";
  }

  static String formatBukuList() {
    return "$url/setup/format-buku/list";
  }

  static String formatBukuDetail() {
    return "$url/setup/format-buku/detail";
  }

  static String formatBukuCreate() {
    return "$url/setup/format-buku/create";
  }

  static String formatBukuUpdate() {
    return "$url/setup/format-buku/update";
  }

  static String formatBukuDelete() {
    return "$url/setup/format-buku/delete";
  }

  static String formatCoverList() {
    return "$url/setup/format-cover/list";
  }

  static String formatCoverDetail() {
    return "$url/setup/format-cover/detail";
  }

  static String formatCoverCreate() {
    return "$url/setup/format-cover/create";
  }

  static String formatCoverUpdate() {
    return "$url/setup/format-cover/update";
  }

  static String formatCoverDelete() {
    return "$url/setup/format-cover/delete";
  }

  static String formatBilyetList() {
    return "$url/setup/format-bilyet/list";
  }

  static String formatBilyetDetail() {
    return "$url/setup/format-bilyet/detail";
  }

  static String formatBilyetCreate() {
    return "$url/setup/format-bilyet/create";
  }

  static String formatBilyetUpdate() {
    return "$url/setup/format-bilyet/update";
  }

  static String formatBilyetDelete() {
    return "$url/setup/format-bilyet/delete";
  }

  static String sandiTransaksiBukuList() {
    return "$url/setup/sandi-transaksi-buku/list";
  }

  static String sandiTransaksiBukuDetail() {
    return "$url/setup/sandi-transaksi-buku/detail";
  }

  static String sandiTransaksiBukuCreate() {
    return "$url/setup/sandi-transaksi-buku/create";
  }

  static String sandiTransaksiBukuUpdate() {
    return "$url/setup/sandi-transaksi-buku/update";
  }

  static String sandiTransaksiBukuDelete() {
    return "$url/setup/sandi-transaksi-buku/delete";
  }

  static String savingProductList() {
    return "$url/setup/saving-product/list";
  }

  static String savingProductDetail() {
    return "$url/setup/saving-product/detail";
  }

  static String savingProductCreate() {
    return "$url/setup/saving-product/create";
  }

  static String savingProductUpdate() {
    return "$url/setup/saving-product/update";
  }

  static String savingProductDelete() {
    return "$url/setup/saving-product/delete";
  }

  static String agunanList() {
    return "$url/setup/agunan/list";
  }

  static String agunanDetail() {
    return "$url/setup/agunan/detail";
  }

  static String agunanCreate() {
    return "$url/setup/agunan/create";
  }

  static String agunanUpdate() {
    return "$url/setup/agunan/update";
  }

  static String agunanDelete() {
    return "$url/setup/agunan/delete";
  }

  // Kategori agunan custom: disimpan di /setup/request-kategori (field dinamis field_1..N).
  static String requestKategoriList() {
    return "$url/setup/request-kategori/list";
  }

  static String requestKategoriDetail() {
    return "$url/setup/request-kategori/detail";
  }

  static String requestKategoriCreate() {
    return "$url/setup/request-kategori/create";
  }

  static String requestKategoriUpdate() {
    return "$url/setup/request-kategori/update";
  }

  static String requestKategoriDelete() {
    return "$url/setup/request-kategori/delete";
  }

  static String bobotPpapList() {
    return "$url/setup/bobot-ppap/list";
  }

  static String bobotPpapDetail() {
    return "$url/setup/bobot-ppap/detail";
  }

  static String bobotPpapCreate() {
    return "$url/setup/bobot-ppap/create";
  }

  static String bobotPpapUpdate() {
    return "$url/setup/bobot-ppap/update";
  }

  static String bobotPpapDelete() {
    return "$url/setup/bobot-ppap/delete";
  }

  static String pajakAgregatUpsert() {
    return "$url/setup/pajak-agregat/upsert";
  }

  static String pajakAgregatList() {
    return "$url/setup/pajak-agregat/list";
  }

  static String pajakAgregatDetail() {
    return "$url/setup/pajak-agregat/detail";
  }

  static String rakSetupOffice() {
    return "$url/setup/rak/setup-office";
  }

  static String rakOfficeDetail() {
    return "$url/setup/rak/office-detail";
  }

  static String rakSetupRate() {
    return "$url/setup/rak/setup-rate";
  }

  static String rakRateDetail() {
    return "$url/setup/rak/rate-detail";
  }

  static String rakRelasiCreate() {
    return "$url/setup/rak/relasi-create";
  }

  static String rakRelasiList() {
    return "$url/setup/rak/relasi-list";
  }

  static String rakRelasiUpdate() {
    return "$url/setup/rak/relasi-update";
  }

  static String rakRelasiDelete() {
    return "$url/setup/rak/relasi-delete";
  }

  static String cariKaryawan() {
    return "$url/karyawan/search";
  }

  static String rabMarketing(String action) => "$url/master/rab-marketing/$action";
  static String rabKantor(String action) => "$url/master/rab-kantor/$action";

  static String cariUsers() {
    return "$url/users/search";
  }

  static String getAksesPoint() {
    return "$url/akses-point";
  }

  static String insertAksesPoint() {
    return "$url/akses-point/add";
  }

  static String editAksesPoint(int id) {
    return "$url/akses-point/$id";
  }

  static String deleteAksesPoint(int id) {
    return "$url/akses-point/$id";
  }

  static String getProvinsi() {
    return "$url2/provinsi";
  }

  static String getKota(String id) {
    return "$url2/kota?id=$id";
  }

  static String getKecamatan(String id) {
    return "$url2/kecamatan?id=$id";
  }

  static String getKelurahan(String id) {
    return "$url2/kelurahan?id=$id";
  }


  static String setupLoanList() {
    return "$url/setup/loan/list";
  }

  static String setupLoanDetail() {
    return "$url/setup/loan/detail";
  }

  static String setupLoanCreate() {
    return "$url/setup/loan/create";
  }

  static String setupLoanUpdate() {
    return "$url/setup/loan/update";
  }

  static String setupLoanDelete() {
    return "$url/setup/loan/delete";
  }

  // Template SPK per produk kredit: list, detail, create, update, delete.
  static String setupLoanSpkTemplate(String action) => "$url/setup/loan/spk-template/$action";


  static String setupInventarisList() {
    return "$url/setup/inventaris/list";
  }

  static String setupInventarisDetail() {
    return "$url/setup/inventaris/detail";
  }

  static String setupInventarisCreate() {
    return "$url/setup/inventaris/create";
  }

  static String setupInventarisUpdate() {
    return "$url/setup/inventaris/update";
  }

  static String setupInventarisDelete() {
    return "$url/setup/inventaris/delete";
  }

  static String masterAbaList() {
    return "$url/master/aba/list";
  }

  static String masterAbaDetail() {
    return "$url/master/aba/detail";
  }

  static String masterAbaCreate() {
    return "$url/master/aba/create";
  }

  static String masterAbaUpdate() {
    return "$url/master/aba/update";
  }

  static String masterAbaDelete() {
    return "$url/master/aba/delete";
  }

  static String thirdPartyCapabilities() => "$url/core/third-party/capabilities";
  // Kelompok Mitra (master-service): kode, nama, SBB fee mitra.
  static String partyGroupEndpoint(String action) => "$url/master/kelompok-mitra/$action";
  static String thirdPartyEndpoint(String action) => "$url/setup/data-pihak-ketiga/$action";

  static String masterInventarisList() {
    return "$url/master/inventaris/list";
  }

  static String masterInventarisDetail() {
    return "$url/master/inventaris/detail";
  }

  static String masterInventarisCreate() {
    return "$url/master/inventaris/create";
  }

  static String masterInventarisUpdate() {
    return "$url/master/inventaris/update";
  }

  static String masterInventarisDelete() {
    return "$url/master/inventaris/delete";
  }

  static String masterMitraBisnisSearch() {
    return "$url/master/mitra-bisnis/search";
  }

  static String masterMitraBisnisDetail() {
    return "$url/master/mitra-bisnis/detail";
  }

  static String masterMitraBisnisCreate() {
    return "$url/master/mitra-bisnis/create";
  }

  static String masterMitraBisnisUpdate() {
    return "$url/master/mitra-bisnis/update";
  }

  static String masterMitraBisnisDelete() {
    return "$url/master/mitra-bisnis/delete";
  }

  static String bprProfile() {
    return "https://api-dev-cms.medtrans.id/bpr_profile";
  }

}
