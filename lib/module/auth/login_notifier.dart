import 'dart:convert';

import 'package:cms_core/module/menu/menu_page.dart';
import 'package:cms_core/pref/pref.dart';
import 'package:cms_core/repository/SetupRepository.dart';
import 'package:cms_core/utils/dialog_loading.dart';
import 'package:cms_core/utils/informationdialog.dart';
import 'package:flutter/material.dart';

import '../../network/network.dart';

class LoginNotifier extends ChangeNotifier {
  final BuildContext context;

  LoginNotifier({required this.context});

  TextEditingController username = TextEditingController();
  TextEditingController password = TextEditingController();
  final keyForm = GlobalKey<FormState>();
  bool obscure = true;

  void gantiObscure() {
    obscure = !obscure;
    notifyListeners();
  }

  Future<void> cek() async {
    if (!(keyForm.currentState?.validate() ?? false)) return;

    DialogCustom().showLoading(context);
    final deviceId = await Pref().getOrCreateDeviceId();
    final data = {
      "userid": username.text.trim(),
      "password": password.text.trim(),
      "device_id": deviceId,
    };

    final value = await Setuprepository.setup(
      token,
      NetworkURL.authLogin(),
      jsonEncode(data),
    );
    Navigator.pop(context);

    final code = (value?['code'] ?? '').toString();
    final status = (value?['status'] ?? '').toString().toLowerCase();
    if (code == '000' || status.contains('success')) {
      final responseData = value['data'];
      if (responseData is Map) {
        await Pref().simpanCoreLogin(Map<String, dynamic>.from(responseData));
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const MenuPage()),
          (route) => false,
        );
      } else {
        informationDialog(context, "Warning", "Response login tidak valid");
      }
    } else {
      informationDialog(context, "Warning", value?['message']?.toString() ?? 'Login gagal');
    }
  }
}
