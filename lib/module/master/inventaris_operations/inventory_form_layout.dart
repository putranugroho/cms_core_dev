import 'package:flutter/material.dart';

/// Inventory-only responsive fields, ordered left-to-right then top-to-bottom.
class InventoryFormGrid extends StatelessWidget {
  final List<Widget> children;
  final int maxColumns;
  const InventoryFormGrid({super.key, required this.children, this.maxColumns = 3});

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, constraints) {
    const gap = 16.0;
    final width = constraints.maxWidth;
    final columns = width >= 960 && maxColumns >= 3 ? 3 : width >= 600 && maxColumns >= 2 ? 2 : 1;
    final fieldWidth = (width - gap * (columns - 1)) / columns;
    return Wrap(spacing: gap, runSpacing: 8, children: [
      for (final child in children)
        SizedBox(width: child is InventoryFullWidth ? width : fieldWidth, child: child),
    ]);
  });
}

class InventoryFullWidth extends StatelessWidget {
  final Widget child;
  const InventoryFullWidth({super.key, required this.child});
  @override
  Widget build(BuildContext context) => child;
}
