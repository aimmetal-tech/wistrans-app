import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/app_state.dart';
import 'style/app_theme.dart';
import 'pages/main_app_page.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AppState(),
      child: MaterialApp(
        title: 'Wistrans 学习助手',
        theme: AppTheme.lightTheme,
        home: const MainAppPage(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
