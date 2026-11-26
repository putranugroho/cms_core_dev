import 'package:cms_core/module/menu/menu_notifier.dart';
import 'package:cms_core/utils/images_path.dart';
import 'package:flutter/material.dart';

class MenuKantorGlWidget extends StatelessWidget {
  final MenuNotifier value;

  const MenuKantorGlWidget({super.key, required this.value});

  @override
  Widget build(BuildContext context) {
    final setup = value.menuItems.where((item) => item.section == 'SETUP').toList();
    final master = value.menuItems.where((item) => item.section == 'MASTER').toList();
    final others = value.menuItems.where((item) => item.section != 'SETUP' && item.section != 'MASTER').toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (setup.isNotEmpty) ...[
          const _SectionTitle(title: 'SETUP'),
          ..._buildGroupedItems(setup),
          const SizedBox(height: 12),
        ],
        if (master.isNotEmpty) ...[
          const _SectionTitle(title: 'MASTER'),
          ..._buildGroupedItems(master),
          const SizedBox(height: 12),
        ],
        if (others.isNotEmpty) ...[
          const _SectionTitle(title: 'LAINNYA'),
          ...others.map((item) => _BuildMenuItem(item: item, value: value)),
        ],
      ],
    );
  }

  List<Widget> _buildGroupedItems(List<CoreMenuItem> items) {
    final widgets = <Widget>[];
    final grouped = <String, List<CoreMenuItem>>{};
    final direct = <CoreMenuItem>[];

    for (final item in items) {
      final parent = item.parentTitle;
      if (parent == null || parent.trim().isEmpty) {
        direct.add(item);
      } else {
        grouped.putIfAbsent(parent, () => <CoreMenuItem>[]).add(item);
      }
    }

    for (final entry in grouped.entries) {
      widgets.add(_ParentMenuGroup(title: entry.key, children: entry.value, value: value));
    }

    widgets.addAll(direct.map((item) => _BuildMenuItem(item: item, value: value)));
    return widgets;
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: 16,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _ParentMenuGroup extends StatelessWidget {
  final String title;
  final List<CoreMenuItem> children;
  final MenuNotifier value;

  const _ParentMenuGroup({required this.title, required this.children, required this.value});

  @override
  Widget build(BuildContext context) {
    final active = children.any((item) => value.page == item.page);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: active ? Colors.white : Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: active,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          iconColor: active ? Colors.black : Colors.white,
          collapsedIconColor: Colors.white,
          leading: Image.asset(
            ImageAssets.group,
            height: 24,
            color: active ? Colors.black : Colors.white,
          ),
          title: Text(
            title,
            style: TextStyle(
              color: active ? Colors.black : Colors.white,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
          children: children
              .map(
                (item) => _BuildMenuItem(
                  item: item,
                  value: value,
                  dense: true,
                  onLightBackground: active,
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class _BuildMenuItem extends StatelessWidget {
  final CoreMenuItem item;
  final MenuNotifier value;
  final bool dense;
  final bool onLightBackground;

  const _BuildMenuItem({required this.item, required this.value, this.dense = false, this.onLightBackground = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: dense ? 4 : 8),
      child: _MenuItem(
        title: item.title,
        icon: _iconFor(item.icon),
        selected: value.page == item.page,
        dense: dense,
        onLightBackground: onLightBackground,
        onTap: () => value.gantimenu(item.page),
      ),
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
      case 'saving':
      case 'deposito':
      case 'sandi':
      default:
        return ImageAssets.setting;
    }
  }
}

class _MenuItem extends StatelessWidget {
  final String title;
  final String icon;
  final bool selected;
  final bool dense;
  final bool onLightBackground;
  final VoidCallback onTap;

  const _MenuItem({
    required this.title,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.dense = false,
    this.onLightBackground = false,
  });

  @override
  Widget build(BuildContext context) {
    final foregroundColor = selected || onLightBackground ? Colors.black87 : Colors.white;
    final iconColor = selected || onLightBackground ? Colors.black87 : Colors.white;

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: dense ? 14 : 16, vertical: dense ? 10 : 14),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Image.asset(
              icon,
              height: dense ? 20 : 24,
              color: iconColor,
            ),
            SizedBox(width: dense ? 12 : 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: dense ? 14 : 16,
                  color: foregroundColor,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
