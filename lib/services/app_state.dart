import 'package:flutter/foundation.dart';
import '../models/conversation.dart';
import '../models/news.dart';
import '../models/user.dart';
import '../models/word_record.dart';
import 'api_service.dart';
import '../utils/log.dart';

class AppState extends ChangeNotifier {
  // 当前选中的底部导航索引
  int _currentIndex = 1; // 默认选中主页
  int get currentIndex => _currentIndex;

  // 对话相关状态
  final List<Conversation> _conversations = [];
  Conversation? _currentConversation;
  bool _isLoadingConversation = false;
  String? _conversationError;

  List<Conversation> get conversations => _conversations;
  Conversation? get currentConversation => _currentConversation;
  bool get isLoadingConversation => _isLoadingConversation;
  String? get conversationError => _conversationError;

  // 新闻相关状态
  final List<TranslatedNews> _newsList = [];
  bool _isLoadingNews = false;
  String? _newsError;

  List<TranslatedNews> get newsList => _newsList;
  bool get isLoadingNews => _isLoadingNews;
  String? get newsError => _newsError;

  // 用户相关状态
  bool _isLoggedIn = false;
  User? _currentUser;
  bool _isLoadingAuth = false;
  String? _authError;

  bool get isLoggedIn => _isLoggedIn;
  User? get currentUser => _currentUser;
  bool get isLoadingAuth => _isLoadingAuth;
  String? get authError => _authError;

  // 单词记录相关状态
  final List<WordRecord> _wordRecords = [];
  bool _isLoadingWordRecords = false;
  String? _wordRecordsError;

  List<WordRecord> get wordRecords => _wordRecords;
  bool get isLoadingWordRecords => _isLoadingWordRecords;
  String? get wordRecordsError => _wordRecordsError;

  // 设置当前导航索引
  void setCurrentIndex(int index) {
    Log.enter('AppState.setCurrentIndex');
    _currentIndex = index;
    Log.business('切换导航页面', {'index': index});
    notifyListeners();
    Log.exit('AppState.setCurrentIndex');
  }

  // 用户认证相关方法
  Future<void> registerUser({
    required String username,
    required String password,
    required String confirmPassword,
  }) async {
    Log.enter('AppState.registerUser');
    try {
      _isLoadingAuth = true;
      _authError = null;
      notifyListeners();

      Log.i('Register request: $username');
      final result = await ApiService.registerUser(
        username: username,
        password: password,
        confirmPassword: confirmPassword,
      );

      final user = User.fromJson(result);
      _currentUser = user;
      _isLoggedIn = true;
      
      _isLoadingAuth = false;
      Log.i('Register success: ${user.id}');
      notifyListeners();
      Log.exit('AppState.registerUser');
    } catch (e, stackTrace) {
      _isLoadingAuth = false;
      _authError = e.toString();
      Log.e('Register failed', e, stackTrace);
      notifyListeners();
      Log.exit('AppState.registerUser');
    }
  }

  Future<void> loginUser({
    required String username,
    required String password,
  }) async {
    Log.enter('AppState.loginUser');
    try {
      _isLoadingAuth = true;
      _authError = null;
      notifyListeners();

      Log.i('Login request: $username');
      final result = await ApiService.loginUser(
        username: username,
        password: password,
      );

      final userData = result['user'] as Map<String, dynamic>;
      final user = User.fromJson(userData);
      _currentUser = user;
      _isLoggedIn = true;
      
      _isLoadingAuth = false;
      Log.i('Login success: ${user.id}');
      notifyListeners();
      Log.exit('AppState.loginUser');
    } catch (e, stackTrace) {
      _isLoadingAuth = false;
      _authError = e.toString();
      Log.e('Login failed', e, stackTrace);
      notifyListeners();
      Log.exit('AppState.loginUser');
    }
  }

  void logout() {
    Log.enter('AppState.logout');
    _currentUser = null;
    _isLoggedIn = false;
    _wordRecords.clear();
    Log.business('用户登出');
    notifyListeners();
    Log.exit('AppState.logout');
  }

  // 单词记录相关方法
  Future<void> loadWordRecords() async {
    Log.enter('AppState.loadWordRecords');
    if (_currentUser == null) {
      Log.w('尝试加载单词记录但用户未登录');
      Log.exit('AppState.loadWordRecords');
      return;
    }

    try {
      _isLoadingWordRecords = true;
      _wordRecordsError = null;
      notifyListeners();

      final result = await ApiService.getWordRecords(
        userId: _currentUser!.id,
        limit: 100,
        offset: 0,
      );

      final records = (result['records'] as List<dynamic>)
          .map((e) => WordRecord.fromJson(e))
          .toList();

      _wordRecords.clear();
      _wordRecords.addAll(records);
      
      _isLoadingWordRecords = false;
      Log.i('Fetched vocabulary: ${records.length}');
      notifyListeners();
      Log.exit('AppState.loadWordRecords');
    } catch (e, stackTrace) {
      _isLoadingWordRecords = false;
      _wordRecordsError = e.toString();
      Log.e('加载单词记录失败', e, stackTrace);
      notifyListeners();
      Log.exit('AppState.loadWordRecords');
    }
  }

