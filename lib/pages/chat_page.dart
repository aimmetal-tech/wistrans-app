import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../models/conversation.dart';
import '../style/app_theme.dart';
import '../utils/log.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _selectedModel = 'qwen-turbo-latest';
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  // 联网搜索相关状态
  bool _isWebSearchEnabled = false;
  bool _isAutoSearchEnabled = false;
  bool _isSearchPanelExpanded = false;

  @override
  void dispose() {
    Log.enter('ChatPage.dispose');
    _messageController.dispose();
    _scrollController.dispose();
    Log.i('聊天页面资源释放完成');
    super.dispose();
    Log.exit('ChatPage.dispose');
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _toggleSearchPanel() {
    setState(() {
      _isSearchPanelExpanded = !_isSearchPanelExpanded;
    });
    Log.i('Search panel ${_isSearchPanelExpanded ? 'expanded' : 'collapsed'}');
  }

  void _onWebSearchChanged(bool value) {
    setState(() {
      _isWebSearchEnabled = value;
      if (!value) {
        _isAutoSearchEnabled = false;
      }
    });
    Log.i('Search mode changed: ${value ? 'enabled' : 'disabled'}');
  }

  void _onAutoSearchChanged(bool value) {
    setState(() {
      _isAutoSearchEnabled = value;
    });
    Log.i('Search mode changed: ${value ? 'auto' : 'manual'}');
  }

  Future<void> _sendMessage() async {
    Log.enter('ChatPage._sendMessage');
    final message = _messageController.text.trim();
    if (message.isEmpty) {
      Log.d('消息为空，不发送');
      Log.exit('ChatPage._sendMessage');
      return;
    }

    final appState = context.read<AppState>();
    Log.business('用户发送消息', {
      'messageLength': message.length, 
      'model': _selectedModel,
      'webSearchEnabled': _isWebSearchEnabled,
      'autoSearchEnabled': _isAutoSearchEnabled,
    });
    
    // 如果没有当前对话，先创建一个新的
    if (appState.currentConversation == null) {
      Log.i('当前没有对话，创建新对话');
      try {
        await appState.createNewConversation();
        Log.i('新对话创建完成，开始发送消息');
      } catch (e, stackTrace) {
        Log.e('创建新对话失败', e, stackTrace);
        Log.exit('ChatPage._sendMessage');
        return;
      }
    }
    
    // 现在确保有当前对话，发送消息
    if (appState.currentConversation != null) {
      await appState.sendMessage(message, _selectedModel);
    } else {
      Log.e('创建对话后仍然没有当前对话');
    }

    _messageController.clear();
    _scrollToBottom();
    Log.exit('ChatPage._sendMessage');
  }

  void _selectConversation(Conversation conversation) {
    Log.enter('ChatPage._selectConversation');
    context.read<AppState>().selectConversation(conversation);
    Log.business('用户选择对话', {'conversationId': conversation.id, 'title': conversation.title});
    Navigator.pop(context); // 关闭抽屉
    Log.exit('ChatPage._selectConversation');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppTheme.backgroundColor,
      drawer: _buildDrawer(),
      appBar: AppBar(
        title: const Text('AI 对话'),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) async {
              if (value == 'new_chat') {
                try {
                  await context.read<AppState>().createNewConversation();
                } catch (e) {
                  Log.e('创建新对话失败', e);
                }
              } else if (value == 'clear') {
                // 清空当前对话
                context.read<AppState>().selectConversation(
                  Conversation(
                    id: '',
                    title: '',
                    model: '',
                    service: '',
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                  ),
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'new_chat',
                child: Row(
                  children: [
                    Icon(Icons.add),
                    SizedBox(width: 8),
                    Text('新建对话'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(Icons.clear_all),
                    SizedBox(width: 8),
                    Text('清空对话'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Consumer<AppState>(
        builder: (context, appState, child) {
          // 在每次重建时尝试滚动到底部
          WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
          
          if (appState.currentConversation == null) {
            return _buildWelcomeScreen();
          }

          return Column(
            children: [
              // 模型选择器
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  boxShadow: AppTheme.defaultShadow,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.smart_toy, color: AppTheme.primaryColor),
                    const SizedBox(width: 8),
                    const Text('AI 模型:'),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButton<String>(
                        value: _selectedModel,
                        isExpanded: true,
                        underline: Container(),
                        items: const [
                          DropdownMenuItem(
                            value: 'qwen-turbo-latest',
                            child: Text('Qwen Turbo'),
                          ),
                          DropdownMenuItem(
                            value: 'deepseek-chat',
                            child: Text('DeepSeek'),
                          ),
                          DropdownMenuItem(
                            value: 'gpt-4o',
                            child: Text('GPT-4o'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedModel = value;
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
              
              // 联网搜索控制面板
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  boxShadow: AppTheme.defaultShadow,
                ),
                child: Column(
                  children: [
                    // 主开关行
                    Row(
                      children: [
                        const Icon(Icons.search, color: AppTheme.primaryColor),
                        const SizedBox(width: 8),
                        const Text('联网搜索'),
                        const Spacer(),
                        Switch(
                          value: _isWebSearchEnabled,
                          onChanged: _onWebSearchChanged,
                          activeThumbColor: AppTheme.primaryColor,
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: Icon(
                            _isSearchPanelExpanded 
                                ? Icons.expand_less 
                                : Icons.expand_more,
                            color: AppTheme.textSecondaryColor,
                          ),
                          onPressed: _isWebSearchEnabled ? _toggleSearchPanel : null,
                        ),
                      ],
                    ),
                    
                    // 展开的子选项
                    if (_isWebSearchEnabled && _isSearchPanelExpanded) ...[
                      const Divider(height: 16),
                      Row(
                        children: [
                          const SizedBox(width: 32),
                          const Text('搜索模式:'),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Row(
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      Radio<bool>(
                                        value: true,
                                        groupValue: _isAutoSearchEnabled,
                                        onChanged: (value) {
                                          if (value != null) {
                                            _onAutoSearchChanged(value);
                                          }
                                        },
                                      ),
                                      const Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text('自动搜索'),
                                            Text(
                                              'AI自动决定是否搜索',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: AppTheme.textSecondaryColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Row(
                                    children: [
                                      Radio<bool>(
                                        value: false,
                                        groupValue: _isAutoSearchEnabled,
                                        onChanged: (value) {
                                          if (value != null) {
                                            _onAutoSearchChanged(value);
                                          }
                                        },
                                      ),
                                      const Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text('手动搜索'),
                                            Text(
                                              '用户手动触发搜索',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: AppTheme.textSecondaryColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              
              // 对话列表
              Expanded(
                child: appState.currentConversation!.messages.isEmpty
                    ? _buildEmptyChat()
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: appState.currentConversation!.messages.length,
                        itemBuilder: (context, index) {
                          final message = appState.currentConversation!.messages[index];
                          return MessageBubble(message: message);
                        },
                      ),
              ),
              
              // 错误提示
              if (appState.conversationError != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                                         color: AppTheme.errorColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.errorColor),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error, color: AppTheme.errorColor, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          appState.conversationError!,
                          style: TextStyle(color: AppTheme.errorColor),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 16),
                        onPressed: () => appState.clearConversationError(),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
              
              // 输入框
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  boxShadow: AppTheme.defaultShadow,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: const InputDecoration(
                          hintText: '输入您的问题...',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        maxLines: null,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) async => await _sendMessage(),
                      ),
                    ),
                    const SizedBox(width: 8),
                                         IconButton(
                       onPressed: () async => await _sendMessage(),
                       icon: const Icon(Icons.send),
                       color: AppTheme.primaryColor,
                     ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Consumer<AppState>(
        builder: (context, appState, child) {
          return Column(
            children: [
              // 抽屉头部 - 用户信息
              UserAccountsDrawerHeader(
                accountName: const Text(
                  '英语学习者',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                accountEmail: const Text(
                  'learner@example.com',
                  style: TextStyle(
                    fontSize: 14,
                  ),
                ),
                currentAccountPicture: CircleAvatar(
                  backgroundImage: const AssetImage(
                    'assets/user_demo.png',
                  ),
                  backgroundColor: AppTheme.primaryColor,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                ),
              ),
              // 新建对话按钮
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final navigator = Navigator.of(context);
                    try {
                      await context.read<AppState>().createNewConversation();
                      navigator.pop(); // 关闭抽屉
                    } catch (e) {
                      Log.e('创建新对话失败', e);
                    }
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('新建对话'),
                ),
              ),
              // 历史对话列表
              Expanded(
                child: appState.conversations.isEmpty
                    ? const Center(
                        child: Text('暂无历史对话'),
                      )
                    : ListView.builder(
                        itemCount: appState.conversations.length,
                        itemBuilder: (context, index) {
                          final conversation = appState.conversations[index];
                          final isSelected = appState.currentConversation?.id == conversation.id;
                          return ListTile(
                            title: Text(
                              conversation.title.isEmpty 
                                ? '新对话' 
                                : conversation.title,
                              style: TextStyle(
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            subtitle: Text(
                              '${conversation.messages.length} 条消息',
                              style: TextStyle(
                                color: isSelected 
                                  ? AppTheme.primaryColor 
                                  : AppTheme.textSecondaryColor,
                              ),
                            ),
                            selected: isSelected,
                            onTap: () => _selectConversation(conversation),
                            trailing: Text(
                              _formatDate(conversation.updatedAt),
                              style: TextStyle(
                                color: AppTheme.textSecondaryColor,
                                fontSize: 12,
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildWelcomeScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 80,
            color: AppTheme.textSecondaryColor,
          ),
          const SizedBox(height: 24),
          Text(
            '开始与AI对话',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),
          Text(
            '选择AI模型，开始您的学习之旅',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () async {
              try {
                await context.read<AppState>().createNewConversation();
              } catch (e) {
                Log.e('创建新对话失败', e);
              }
            },
            icon: const Icon(Icons.add),
            label: const Text('新建对话'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyChat() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: AppTheme.textSecondaryColor,
          ),
          const SizedBox(height: 16),
          Text(
            '开始对话',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            '在下方输入框中输入您的问题',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays == 0) {
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return '昨天';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}天前';
    } else {
      return '${dateTime.month}-${dateTime.day}';
    }
  }
}

class MessageBubble extends StatelessWidget {
  final Message message;

  const MessageBubble({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.primaryColor,
              child: const Icon(
                Icons.smart_toy,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isUser ? AppTheme.userBubbleColor : AppTheme.assistantBubbleColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: isUser
                      ? Text(
                          message.content,
                          style: const TextStyle(
                            color: AppTheme.userTextColor,
                            fontSize: 16,
                          ),
                        )
                      : MarkdownBody(
                          data: message.content,
                          styleSheet: MarkdownStyleSheet(
                            p: const TextStyle(
                              color: AppTheme.assistantTextColor,
                              fontSize: 16,
                            ),
                            code: TextStyle(
                              backgroundColor: AppTheme.backgroundColor,
                              color: AppTheme.textPrimaryColor,
                              fontSize: 14,
                            ),
                            codeblockDecoration: BoxDecoration(
                              color: AppTheme.backgroundColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTime(message.createdAt),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.secondaryColor,
              child: const Icon(
                Icons.person,
                color: Colors.white,
                size: 16,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}