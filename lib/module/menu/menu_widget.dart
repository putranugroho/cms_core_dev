import 'package:accounting_kantor_gl_useraccess/module/menu/menu_notifier.dart';
import 'package:accounting_kantor_gl_useraccess/utils/images_path.dart';
import 'package:flutter/material.dart';

class MenuKantorGlWidget extends StatelessWidget {
  final MenuNotifier value;

  const MenuKantorGlWidget({super.key, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: value.menuItems
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _MenuItem(
                title: item.title,
                icon: _iconFor(item.icon),
                selected: value.page == item.page,
                onTap: () => value.gantimenu(item.page),
              ),
            ),
          )
          .toList(),
    );
  }

  String _iconFor(String key) {
    switch (key) {
      case 'building':
        return ImageAssets.building;
      case 'accounting':
        return ImageAssets.accounting;
      case 'group':
        return ImageAssets.group;
      case 'user':
        return ImageAssets.user;
      case 'ao':
        return ImageAssets.group;
      default:
        return ImageAssets.setting;
    }
  }
}

class _MenuItem extends StatelessWidget {
  final String title;
  final String icon;
  final bool selected;
  final VoidCallback onTap;

  const _MenuItem({
    required this.title,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Image.asset(
              icon,
              height: 26,
              color: selected ? Colors.black : Colors.white,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  color: selected ? Colors.black : Colors.white,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
