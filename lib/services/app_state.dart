import 'package:flutter/foundation.dart';
import '../models/conversation.dart';
import '../models/news.dart';
import 'api_service.dart';

class AppState extends ChangeNotifier {
  // 当前选中的底部导航索引
  int _currentIndex = 1; // 默认选中主页
  int get currentIndex => _currentIndex;

  // 对话相关状态
  List<Conversation> _conversations = [];
  Conversation? _currentConversation;
  bool _isLoadingConversation = false;
  String? _conversationError;

  List<Conversation> get conversations => _conversations;
  Conversation? get currentConversation => _currentConversation;
  bool get isLoadingConversation => _isLoadingConversation;
  String? get conversationError => _conversationError;

  // 新闻相关状态
  List<TranslatedNews> _newsList = [];
  bool _isLoadingNews = false;
  String? _newsError;

  List<TranslatedNews> get newsList => _newsList;
  bool get isLoadingNews => _isLoadingNews;
  String? get newsError => _newsError;

  // 用户相关状态
  bool _isLoggedIn = false;
  String? _username;
  String? _userId;

  bool get isLoggedIn => _isLoggedIn;
  String? get username => _username;
  String? get userId => _userId;

  // 设置当前导航索引
  void setCurrentIndex(int index) {
    _currentIndex = index;
    notifyListeners();
  }

  // 对话相关方法
  Future<void> createNewConversation() async {
    try {
      _isLoadingConversation = true;
      _conversationError = null;
      notifyListeners();

      final conversationId = await ApiService.createConversation();
      final conversation = await ApiService.getConversationDetail(conversationId);
      
      _conversations.insert(0, conversation);
      _currentConversation = conversation;
      
      _isLoadingConversation = false;
      notifyListeners();
    } catch (e) {
      _isLoadingConversation = false;
      _conversationError = e.toString();
      notifyListeners();
    }
  }

  Future<void> loadConversationHistory(String conversationId) async {
    try {
      _isLoadingConversation = true;
      _conversationError = null;
      notifyListeners();

      final messages = await ApiService.getConversationHistory(conversationId);
      final conversation = _conversations.firstWhere(
        (c) => c.id == conversationId,
        orElse: () => Conversation(
          id: conversationId,
          title: '新对话',
          model: 'qwen-turbo-latest',
          service: 'Qwen',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      final updatedConversation = conversation.copyWith(messages: messages);
      
      final index = _conversations.indexWhere((c) => c.id == conversationId);
      if (index != -1) {
        _conversations[index] = updatedConversation;
      } else {
        _conversations.insert(0, updatedConversation);
      }
      
      _currentConversation = updatedConversation;
      _isLoadingConversation = false;
      notifyListeners();
    } catch (e) {
      _isLoadingConversation = false;
      _conversationError = e.toString();
      notifyListeners();
    }
  }

  Future<void> sendMessage(String message, String model) async {
    if (_currentConversation == null) return;

    try {
      // 添加用户消息
      final userMessage = Message(
        id: _currentConversation!.messages.length + 1,
        conversationId: _currentConversation!.id,
        role: 'user',
        content: message,
        createdAt: DateTime.now(),
      );

      final updatedMessages = [..._currentConversation!.messages, userMessage];
      final updatedConversation = _currentConversation!.copyWith(
        messages: updatedMessages,
        updatedAt: DateTime.now(),
      );

      _currentConversation = updatedConversation;
      _updateConversationInList(updatedConversation);
      notifyListeners();

      // 创建助手消息
      final assistantMessage = Message(
        id: updatedMessages.length + 1,
        conversationId: _currentConversation!.id,
        role: 'assistant',
        content: '',
        createdAt: DateTime.now(),
      );

      final messagesWithAssistant = [...updatedMessages, assistantMessage];
      final conversationWithAssistant = updatedConversation.copyWith(
        messages: messagesWithAssistant,
      );

      _currentConversation = conversationWithAssistant;
      _updateConversationInList(conversationWithAssistant);
      notifyListeners();

      // 流式接收AI回复
      String fullResponse = '';
      await for (final chunk in ApiService.streamConversation(
        _currentConversation!.id,
        message,
        model,
      )) {
        fullResponse += chunk;
        
        final updatedAssistantMessage = assistantMessage.copyWith(
          content: fullResponse,
        );
        
        final finalMessages = [...updatedMessages, updatedAssistantMessage];
        final finalConversation = updatedConversation.copyWith(
          messages: finalMessages,
          updatedAt: DateTime.now(),
        );

        _currentConversation = finalConversation;
        _updateConversationInList(finalConversation);
        notifyListeners();
      }
    } catch (e) {
      _conversationError = e.toString();
      notifyListeners();
    }
  }

  void _updateConversationInList(Conversation conversation) {
    final index = _conversations.indexWhere((c) => c.id == conversation.id);
    if (index != -1) {
      _conversations[index] = conversation;
    } else {
      _conversations.insert(0, conversation);
    }
  }

  void selectConversation(Conversation conversation) {
    _currentConversation = conversation;
    notifyListeners();
  }

  // 新闻相关方法
  Future<void> fetchAndTranslateNews() async {
    try {
      _isLoadingNews = true;
      _newsError = null;
      notifyListeners();

      final news = await ApiService.fetchNews();
      
      // 翻译新闻内容
      final segments = [
        {'id': 'title', 'text': news.title},
        {'id': 'content', 'text': news.content},
        {'id': 'summary', 'text': news.summary},
      ];

      final translationResult = await ApiService.translateText(
        target: 'zh',
        segments: segments,
      );

      final translatedSegments = translationResult['segments'] as List<dynamic>;
      final translatedTitle = translatedSegments
          .firstWhere((s) => s['id'] == 'title')['text'] as String;
      final translatedContent = translatedSegments
          .firstWhere((s) => s['id'] == 'content')['text'] as String;
      final translatedSummary = translatedSegments
          .firstWhere((s) => s['id'] == 'summary')['text'] as String;

      final translatedNews = TranslatedNews(
        originalNews: news,
        translatedTitle: translatedTitle,
        translatedContent: translatedContent,
        translatedSummary: translatedSummary,
      );

      _newsList.insert(0, translatedNews);
      _isLoadingNews = false;
      notifyListeners();
    } catch (e) {
      _isLoadingNews = false;
      _newsError = e.toString();
      notifyListeners();
    }
  }

  // 用户相关方法
  void setUserInfo(String username, String userId) {
    _username = username;
    _userId = userId;
    _isLoggedIn = true;
    notifyListeners();
  }

  void logout() {
    _username = null;
    _userId = null;
    _isLoggedIn = false;
    notifyListeners();
  }

  // 清除错误信息
  void clearConversationError() {
    _conversationError = null;
    notifyListeners();
  }

  void clearNewsError() {
    _newsError = null;
    notifyListeners();
  }
}