  Future<void> recordWord({
    required String text,
    String targetLanguage = '中文',
    String modelName = 'qwen-turbo-latest',
  }) async {
    Log.enter('AppState.recordWord');
    if (_currentUser == null) {
      Log.w('尝试记录单词但用户未登录');
      Log.exit('AppState.recordWord');
      return;
    }

    try {
      await ApiService.recordWord(
        userId: _currentUser!.id,
        text: text,
        targetLanguage: targetLanguage,
        modelName: modelName,
      );

      // 重新加载单词记录
      await loadWordRecords();
      Log.exit('AppState.recordWord');
    } catch (e, stackTrace) {
      Log.e('记录单词失败', e, stackTrace);
      Log.exit('AppState.recordWord');
    }
  }

  // 对话相关方法
  Future<void> createNewConversation() async {
    Log.enter('AppState.createNewConversation');
    try {
      _isLoadingConversation = true;
      _conversationError = null;
      notifyListeners();

      final conversationId = await ApiService.createConversation();
      final conversation = await ApiService.getConversationDetail(conversationId);
      
      _conversations.insert(0, conversation);
      _currentConversation = conversation;
      
      _isLoadingConversation = false;
      Log.business('创建新对话成功', {'conversationId': conversationId});
      notifyListeners();
      Log.exit('AppState.createNewConversation');
    } catch (e, stackTrace) {
      _isLoadingConversation = false;
      _conversationError = e.toString();
      Log.e('创建新对话失败', e, stackTrace);
      notifyListeners();
      Log.exit('AppState.createNewConversation');
    }
  }

  Future<void> loadConversationHistory(String conversationId) async {
    Log.enter('AppState.loadConversationHistory');
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
      Log.business('加载对话历史成功', {'conversationId': conversationId, 'messageCount': messages.length});
      notifyListeners();
      Log.exit('AppState.loadConversationHistory');
    } catch (e, stackTrace) {
      _isLoadingConversation = false;
      _conversationError = e.toString();
      Log.e('加载对话历史失败', e, stackTrace);
      notifyListeners();
      Log.exit('AppState.loadConversationHistory');
    }
  }

  Future<void> sendMessage(String message, String model) async {
    Log.enter('AppState.sendMessage');
    if (_currentConversation == null) {
      Log.w('尝试发送消息但当前没有选中的对话');
      Log.exit('AppState.sendMessage');
      return;
    }

    try {
      Log.business('开始发送消息', {
        'conversationId': _currentConversation!.id,
        'model': model,
        'messageLength': message.length,
      });

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

      Log.business('消息发送完成', {
        'conversationId': _currentConversation!.id,
        'responseLength': fullResponse.length,
      });
      Log.exit('AppState.sendMessage');
    } catch (e, stackTrace) {
      _conversationError = e.toString();
      Log.e('发送消息失败', e, stackTrace);
      notifyListeners();
      Log.exit('AppState.sendMessage');
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
    Log.enter('AppState.selectConversation');
    _currentConversation = conversation;
    Log.business('选择对话', {'conversationId': conversation.id, 'title': conversation.title});
    notifyListeners();
    Log.exit('AppState.selectConversation');
  }

  // 新闻相关方法
  Future<void> fetchAndTranslateNews() async {
    Log.enter('AppState.fetchAndTranslateNews');
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
      Log.business('获取并翻译新闻成功', {
        'newsTitle': news.title,
        'translatedTitle': translatedTitle,
      });
      notifyListeners();
      Log.exit('AppState.fetchAndTranslateNews');
    } catch (e, stackTrace) {
      _isLoadingNews = false;
      _newsError = e.toString();
      Log.e('获取并翻译新闻失败', e, stackTrace);
      notifyListeners();
      Log.exit('AppState.fetchAndTranslateNews');
    }
  }

  // TTS相关方法
  Future<List<int>?> generateTTS(String text) async {
    Log.enter('AppState.generateTTS');
    try {
      Log.business('开始生成TTS', {'textLength': text.length});
      
      final audioBytes = await ApiService.textToSpeech(
        text: text,
        extraArgs: {'style': '新闻播报'},
      );
      
      Log.business('TTS生成成功', {'audioSize': audioBytes.length});
      Log.exit('AppState.generateTTS');
      return audioBytes;
    } catch (e, stackTrace) {
      Log.e('TTS生成失败', e, stackTrace);
      Log.exit('AppState.generateTTS');
      return null;
    }
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
