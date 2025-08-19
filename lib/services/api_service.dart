import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/conversation.dart';
import '../models/news.dart';

class ApiService {
  static const String goBaseUrl = 'http://localhost:8080';
  static const String pythonBaseUrl = 'http://localhost:8000';

  // Go API 服务
  static Future<Map<String, dynamic>> checkHealth() async {
    try {
      final response = await http.get(Uri.parse('$goBaseUrl/health'));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('健康检查失败: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('网络请求失败: $e');
    }
  }

  static Future<String> createConversation() async {
    try {
      final response = await http.get(Uri.parse('$goBaseUrl/conversations'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['id'];
      } else {
        throw Exception('创建会话失败: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('网络请求失败: $e');
    }
  }

  static Future<Conversation> getConversationDetail(String id) async {
    try {
      final response = await http.get(
        Uri.parse('$goBaseUrl/conversations/detail?id=$id'),
      );
      if (response.statusCode == 200) {
        return Conversation.fromJson(json.decode(response.body));
      } else {
        throw Exception('获取会话详情失败: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('网络请求失败: $e');
    }
  }

  static Future<List<Message>> getConversationHistory(String id) async {
    try {
      final response = await http.get(
        Uri.parse('$goBaseUrl/conversations/history?id=$id'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['messages'] as List<dynamic>)
            .map((e) => Message.fromJson(e))
            .toList();
      } else {
        throw Exception('获取会话历史失败: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('网络请求失败: $e');
    }
  }

  static Future<void> updateConversation(String id, String title) async {
    try {
      final response = await http.patch(
        Uri.parse('$goBaseUrl/conversations/$id'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'title': title}),
      );
      if (response.statusCode != 200) {
        throw Exception('更新会话失败: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('网络请求失败: $e');
    }
  }

  static Stream<String> streamConversation(
    String id,
    String input,
    String model,
  ) async* {
    try {
      final uri = Uri.parse('$goBaseUrl/conversations/stream')
          .replace(queryParameters: {
        'id': id,
        'input': input,
        'model': model,
      });

      final request = http.Request('GET', uri);
      request.headers['Accept'] = 'text/event-stream';
      request.headers['Cache-Control'] = 'no-cache';

      final streamedResponse = await request.send();
      
      if (streamedResponse.statusCode != 200) {
        throw Exception('流式对话失败: ${streamedResponse.statusCode}');
      }

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
              }
            }
          }
          // 忽略空行和其他不相关的行
        }
      }
    } catch (e) {
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
    try {
      final response = await http.post(
        Uri.parse('$goBaseUrl/fetch'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'url': url,
          'content_type': contentType,
          'language': language,
          'max_length': maxLength,
          'extract_fields': extractFields,
        }),
      );
      if (response.statusCode == 200) {
        return News.fromJson(json.decode(response.body));
      } else {
        throw Exception('获取新闻失败: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('网络请求失败: $e');
    }
  }

  // Python API 服务
  static Future<Map<String, dynamic>> translateText({
    required String target,
    required List<Map<String, String>> segments,
    Map<String, dynamic>? extraArgs,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$pythonBaseUrl/translate'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'target': target,
          'segments': segments,
          'extra_args': extraArgs,
        }),
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('翻译失败: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('网络请求失败: $e');
    }
  }

  static Future<Map<String, dynamic>> ocrImage(String imagePath) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$pythonBaseUrl/ocr'),
      );
      
      request.files.add(
        await http.MultipartFile.fromPath('image', imagePath),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('OCR识别失败: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('网络请求失败: $e');
    }
  }

  static Future<Map<String, dynamic>> ocrTranslate({
    required String imagePath,
    String target = 'zh',
    String model = 'qwen-turbo-latest',
    Map<String, dynamic>? extraArgs,
  }) async {
    try {
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
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('OCR翻译失败: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('网络请求失败: $e');
    }
  }

  static Future<List<Map<String, String>>> translateWords({
    required List<Map<String, String>> words,
    String target = '中文',
    String model = 'qwen-turbo-latest',
    Map<String, dynamic>? extraArgs,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$pythonBaseUrl/trans-word'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'word': words,
          'target': target,
          'model': model,
          'extra_args': extraArgs,
        }),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, String>>.from(data['translated_word']);
      } else {
        throw Exception('单词翻译失败: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('网络请求失败: $e');
    }
  }

  static Future<List<int>> textToSpeech({
    required String text,
    Map<String, dynamic>? extraArgs,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$pythonBaseUrl/tts'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'full_text': text,
          'extra_args': extraArgs,
        }),
      );
      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        throw Exception('文本转语音失败: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('网络请求失败: $e');
    }
  }
}
