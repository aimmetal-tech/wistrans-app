import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../style/app_theme.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('我的'),
      ),
      body: Consumer<AppState>(
        builder: (context, appState, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // 用户信息卡片
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 25,
                          backgroundColor: AppTheme.primaryColor,
                          child: Icon(
                            Icons.person,
                            size: 25,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                appState.username ?? '未登录用户',
                                style: Theme.of(context).textTheme.headlineSmall,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                appState.isLoggedIn ? '已登录' : '点击登录',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppTheme.textSecondaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // 功能菜单
                Card(
                  child: Column(
                    children: [
                      _buildMenuItem(
                        context,
                        icon: Icons.translate,
                        title: '翻译工具',
                        subtitle: '文本翻译、OCR翻译、单词翻译',
                        onTap: () {
                          // TODO: 导航到翻译工具页面
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('翻译工具功能开发中...')),
                          );
                        },
                      ),
                      const Divider(height: 1),
                      _buildMenuItem(
                        context,
                        icon: Icons.record_voice_over,
                        title: '语音合成',
                        subtitle: '文本转语音功能',
                        onTap: () {
                          // TODO: 导航到语音合成页面
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('语音合成功能开发中...')),
                          );
                        },
                      ),
                      const Divider(height: 1),
                      _buildMenuItem(
                        context,
                        icon: Icons.settings,
                        title: '应用设置',
                        subtitle: '主题、语言、通知设置',
                        onTap: () {
                          // TODO: 导航到设置页面
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('设置功能开发中...')),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // 统计信息
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '学习统计',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatItem(
                                context,
                                icon: Icons.chat_bubble,
                                title: '对话次数',
                                value: '${appState.conversations.length}',
                              ),
                            ),
                            Expanded(
                              child: _buildStatItem(
                                context,
                                icon: Icons.newspaper,
                                title: '阅读新闻',
                                value: '${appState.newsList.length}',
                              ),
                            ),
                            Expanded(
                              child: _buildStatItem(
                                context,
                                icon: Icons.note,
                                title: '笔记数量',
                                value: '0', // TODO: 从笔记页面获取数量
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // 关于信息
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '关于应用',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        _buildAboutItem(
                          context,
                          icon: Icons.info,
                          title: '版本信息',
                          subtitle: 'Wistrans Demo 1.0.0',
                        ),
                        const SizedBox(height: 12),
                        _buildAboutItem(
                          context,
                          icon: Icons.description,
                          title: '功能介绍',
                          subtitle: 'AI对话、新闻阅读、学习笔记',
                        ),
                        const SizedBox(height: 12),
                        _buildAboutItem(
                          context,
                          icon: Icons.support_agent,
                          title: '技术支持',
                          subtitle: 'Go + Python 后端服务',
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // 退出登录按钮
                if (appState.isLoggedIn)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('确认退出'),
                            content: const Text('确定要退出登录吗？'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('取消'),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  appState.logout();
                                  Navigator.of(context).pop();
                                },
                                child: const Text('确定'),
                              ),
                            ],
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.errorColor,
                        side: BorderSide(color: AppTheme.errorColor),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('退出登录'),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryColor),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.primaryColor, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildAboutItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.textSecondaryColor, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondaryColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}