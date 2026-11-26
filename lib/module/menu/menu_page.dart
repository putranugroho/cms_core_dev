import 'package:cms_core/module/setup/digital_bilyet/bilyet_category_page.dart';
import 'package:cms_core/module/setup/simple_menus/simple_menu_pages.dart';
import 'package:cms_core/module/master/rab/rab_realisasi_page.dart';
import 'package:cms_core/module/master/inventaris_operations/inventaris_assignment_page.dart';
import 'package:cms_core/module/master/inventaris_operations/inventaris_operations_page.dart';
import 'package:cms_core/module/gl/gl_page.dart';
import 'package:cms_core/module/level_user/level_user_page.dart';
import 'package:cms_core/module/master/users/users_page.dart';
import 'package:cms_core/module/master/ao/ao_page.dart';
import 'package:cms_core/module/menu/menu_notifier.dart';
import 'package:cms_core/module/menu/menu_widget.dart';
import 'package:cms_core/module/setup/kantor/kantor_page.dart';
import 'package:cms_core/module/setup/product_deposito/product_deposito_page.dart';
import 'package:cms_core/module/setup/product_kredit/product_kredit_page.dart';
import 'package:cms_core/module/setup/product_tabungan/product_tabungan_page.dart';
import 'package:cms_core/module/setup/pajak_agregat/pajak_agregat_page.dart';
import 'package:cms_core/module/setup/sandi/sandi_page.dart';
import 'package:cms_core/module/setup/format_print/format_print_pages.dart';
import 'package:cms_core/module/setup/sandi_transaksi_buku/sandi_transaksi_buku_page.dart';
import 'package:cms_core/module/setup/lending/lending_setup_pages.dart';
import 'package:cms_core/module/setup/setup_inventaris/setup_inventaris_page.dart';
import 'package:cms_core/module/master/new_master/new_master_pages.dart' hide AbaPage;
import 'package:cms_core/module/master/aba/aba_page.dart';
import 'package:cms_core/module/setup/third_party/third_party_pages.dart';
import 'package:cms_core/module/master/rab/rab_page.dart';
import 'package:cms_core/utils/auto_logout_wrapper.dart';
import 'package:cms_core/utils/colors.dart';
import 'package:cms_core/utils/images_path.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MenuPage extends StatelessWidget {
  const MenuPage({super.key});

  Widget _buildPage(MenuNotifier value) {
    switch (value.page) {
      case 1:
        return const KantorPage();
      case 2:
        return const GlPage();
      case 3:
        return const UsersPage();
      case 4:
        return const LevelUserPage();
      case 5:
        return const AoPage();
      case 6:
        return const SandiPage();
      case 7:
        return const ProductTabunganPage();
      case 8:
        return const ProductDepositoPage();
      case 9:
        return const FormatBukuPage();
      case 10:
        return const FormatCoverPage();
      case 11:
        return const BilyetCategoryPage();
      case 12:
        return const SandiTransaksiBukuPage();
      case 13:
        return const AgunanPage();
      case 14:
        return const RakPage();
      case 15:
        return const RateRakPage();
      case 16:
        return const PpapPage();
      case 17:
        return const PajakAgregatPage();
      case 18:
        return const ProductKreditPage();
      case 19:
        return const SetupInventarisPage();
      case 20:
        return const AbaPage();
      case 21:
        return const MitraBisnisFormPage();
      case 22:
        return const MasterInventarisPage();
      case 23:
        return const RabMarketingPage();
      case 24:
        return const RabKantorPage();
      case 31:
        return const RabRealisasiPage(key: ValueKey('rab-marketing-realisasi'), marketing: true);
      case 32:
        return const RabRealisasiPage(key: ValueKey('rab-kantor-realisasi'), marketing: false);
      case 30:
        return const InventoryAssignmentPage();
      case 27:
        return const InventoryOperationsPage(key: ValueKey('asset-group'), screen: InventoryScreen.group);
      case 28:
        return const InventoryOperationsPage(key: ValueKey('asset-revaluation'), screen: InventoryScreen.revaluation);
      case 29:
        return const InventoryOperationsPage(key: ValueKey('asset-disposal'), screen: InventoryScreen.disposal);
      case 33:
        return const SimpleMenuPage(key: ValueKey('operating-hours'), menu: SimpleMenu.hours);
      case 34:
        return const SimpleMenuPage(key: ValueKey('holidays'), menu: SimpleMenu.holidays);
      case 25:
        return const PartyGroupPage();
      case 17:
        return const KategoriAgunanPage();
      default:
        if (value.menuItems.isEmpty) return const _NoAccessPage();
        return _buildPageByFirst(value.menuItems.first.page);
    }
  }

  Widget _buildPageByFirst(int page) {
    switch (page) {
      case 1:
        return const KantorPage();
      case 2:
        return const GlPage();
      case 3:
        return const UsersPage();
      case 4:
        return const LevelUserPage();
      case 5:
        return const AoPage();
      case 6:
        return const SandiPage();
      case 7:
        return const ProductTabunganPage();
      case 8:
        return const ProductDepositoPage();
      case 9:
        return const FormatBukuPage();
      case 10:
        return const FormatCoverPage();
      case 11:
        return const BilyetCategoryPage();
      case 12:
        return const SandiTransaksiBukuPage();
      case 13:
        return const AgunanPage();
      case 14:
        return const RakPage();
      case 15:
        return const RateRakPage();
      case 16:
        return const PpapPage();
      case 17:
        return const PajakAgregatPage();
      case 18:
        return const ProductKreditPage();
      case 19:
        return const SetupInventarisPage();
      case 20:
        return const AbaPage();
      case 21:
        return const MitraBisnisFormPage();
      case 22:
        return const MasterInventarisPage();
      case 23:
        return const RabMarketingPage();
      case 24:
        return const RabKantorPage();
      case 31:
        return const RabRealisasiPage(key: ValueKey('rab-marketing-realisasi'), marketing: true);
      case 32:
        return const RabRealisasiPage(key: ValueKey('rab-kantor-realisasi'), marketing: false);
      case 30:
        return const InventoryAssignmentPage();
      case 27:
        return const InventoryOperationsPage(key: ValueKey('asset-group'), screen: InventoryScreen.group);
      case 28:
        return const InventoryOperationsPage(key: ValueKey('asset-revaluation'), screen: InventoryScreen.revaluation);
      case 29:
        return const InventoryOperationsPage(key: ValueKey('asset-disposal'), screen: InventoryScreen.disposal);
      case 33:
        return const SimpleMenuPage(key: ValueKey('operating-hours'), menu: SimpleMenu.hours);
      case 34:
        return const SimpleMenuPage(key: ValueKey('holidays'), menu: SimpleMenu.holidays);
      case 25:
        return const PartyGroupPage();
      default:
        return const _NoAccessPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MenuNotifier(context: context),
      child: Consumer<MenuNotifier>(
        builder: (context, value, child) {
          if (value.isLoading) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }

          return AutoLogoutWrapper(
            idleDuration: value.idleDuration,
            onIdleTimeout: value.autoLogoutByIdle,
            onActivity: value.onActivity,
            child: SafeArea(
              child: Scaffold(
                body: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 300,
                      height: MediaQuery.of(context).size.height,
                      padding: const EdgeInsets.all(20),
                      decoration: const BoxDecoration(color: colorPrimary),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Image.asset(
                                ImageAssets.accounting,
                                height: 36,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'CMS Core',
                                      style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'Setup & Master CMS Core',
                                      style: TextStyle(fontSize: 12, color: Colors.white70),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Container(height: 1, color: Colors.white24),
                          const SizedBox(height: 16),
                          if (value.isSuperAdmin) ...[
                            _CmsCoreToggleCard(value: value),
                            const SizedBox(height: 16),
                          ],
                          Expanded(
                            child: value.menuItems.isEmpty
                                ? const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(16),
                                      child: Text(
                                        'Tidak ada menu yang dapat diakses.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(color: Colors.white70),
                                      ),
                                    ),
                                  )
                                : ListView(children: [MenuKantorGlWidget(value: value)]),
                          ),
                          Container(height: 1, color: Colors.white24),
                          const SizedBox(height: 12),
                          if (value.users != null)
                            Padding(
                              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    value.users?.namauser ?? '',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 13, color: Colors.white70, fontWeight: FontWeight.w600),
                                  ),
                                  if (value.isSuperAdmin)
                                    const Text(
                                      'SUPER ADMIN',
                                      style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
                                    ),
                                ],
                              ),
                            ),
                          InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () => value.confirmLogout(),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              child: Row(
                                children: [
                                  Image.asset(ImageAssets.logout, height: 24, color: Colors.white),
                                  const SizedBox(width: 16),
                                  const Text('Keluar', style: TextStyle(fontSize: 16, color: Colors.white)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Container(color: const Color(0xFFF7F9FC), child: _buildPage(value)),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CmsCoreToggleCard extends StatelessWidget {
  final MenuNotifier value;

  const _CmsCoreToggleCard({required this.value});

  @override
  Widget build(BuildContext context) {
    final active = value.cmsCoreEnabled;
    return InkWell(
      onTap: value.isCmsCoreLoading ? null : value.confirmToggleCmsCore,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: active ? Colors.green.shade700 : Colors.red.shade700,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: active ? Colors.greenAccent : Colors.redAccent, width: 1.2),
        ),
        child: Row(
          children: [
            Icon(active ? Icons.lock_open : Icons.lock, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                active ? 'CMS CORE AKTIF' : 'CMS CORE NONAKTIF',
                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
            if (value.isCmsCoreLoading)
              const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            else
              const Icon(Icons.sync_alt, color: Colors.white, size: 16),
          ],
        ),
      ),
    );
  }
}

class _NoAccessPage extends StatelessWidget {
  const _NoAccessPage();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Anda tidak memiliki akses menu. Hubungi super admin.',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }
}
