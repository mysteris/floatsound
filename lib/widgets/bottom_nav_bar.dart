import 'package:flutter/material.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  
  const BottomNavBar({super.key, required this.currentIndex, required this.onTap});
  
  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      backgroundColor: Colors.black,
      selectedItemColor: Colors.red[900],
      unselectedItemColor: Colors.grey,
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.music_note),
          label: '所有歌曲',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.folder),
          label: '文件夹',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.album),
          label: '专辑',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: '艺术家',
        ),
      ],
    );
  }
}
