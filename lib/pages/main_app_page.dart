import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../style/app_theme.dart';
import 'notes_page.dart';
import 'home_page.dart';
import 'chat_page.dart';
import 'profile_page.dart';

class MainAppPage extends StatefulWidget {
  const MainAppPage({super.key});

  @override
  State<MainAppPage> createState() => _MainAppPageState();
}

class _MainAppPageState extends State<MainAppPage> {
  final List<Widget> _pages = [
    const NotesPage(),
    const HomePage(),
    const ChatPage(),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        return Scaffold(
          body: IndexedStack(
            index: appState.currentIndex,
            children: _pages,
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: appState.currentIndex,
            onTap: (index) {
              appState.setCurrentIndex(index);
            },
            type: BottomNavigationBarType.fixed,
            selectedItemColor: AppTheme.primaryColor,
            unselectedItemColor: AppTheme.textSecondaryColor,
            backgroundColor: AppTheme.surfaceColor,
            elevation: 8,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.note),
                label: '笔记',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: '主页',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.chat_bubble),
                label: '对话',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: '我的',
              ),
            ],
          ),
        );
      },
    );
  }
}
