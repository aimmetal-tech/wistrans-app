import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/app_state.dart';
import 'style/app_theme.dart';
import 'pages/main_app_page.dart';
import 'pages/login_page.dart';
import 'pages/register_page.dart';
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
        initialRoute: '/',
        routes: {
          '/': (context) => const AuthWrapper(),
          '/login': (context) => const LoginPage(),
          '/register': (context) => const RegisterPage(),
          '/main': (context) => const MainAppPage(),
        },
        debugShowCheckedModeBanner: false,
      ),
    );
    Log.exit('MyApp.build');
    return app;
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    Log.enter('AuthWrapper.build');
    return Consumer<AppState>(
      builder: (context, appState, child) {
        Log.business('检查用户登录状态', {'isLoggedIn': appState.isLoggedIn});
        
        if (appState.isLoggedIn) {
          Log.business('用户已登录，跳转到主页');
          // 使用Future.delayed确保在build完成后进行导航
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushReplacementNamed('/main');
          });
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        } else {
          Log.business('用户未登录，跳转到登录页面');
          // 使用Future.delayed确保在build完成后进行导航
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushReplacementNamed('/login');
          });
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
      },
    );
  }
}
