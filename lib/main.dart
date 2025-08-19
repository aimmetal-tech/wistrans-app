import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/app_state.dart';
import 'style/app_theme.dart';
import 'pages/main_app_page.dart';
import 'utils/log.dart';

void main() {
  Log.i('应用启动');
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    Log.enter('MyApp.build');
    final app = ChangeNotifierProvider(
      create: (context) => AppState(),
      child: MaterialApp(
        title: 'Wistrans 学习助手',
        theme: AppTheme.lightTheme,
        home: const MainAppPage(),
        debugShowCheckedModeBanner: false,
      ),
    );
    Log.exit('MyApp.build');
    return app;
  }
}
