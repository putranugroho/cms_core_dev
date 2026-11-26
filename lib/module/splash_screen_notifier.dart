import 'dart:convert';

import 'package:cms_core/module/auth/login_page.dart';
import 'package:cms_core/module/menu/menu_page.dart';
import 'package:cms_core/network/network.dart';
import 'package:cms_core/pref/pref.dart';
import 'package:cms_core/repository/SetupRepository.dart';
import 'package:flutter/material.dart';

class SplashScreenNotifier extends ChangeNotifier {
  final BuildContext context;

  SplashScreenNotifier({required this.context}) {
    getProfile();
  }

  Future<void> getProfile() async {
    await Future.delayed(const Duration(seconds: 1));

    final pref = Pref();
    final sessionToken = await pref.getSessionToken();
    if (sessionToken.isEmpty) {
      _toLogin();
      return;
    }

    final expired = await pref.isSessionExpired(Pref.idleDuration);
    if (expired) {
      await pref.remove();
      _toLogin();
      return;
    }

    final value = await Setuprepository.setup(
      token,
      NetworkURL.sessionCheck(),
      jsonEncode({}),
    );

    final code = (value?['code'] ?? '').toString();
    if (code == '000') {
      final data = value['data'];
      if (data is Map) {
        await pref.updateCoreSession(Map<String, dynamic>.from(data));
      }
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const MenuPage()),
        ((route) => false),
      );
    } else {
      await pref.remove();
      _toLogin();
    }

    notifyListeners();
  }

  void _toLogin() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
      ((route) => false),
    );
  }
}
