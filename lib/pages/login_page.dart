import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../utils/log.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    Log.enter('LoginPage._login');
    if (!_formKey.currentState!.validate()) {
      Log.exit('LoginPage._login');
      return;
    }

    final appState = context.read<AppState>();
    await appState.loginUser(
      username: _usernameController.text.trim(),
      password: _passwordController.text,
    );

    if (appState.isLoggedIn) {
      Log.business('登录成功，跳转到主页');
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/main');
      }
    } else if (appState.authError != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(appState.authError!),
          backgroundColor: Colors.red,
        ),
      );
    }
    Log.exit('LoginPage._login');
  }

  void _navigateToRegister() {
    Log.business('跳转到注册页面');
    Navigator.of(context).pushNamed('/register');
  }

  @override
  Widget build(BuildContext context) {
    Log.enter('LoginPage.build');
    final appState = context.watch<AppState>();
    
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final app = Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark 
                ? [Colors.grey[900]!, Colors.grey[800]!]
                : [Colors.blue[50]!, Colors.white],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo和标题
                  Icon(
                    Icons.translate,
                    size: 80,
                    color: theme.primaryColor,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Wistrans 学习助手',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '智能翻译，轻松学习',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 48),

                  // 登录表单
                  Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              '登录',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),

                            // 用户名输入框
                            TextFormField(
                              controller: _usernameController,
                              decoration: InputDecoration(
                                labelText: '用户名',
                                prefixIcon: const Icon(Icons.person),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: theme.cardColor,
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return '请输入用户名';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // 密码输入框
                            TextFormField(
                              controller: _passwordController,
                              obscureText: !_isPasswordVisible,
                              decoration: InputDecoration(
                                labelText: '密码',
                                prefixIcon: const Icon(Icons.lock),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _isPasswordVisible 
                                        ? Icons.visibility 
                                        : Icons.visibility_off,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _isPasswordVisible = !_isPasswordVisible;
                                    });
                                  },
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: theme.cardColor,
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return '请输入密码';
                                }
                                if (value.length < 6) {
                                  return '密码长度至少6位';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),

                            // 登录按钮
                            ElevatedButton(
                              onPressed: appState.isLoadingAuth ? null : _login,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: appState.isLoadingAuth
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      '登录',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                            const SizedBox(height: 16),

                            // 注册链接
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '还没有账号？',
                                  style: theme.textTheme.bodyMedium,
                                ),
                                TextButton(
                                  onPressed: _navigateToRegister,
                                  child: const Text('立即注册'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            
                            // 不登录直接进入链接
                            Center(
                              child: TextButton(
                                onPressed: _navigateToMain,
                                child: const Text('不登录，直接进入'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    
    Log.exit('LoginPage.build');
    return app;
  }
  
  // 跳转到主页
  void _navigateToMain() {
    Log.business('用户选择不登录直接进入应用');
    // 设置访客模式
    context.read<AppState>().setGuestMode();
    Navigator.of(context).pushReplacementNamed('/main');
  }
}
