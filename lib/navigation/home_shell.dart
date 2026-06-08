import 'package:flutter/material.dart';
import '../screens/tabs/play_tab.dart';
import '../screens/tabs/shop_tab.dart';
import '../screens/tabs/strikers_tab.dart';
import '../screens/tabs/profile_tab.dart';

class HomeShell extends StatefulWidget {
  /// Index of the tab to open on first build (0 = Play).
  final int initialIndex;

  const HomeShell({super.key, this.initialIndex = 0});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  late int _index = widget.initialIndex;

  static const _tabs = [PlayTab(), ShopTab(), StrikersTab(), ProfileTab()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _tabs),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.sports_esports), label: 'Play'),
          BottomNavigationBarItem(
              icon: Icon(Icons.shopping_bag), label: 'Shop'),
          BottomNavigationBarItem(
              icon: Icon(Icons.adjust), label: 'Strikers'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
