import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_state.dart';
import '../widgets/bottom_player_widget.dart';
import 'library_screen.dart';
import 'category_screen.dart';
import 'my_page.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  final List<Widget> _pages = [
    LibraryScreen(), // Filter page with categories
    CategoryScreen(), // Songs list page
    const MyPage(), // My page with settings, equalizer, about
  ];

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AppState()..loadData(),
      child: Consumer<AppState>(
        builder: (context, appState, child) {
          return Scaffold(
            body: Column(
              children: [
                // Page content
                Expanded(
                  child: _pages[_currentIndex],
                ),
                // Bottom player widget
                const BottomPlayerWidget(),
              ],
            ),
            bottomNavigationBar: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              backgroundColor: Colors.black,
              selectedItemColor: Colors.red,
              unselectedItemColor: Colors.grey,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.filter_list),
                  label: '流韵',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.music_note),
                  label: '歌曲列表',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person),
                  label: '我的',
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
