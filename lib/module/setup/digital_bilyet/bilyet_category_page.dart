import 'package:flutter/material.dart';
import '../format_print/format_print_pages.dart' as legacy;
import 'format_bilyet_page.dart';

class BilyetCategoryPage extends StatelessWidget {
  const BilyetCategoryPage({super.key});
  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 2,
    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Material(color: Colors.white, child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Kategori Format Bilyet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          TabBar(isScrollable: true, labelColor: Theme.of(context).primaryColor,
            unselectedLabelColor: Colors.black54,
            tabs: const [Tab(icon: Icon(Icons.print_outlined), text: 'Bilyet Manual'),
              Tab(icon: Icon(Icons.description_outlined), text: 'Bilyet Digital')]),
        ]),
      )),
      const Expanded(child: TabBarView(children: [legacy.FormatBilyetPage(), DigitalBilyetPage()])),
    ]),
  );
}
