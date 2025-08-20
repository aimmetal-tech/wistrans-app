import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/conversation.dart';
import '../models/news.dart';
import '../utils/log.dart';

class ApiService {
  static const String goBaseUrl = 'http://localhost:8080';
  static const String pythonBaseUrl = 'http://localhost:8000';

  // Go API 服务
  static Future<Map<String, dynamic>> checkHealth() async {
    Log.enter('ApiService.checkHealth');
    try {
      Log.network('GET', '$goBaseUrl/health');
      final response = await http.get(Uri.parse('$goBaseUrl/health'));
      Log.network('GET', '$goBaseUrl/health', null, response.body);
      
      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        Log.i('健康检查成功');
        Log.exit('ApiService.checkHealth');
        return result;
      } else {
        throw Exception('健康检查失败: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      Log.e('健康检查失败', e, stackTrace);
      Log.exit('ApiService.checkHealth');
      throw Exception('网络请求失败: $e');
    }
  }

  static Future<String> createConversation() async {
    Log.enter('ApiService.createConversation');
    try {
      Log.network('GET', '$goBaseUrl/conversations');
      final response = await http.get(Uri.parse('$goBaseUrl/conversations'));
      Log.network('GET', '$goBaseUrl/conversations', null, response.body);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final conversationId = data['conversation_id'] ?? data['id'] ?? '';
        Log.business('创建会话成功', {'id': conversationId});
        Log.exit('ApiService.createConversation');
        return conversationId;
      } else {
        throw Exception('创建会话失败: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      Log.e('创建会话失败', e, stackTrace);
      Log.exit('ApiService.createConversation');
      throw Exception('网络请求失败: $e');
    }
  }

  static Future<Conversation> getConversationDetail(String id) async {
    Log.enter('ApiService.getConversationDetail');
    try {
      final url = '$goBaseUrl/conversations/detail?id=$id';
      Log.network('GET', url);
      final response = await http.get(Uri.parse(url));
      Log.network('GET', url, null, response.body);
      
      if (response.statusCode == 200) {
        final conversation = Conversation.fromJson(json.decode(response.body));
        Log.business('获取会话详情成功', {'id': id});
        Log.exit('ApiService.getConversationDetail');
        return conversation;
      } else {
        throw Exception('获取会话详情失败: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      Log.e('获取会话详情失败', e, stackTrace);
      Log.exit('ApiService.getConversationDetail');
      throw Exception('网络请求失败: $e');
    }
  }

  static Future<List<Message>> getConversationHistory(String id) async {
    Log.enter('ApiService.getConversationHistory');
    try {
      final url = '$goBaseUrl/conversations/history?id=$id';
      Log.network('GET', url);
      final response = await http.get(Uri.parse(url));
      Log.network('GET', url, null, response.body);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final messages = (data['messages'] as List<dynamic>)
            .map((e) => Message.fromJson(e))
            .toList();
        Log.business('获取会话历史成功', {'id': id, 'messageCount': messages.length});
        Log.exit('ApiService.getConversationHistory');
        return messages;
      } else {
        throw Exception('获取会话历史失败: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      Log.e('获取会话历史失败', e, stackTrace);
      Log.exit('ApiService.getConversationHistory');
      throw Exception('网络请求失败: $e');
    }
  }

  static Future<void> updateConversation(String id, String title) async {
    Log.enter('ApiService.updateConversation');
    try {
      final url = '$goBaseUrl/conversations/$id';
      final body = {'title': title};
      Log.network('PATCH', url, body);
      final response = await http.patch(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );
      Log.network('PATCH', url, body, response.body);
      
      if (response.statusCode == 200) {
        Log.business('更新会话成功', {'id': id, 'title': title});
        Log.exit('ApiService.updateConversation');
      } else {
        throw Exception('更新会话失败: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      Log.e('更新会话失败', e, stackTrace);
      Log.exit('ApiService.updateConversation');
      throw Exception('网络请求失败: $e');
    }
  }

  static Stream<String> streamConversation(
    String id,
    String input,
    String model,
  ) async* {
    Log.enter('ApiService.streamConversation');
    try {
      final uri = Uri.parse('$goBaseUrl/conversations/stream')
          .replace(queryParameters: {
        'id': id,
        'input': input,
        'model': model,
      });

      Log.network('GET', uri.toString(), {'id': id, 'input': input, 'model': model});

      final request = http.Request('GET', uri);
      request.headers['Accept'] = 'text/event-stream';
      request.headers['Cache-Control'] = 'no-cache';

      final streamedResponse = await request.send();
      
      if (streamedResponse.statusCode != 200) {
        throw Exception('流式对话失败: ${streamedResponse.statusCode}');
      }

      Log.business('开始流式对话', {'id': id, 'model': model});

      String buffer = '';
      await for (final chunk in streamedResponse.stream.transform(utf8.decoder)) {
        buffer += chunk;
        
        List<String> lines = buffer.split('\n');
        buffer = lines.last; // 最后一行可能不完整，保留在buffer中
        
        for (int i = 0; i < lines.length - 1; i++) {
          String line = lines[i];
          
          if (line.startsWith('event:')) {
            // 事件类型行，当前实现中我们主要关注data事件
            // 可以扩展处理start和end事件
          } else if (line.startsWith('data:')) {
            String data = line.substring(5).trim(); // 移除"data: "前缀
            if (data.isNotEmpty) {
              try {
                final jsonData = json.decode(data);
                if (jsonData['choices'] != null && 
                    jsonData['choices'].isNotEmpty && 
                    jsonData['choices'][0]['delta'] != null &&
                    jsonData['choices'][0]['delta']['content'] != null) {
                  yield jsonData['choices'][0]['delta']['content'];
                }
              } catch (e) {
                // 忽略JSON解析错误
                Log.d('SSE数据解析错误', e);
              }
            }
          }
          // 忽略空行和其他不相关的行
        }
      }
      
      Log.business('流式对话完成', {'id': id});
      Log.exit('ApiService.streamConversation');
    } catch (e, stackTrace) {
      Log.e('流式对话失败', e, stackTrace);
      Log.exit('ApiService.streamConversation');
      throw Exception('流式对话失败: $e');
    }
  }

  static Future<News> fetchNews({
    String url = 'https://english.news.cn/',
    String contentType = 'news',
    String language = 'en',
    int maxLength = 5000,
    List<String>? extractFields,
  }) async {
    Log.enter('ApiService.fetchNews');
    try {
      final body = {
        'url': url,
        'content_type': contentType,
        'language': language,
        'max_length': maxLength,
        'extract_fields': extractFields,
      };
      Log.network('POST', '$goBaseUrl/fetch', body);
      final response = await http.post(
        Uri.parse('$goBaseUrl/fetch'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );
      Log.network('POST', '$goBaseUrl/fetch', body, response.body);
      
      if (response.statusCode == 200) {
        final news = News.fromJson(json.decode(response.body));
        Log.business('获取新闻成功', {'url': url, 'contentType': contentType});
        Log.exit('ApiService.fetchNews');
        return news;
      } else {
        throw Exception('获取新闻失败: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      Log.e('获取新闻失败', e, stackTrace);
      Log.exit('ApiService.fetchNews');
      throw Exception('网络请求失败: $e');
    }
  }

  // Python API 服务
  static Future<Map<String, dynamic>> translateText({
    required String target,
    required List<Map<String, String>> segments,
    Map<String, dynamic>? extraArgs,
  }) async {
    Log.enter('ApiService.translateText');
    try {
      final body = {
        'target': target,
        'segments': segments,
        'extra_args': extraArgs,
      };
      Log.network('POST', '$pythonBaseUrl/translate', body);
      final response = await http.post(
        Uri.parse('$pythonBaseUrl/translate'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );
      Log.network('POST', '$pythonBaseUrl/translate', body, response.body);
      
      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        Log.business('文本翻译成功', {'target': target, 'segmentsCount': segments.length});
        Log.exit('ApiService.translateText');
        return result;
      } else {
        throw Exception('翻译失败: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      Log.e('文本翻译失败', e, stackTrace);
      Log.exit('ApiService.translateText');
      throw Exception('网络请求失败: $e');
    }
  }

  static Future<Map<String, dynamic>> ocrImage(String imagePath) async {
    Log.enter('ApiService.ocrImage');
    try {
      Log.network('POST', '$pythonBaseUrl/ocr', {'imagePath': imagePath});
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$pythonBaseUrl/ocr'),
      );
      
      request.files.add(
        await http.MultipartFile.fromPath('image', imagePath),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      Log.network('POST', '$pythonBaseUrl/ocr', {'imagePath': imagePath}, response.body);
      
      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        Log.business('OCR识别成功', {'imagePath': imagePath});
        Log.exit('ApiService.ocrImage');
        return result;
      } else {
        throw Exception('OCR识别失败: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      Log.e('OCR识别失败', e, stackTrace);
      Log.exit('ApiService.ocrImage');
      throw Exception('网络请求失败: $e');
    }
  }

  static Future<Map<String, dynamic>> ocrTranslate({
    required String imagePath,
    String target = 'zh',
    String model = 'qwen-turbo-latest',
    Map<String, dynamic>? extraArgs,
  }) async {
    Log.enter('ApiService.ocrTranslate');
    try {
      final fields = {
        'target': target,
        'model': model,
        'imagePath': imagePath,
      };
      if (extraArgs != null) {
        fields['extra_args'] = json.encode(extraArgs);
      }
      Log.network('POST', '$pythonBaseUrl/translate/ocr', fields);
      
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$pythonBaseUrl/translate/ocr'),
      );
      
      request.files.add(
        await http.MultipartFile.fromPath('image', imagePath),
      );
      
      request.fields['target'] = target;
      request.fields['model'] = model;
      if (extraArgs != null) {
        request.fields['extra_args'] = json.encode(extraArgs);
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      Log.network('POST', '$pythonBaseUrl/translate/ocr', fields, response.body);
      
      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        Log.business('OCR翻译成功', {'imagePath': imagePath, 'target': target, 'model': model});
        Log.exit('ApiService.ocrTranslate');
        return result;
      } else {
        throw Exception('OCR翻译失败: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      Log.e('OCR翻译失败', e, stackTrace);
      Log.exit('ApiService.ocrTranslate');
      throw Exception('网络请求失败: $e');
    }
  }

  static Future<List<Map<String, String>>> translateWords({
    required List<Map<String, String>> words,
    String target = '中文',
    String model = 'qwen-turbo-latest',
    Map<String, dynamic>? extraArgs,
  }) async {
    Log.enter('ApiService.translateWords');
    try {
      final body = {
        'word': words,
        'target': target,
        'model': model,
        'extra_args': extraArgs,
      };
      Log.network('POST', '$pythonBaseUrl/trans-word', body);
      final response = await http.post(
        Uri.parse('$pythonBaseUrl/trans-word'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );
      Log.network('POST', '$pythonBaseUrl/trans-word', body, response.body);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final result = List<Map<String, String>>.from(data['translated_word']);
        Log.business('单词翻译成功', {'target': target, 'wordsCount': words.length});
        Log.exit('ApiService.translateWords');
        return result;
      } else {
        throw Exception('单词翻译失败: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      Log.e('单词翻译失败', e, stackTrace);
      Log.exit('ApiService.translateWords');
      throw Exception('网络请求失败: $e');
    }
  }

  static Future<List<int>?> generateTTS({
    required String text,
    Map<String, dynamic>? extraArgs,
  }) async {
    Log.enter('ApiService.textToSpeech');
    try {
      final body = {
        'full_text': text,
        'extra_args': extraArgs,
      };
      Log.network('POST', '$pythonBaseUrl/tts', body);
      final response = await http.post(
        Uri.parse('$pythonBaseUrl/tts'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );
      Log.network('POST', '$pythonBaseUrl/tts', body, '${response.bodyBytes.length} bytes');
      
      if (response.statusCode == 200) {
        Log.business('文本转语音成功', {'textLength': text.length});
        Log.exit('ApiService.textToSpeech');
        return response.bodyBytes;
      } else {
        throw Exception('文本转语音失败: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      Log.e('文本转语音失败', e, stackTrace);
      Log.exit('ApiService.textToSpeech');
      throw Exception('网络请求失败: $e');
    }
  }

  // 爬虫相关API
  static Future<Map<String, dynamic>> crawlUrl(String url, {bool enableFirecrawl = false}) async {
    Log.enter('ApiService.crawlUrl');
    try {
      final queryParams = {
        'url': url,
        if (enableFirecrawl) 'enable_firecrawl': 'true',
      };
      
      final uri = Uri.parse('$pythonBaseUrl/crawl').replace(queryParameters: queryParams);
      Log.network('POST', uri.toString());
      
      final response = await http.post(uri);
      Log.network('POST', uri.toString(), null, response.body);
      
      if (response.statusCode == 200) {
        // 检查响应内容类型，如果是HTML则直接返回HTML内容
        final contentType = response.headers['content-type'] ?? '';
        if (contentType.contains('text/html')) {
          // 返回HTML内容
          final result = {
            'url': url,
            'title': _extractTitleFromHtml(response.body),
            'content': response.body,
            'processed_content': response.body,
          };
          Log.business('爬取URL成功(HTML)', {'url': url});
          Log.exit('ApiService.crawlUrl');
          return result;
        } else {
          // 原有的JSON处理逻辑
          final result = json.decode(response.body);
          Log.business('爬取URL成功(JSON)', {'url': url});
          Log.exit('ApiService.crawlUrl');
          return result;
        }
      } else {
        throw Exception('爬取URL失败: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      Log.e('爬取URL失败', e, stackTrace);
      Log.exit('ApiService.crawlUrl');
      throw Exception('网络请求失败: $e');
    }
  }

  // 从HTML中提取标题的辅助方法
  static String _extractTitleFromHtml(String html) {
    try {
      final RegExp titleRegExp = RegExp(r'<title>(.*?)</title>', caseSensitive: false);
      final match = titleRegExp.firstMatch(html);
      return match?.group(1)?.trim() ?? '未知标题';
    } catch (e) {
      Log.e('提取HTML标题失败', e);
      return '未知标题';
    }
  }

  // 用户认证相关API
  static Future<Map<String, dynamic>> registerUser({
    required String username,
    required String password,
    required String confirmPassword,
  }) async {
    Log.enter('ApiService.registerUser');
    try {
      final body = {
        'username': username,
        'password': password,
        'confirm_password': confirmPassword,
      };
      Log.network('POST', '$pythonBaseUrl/user/register', body);
      final response = await http.post(
        Uri.parse('$pythonBaseUrl/user/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );
      Log.network('POST', '$pythonBaseUrl/user/register', body, response.body);
      
      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        Log.business('用户注册成功', {'username': username});
        Log.exit('ApiService.registerUser');
        return result;
      } else {
        throw Exception('用户注册失败: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      Log.e('用户注册失败', e, stackTrace);
      Log.exit('ApiService.registerUser');
      throw Exception('网络请求失败: $e');
    }
  }

  static Future<Map<String, dynamic>> loginUser({
    required String username,
    required String password,
  }) async {
    Log.enter('ApiService.loginUser');
    try {
      final body = {
        'username': username,
        'password': password,
      };
      Log.network('POST', '$pythonBaseUrl/user/login', body);
      final response = await http.post(
        Uri.parse('$pythonBaseUrl/user/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );
      Log.network('POST', '$pythonBaseUrl/user/login', body, response.body);
      
      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        Log.business('用户登录成功', {'username': username});
        Log.exit('ApiService.loginUser');
        return result;
      } else {
        throw Exception('用户登录失败: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      Log.e('用户登录失败', e, stackTrace);
      Log.exit('ApiService.loginUser');
      throw Exception('网络请求失败: $e');
    }
  }

  // 单词记录相关API
  static Future<Map<String, dynamic>> recordWord({
    required String userId,
    required String text,
    String targetLanguage = '中文',
    String modelName = 'qwen-turbo-latest',
  }) async {
    Log.enter('ApiService.recordWord');
    try {
      final body = {
        'user_id': userId,
        'text': text,
        'target_language': targetLanguage,
        'model_name': modelName,
      };
      Log.network('POST', '$pythonBaseUrl/word/record', body);
      final response = await http.post(
        Uri.parse('$pythonBaseUrl/word/record'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );
      Log.network('POST', '$pythonBaseUrl/word/record', body, response.body);
      
      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        Log.business('单词记录成功', {'userId': userId, 'text': text});
        Log.exit('ApiService.recordWord');
        return result;
      } else {
        throw Exception('单词记录失败: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      Log.e('单词记录失败', e, stackTrace);
      Log.exit('ApiService.recordWord');
      throw Exception('网络请求失败: $e');
    }
  }

  static Future<Map<String, dynamic>> getWordRecords({
    required String userId,
    int limit = 100,
    int offset = 0,
  }) async {
    Log.enter('ApiService.getWordRecords');
    try {
      final url = '$pythonBaseUrl/word/records/$userId?limit=$limit&offset=$offset';
      Log.network('GET', url);
      final response = await http.get(Uri.parse(url));
      Log.network('GET', url, null, response.body);
      
      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        Log.business('获取单词记录成功', {'userId': userId, 'limit': limit, 'offset': offset});
        Log.exit('ApiService.getWordRecords');
        return result;
      } else {
        throw Exception('获取单词记录失败: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      Log.e('获取单词记录失败', e, stackTrace);
      Log.exit('ApiService.getWordRecords');
      throw Exception('网络请求失败: $e');
    }
  }
}
