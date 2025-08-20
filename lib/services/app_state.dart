import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
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
  bool _isGuestMode = false; // 添加访客模式状态

  bool get isLoggedIn => _isLoggedIn;
  User? get currentUser => _currentUser;
  bool get isLoadingAuth => _isLoadingAuth;
  String? get authError => _authError;
  bool get isGuestMode => _isGuestMode; // 添加访客模式getter

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
    _isGuestMode = false; // 退出登录时关闭访客模式
    Log.business('用户登出');
    notifyListeners();
    Log.exit('AppState.logout');
  }

  // 设置访客模式
  void setGuestMode() {
    Log.enter('AppState.setGuestMode');
    _isGuestMode = true;
    _isLoggedIn = false; // 确保不是登录状态
    Log.business('设置访客模式');
    notifyListeners();
    Log.exit('AppState.setGuestMode');
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
      _newsList.clear(); // 清空现有新闻列表
      notifyListeners();

      // 首先爬取主页获取新闻链接
      final homeCrawlResult = await ApiService.crawlUrl(
        'https://english.news.cn/home.htm',
        enableFirecrawl: true,
      );

      final homeContent = homeCrawlResult['processed_content'] as String? ?? '';
      
      // 使用正则表达式提取新闻链接
      final RegExp linkRegExp = RegExp(
        r'https://english\.news\.cn/[0-9]{8}/[a-f0-9]+/c\.html',
      );
      
      final Iterable<RegExpMatch> matches = linkRegExp.allMatches(homeContent);
      final List<String> newsLinks = matches.map((m) => m.group(0)!).toList();
      
      // 去重
      final Set<String> uniqueLinks = newsLinks.toSet();
      
      // 随机选择5条链接
      final List<String> selectedLinks = uniqueLinks.toList();
      selectedLinks.shuffle();
      final List<String> randomLinks = selectedLinks.take(5).toList();
      
      // 爬取选中的新闻链接
      int fetchedCount = 0;
      for (final link in randomLinks) {
        try {
          final crawlResult = await ApiService.crawlUrl(link, enableFirecrawl: true);
          var content = crawlResult['processed_content'] as String? ?? '';
          final title = crawlResult['title'] as String? ?? '未知标题';
          
          // 预处理新闻内容，仅保留正文和网络图片
          content = await _preprocessNewsContent(content);
          
          // 创建新闻对象
          final news = News(
            url: link,
            title: title,
            content: content,
            summary: content.substring(0, content.length > 200 ? 200 : content.length),
            language: 'en',
            status: 'success',
            fetchTime: DateTime.now(),
            extractedData: {},
          );
          
          // 创建未翻译的新闻对象
          final translatedNews = TranslatedNews(
            originalNews: news,
            translatedTitle: title, // 初始时使用原标题
            translatedContent: content, // 初始时使用原内容
            translatedSummary: content.substring(0, content.length > 200 ? 200 : content.length), // 初始时使用原摘要
            isTranslated: false, // 标记为未翻译
          );
          
          // 立即添加新闻到列表并通知UI更新
          _newsList.add(translatedNews);
          fetchedCount++;
          notifyListeners();
          Log.i('已获取新闻 $fetchedCount/${randomLinks.length}: $title');
        } catch (e) {
          Log.e('处理新闻链接失败: $link', e);
          // 继续处理其他链接
        }
      }

      _isLoadingNews = false;
      Log.business('获取新闻完成', {'newsCount': _newsList.length});
      notifyListeners();
      Log.exit('AppState.fetchAndTranslateNews');
    } catch (e, stackTrace) {
      _isLoadingNews = false;
      _newsError = e.toString();
      Log.e('获取新闻失败', e, stackTrace);
      notifyListeners();
      Log.exit('AppState.fetchAndTranslateNews');
    }
  }

  // 翻译特定新闻
  Future<void> translateNews(TranslatedNews news) async {
    Log.enter('AppState.translateNews');
    try {
      // 如果已经翻译过，则不需要再次翻译
      if (news.isTranslated) {
        Log.d('新闻已翻译，无需重复翻译');
        Log.exit('AppState.translateNews');
        return;
      }

      // 提取需要翻译的文本内容（避免Markdown符号）
      final title = news.originalNews.title;
      final summary = news.originalNews.summary;
      
      // 先预处理内容，然后再进行翻译前的清理
      final preprocessedContent = await _preprocessNewsContent(news.originalNews.content);
      final content = _cleanContentForTranslation(preprocessedContent);

      // 翻译新闻内容
      final segments = [
        {'id': 'title', 'text': title},
        {'id': 'content', 'text': content},
        {'id': 'summary', 'text': summary},
      ];

      final translationResult = await ApiService.translateText(
        target: 'zh',
        segments: segments,
      );

      final translatedSegments = translationResult['segments'] as List<dynamic>;
      final translatedTitle = translatedSegments
          .firstWhere((s) => s['id'] == 'title', orElse: () => {'text': title})['text'] as String;
      final translatedContent = translatedSegments
          .firstWhere((s) => s['id'] == 'content', orElse: () => {'text': content})['text'] as String;
      final translatedSummary = translatedSegments
          .firstWhere((s) => s['id'] == 'summary', orElse: () => {'text': summary})['text'] as String;

      // 创建翻译后的新闻对象
      final translatedNews = news.copyWith(
        translatedTitle: translatedTitle,
        translatedContent: translatedContent,
        translatedSummary: translatedSummary,
        isTranslated: true,
      );

      // 更新新闻列表中的新闻
      final index = _newsList.indexOf(news);
      if (index != -1) {
        _newsList[index] = translatedNews;
        notifyListeners();
      }

      Log.business('翻译新闻成功', {'title': title});
      Log.exit('AppState.translateNews');
    } catch (e, stackTrace) {
      Log.e('翻译新闻失败', e, stackTrace);
      Log.exit('AppState.translateNews');
    }
  }

  // 清理内容用于翻译，移除Markdown符号
  String _cleanContentForTranslation(String content) {
    // 移除图片标记
    String cleanedContent = content.replaceAll(RegExp(r'!\[.*?\]\(.*?\)'), '');
    
    // 移除链接标记，但保留链接文本
    cleanedContent = cleanedContent.replaceAll(RegExp(r'\[([^\]]*)\]\([^\)]*\)'), r'$1');
    
    // 移除标题标记
    cleanedContent = cleanedContent.replaceAll(RegExp(r'^#+\s*', multiLine: true), '');
    
    // 移除表格中的分隔符
    cleanedContent = cleanedContent.replaceAll(RegExp(r'\|[-|\s]*\|', multiLine: true), '');
    
    // 移除多余的换行
    cleanedContent = cleanedContent.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    
    return cleanedContent.trim();
  }
  
  // 使用后端大模型辅助过滤新闻内容
  Future<String?> _filterContentWithLLM(String content) async {
    Log.enter('AppState._filterContentWithLLM');
    try {
      // 构建请求体
      final requestBody = {
        'model': 'qwen-turbo-latest',  // 使用通义千问模型
        'prompt': '你是一个新闻内容过滤助手。请帮我过滤以下新闻内容，只保留正文和相关图片，移除所有网站导航、目录、语言选择列表、网站图标、广告等非正文内容。保持正文的完整性和可读性。\n\n$content',
        'temperature': 0.1,  // 低温度以获得确定性输出
        'max_tokens': 4000,  // 限制输出长度
      };
      
      // 调用后端API
      final response = await http.post(
        Uri.parse('${ApiService.pythonBaseUrl}/llm/generate'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );
      
      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        final filteredContent = result['response'] as String? ?? '';
        
        // 如果过滤后的内容太短，可能是过滤出了问题，返回原内容
        if (filteredContent.length < content.length * 0.3) {
          Log.w('大模型过滤后内容太短，可能过滤过度，使用原内容');
          Log.exit('AppState._filterContentWithLLM');
          return null;
        }
        
        Log.i('大模型成功过滤内容');
        Log.exit('AppState._filterContentWithLLM');
        return filteredContent;
      } else {
        Log.w('大模型过滤请求失败: ${response.statusCode}');
        Log.exit('AppState._filterContentWithLLM');
        return null;
      }
    } catch (e, stackTrace) {
      Log.e('使用大模型过滤内容失败', e, stackTrace);
      Log.exit('AppState._filterContentWithLLM');
      return null;
    }
  }
  
  // 预处理新闻内容，仅保留正文和网络图片，过滤网站图片、SVG和清单列表等
  Future<String> _preprocessNewsContent(String content) async {
    Log.enter('AppState._preprocessNewsContent');
    try {
      // 保留正文内容
      String processedContent = content;
      
      // 移除SVG图片和图标（增强SVG检测）
      processedContent = processedContent.replaceAll(RegExp(r'<svg[\s\S]*?<\/svg>'), '');
      processedContent = processedContent.replaceAll(RegExp(r'!\[.*?\]\(.*?\.svg.*?\)'), '');
      processedContent = processedContent.replaceAll(RegExp(r'\(data:image\/svg\+xml[^\)]*\)'), '');
      
      // 移除网站图片（通常包含网站logo、图标等）- 增强关键词列表
      final websiteImageKeywords = [
        'logo', 'icon', 'banner', 'header', 'footer', 'nav', 'menu', 'button', 'sidebar',
        'avatar', 'badge', 'social', 'share', 'follow', 'subscribe', 'download', 'upload',
        'search', 'cart', 'profile', 'account', 'login', 'signup', 'register', 'notification'
      ];
      final websiteImagePattern = '!\\[.*?\\]\\(.*?(?:${websiteImageKeywords.join('|')}).*?\\)';
      processedContent = processedContent.replaceAll(RegExp(websiteImagePattern), '');
      
      // 移除清单列表（通常是网站导航或目录）- 增强检测能力
      final navigationKeywords = [
        '目录', '导航', '菜单', '索引', 'Index', 'Contents', 'Menu', 'Navigation', 'Categories',
        'Topics', 'Sections', 'Links', 'Pages', 'Site Map', '站点地图', '分类', '主题', '栏目',
        'Home', 'About', 'Contact', 'Services', 'Products', 'FAQ', 'Support', 'Help',
        'China', 'World', 'Business', 'Sports', 'Entertainment', 'Technology', 'Science',
        'Health', 'Travel', 'Opinion', 'Politics', 'Economy', 'Culture', 'Education',
        'Video', 'Photos', 'Live', 'Special', 'Reports', 'Editions', 'Regions', 'Languages'
      ];
      
      // 移除导航列表项（增强匹配模式）
      final navListPattern = r'(^|\n)[-*+•⦿⦾⦿●○•◦]\s*(' + navigationKeywords.join('|') + r').*?(?=\n\n|$)';
      processedContent = processedContent.replaceAll(RegExp(navListPattern, multiLine: true), '');
      
      // 移除整个导航列表块
      final navBlockPattern = '(^|\\n)(([-*+•⦿⦾⦿●○•◦]\\s*\\w+.*?\\n){3,})';
      processedContent = processedContent.replaceAll(RegExp(navBlockPattern, multiLine: true), '\n');
      
      // 移除网站相关的HTML标签（增强标签列表）
      processedContent = processedContent.replaceAll(
        RegExp(r'<(header|footer|nav|aside|menu|button|sidebar|widget|banner|ad|advertisement|popup|modal|dialog)>[\s\S]*?<\/\1>'), 
        ''
      );
      
      // 移除语言选择列表
      processedContent = processedContent.replaceAll(
        RegExp(r'(^|\n)([-*+•⦿⦾⦿●○•◦]\\s*(中文|English|Français|Español|Русский|Deutsch|日本語|한국어|العربية|Português).*?\n)+', multiLine: true),
        '\n'
      );
      
      // 尝试使用后端大模型辅助过滤
      try {
        final modelFilterResult = await _filterContentWithLLM(processedContent);
        if (modelFilterResult != null && modelFilterResult.isNotEmpty) {
          processedContent = modelFilterResult;
          Log.i('使用大模型过滤成功');
        }
      } catch (e) {
        Log.w('使用大模型过滤失败，使用规则过滤结果', e);
        // 如果大模型过滤失败，继续使用已处理的内容
      }
      
      // 移除多余的空行
      processedContent = processedContent.replaceAll(RegExp(r'\n{3,}'), '\n\n');
      
      Log.i('新闻内容预处理完成');
      Log.exit('AppState._preprocessNewsContent');
      return processedContent.trim();
    } catch (e, stackTrace) {
      Log.e('新闻内容预处理失败', e, stackTrace);
      Log.exit('AppState._preprocessNewsContent');
      return content; // 如果处理失败，返回原始内容
    }
  }

  // TTS相关方法
  Future<List<int>?> generateTTS(String text) async {
    Log.enter('AppState.generateTTS');
    try {
      Log.business('开始生成TTS', {'textLength': text.length});
      
      final audioBytes = await ApiService.generateTTS(
        text: text,
        extraArgs: {'style': '新闻播报'},
      );
      
      Log.business('TTS生成成功', {'audioSize': audioBytes?.length});
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
