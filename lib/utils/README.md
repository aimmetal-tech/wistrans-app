# Flutter Logger 最佳实践

本项目已实现符合最佳实践的日志系统，基于 `logger` 库进行封装。

## 📁 文件结构

```
lib/utils/
├── log.dart              # 日志工具类
├── log_example.dart      # 使用示例
└── README.md            # 本文档
```

## 🚀 快速开始

### 1. 导入日志工具

```dart
import '../utils/log.dart';
```

### 2. 基本使用

```dart
class MyService {
  Future<void> myMethod() async {
    Log.enter('MyService.myMethod');
    
    try {
      Log.i('开始执行业务逻辑');
      
      // 你的业务代码
      await someAsyncOperation();
      
      Log.business('操作完成', {'result': 'success'});
      
    } catch (e, stackTrace) {
      Log.e('操作失败', e, stackTrace);
    } finally {
      Log.exit('MyService.myMethod');
    }
  }
}
```

## 📝 日志级别

### Debug 级别 (`Log.d`)
- **仅在 debug 模式下输出**
- 用于调试信息
- 包含函数进入/退出日志

```dart
Log.d('调试信息');
Log.d('调试信息', error, stackTrace);
```

### Info 级别 (`Log.i`)
- **所有模式下都输出**
- 用于一般信息记录

```dart
Log.i('应用启动');
Log.i('用户登录成功');
```

### Warning 级别 (`Log.w`)
- 用于警告信息
- 可包含错误和堆栈跟踪

```dart
Log.w('警告信息');
Log.w('警告信息', error, stackTrace);
```

### Error 级别 (`Log.e`)
- **必须包含 error 和 stackTrace**
- 用于错误记录

```dart
Log.e('错误描述', error, stackTrace);
```

## 🎯 专用日志方法

### 网络请求日志 (`Log.network`)

```dart
// 发送请求
Log.network('POST', 'https://api.example.com/data', requestData);

// 接收响应
Log.network('POST', 'https://api.example.com/data', requestData, responseData);
```

### 业务流程日志 (`Log.business`)

```dart
Log.business('用户登录', {'userId': '12345', 'username': 'testuser'});
Log.business('订单创建', {'orderId': 'ORD001', 'amount': 99.99});
```

### 函数进入/退出日志 (`Log.enter` / `Log.exit`)

```dart
void myFunction() {
  Log.enter('MyClass.myFunction');
  
  // 函数逻辑
  
  Log.exit('MyClass.myFunction');
}
```

## 🔧 配置说明

### Debug 模式
- 彩色控制台输出
- 显示完整的调用堆栈
- 包含时间戳和 emoji

### Release 模式
- 精简信息输出
- 不显示调试日志
- 可配置写入文件（待实现）

## ❌ 禁止事项

1. **禁止使用 `print()` 函数**
   ```dart
   // ❌ 错误
   print('调试信息');
   
   // ✅ 正确
   Log.d('调试信息');
   ```

2. **禁止创建 Logger 实例**
   ```dart
   // ❌ 错误
   final logger = Logger();
   logger.d('信息');
   
   // ✅ 正确
   Log.d('信息');
   ```

3. **禁止记录敏感信息**
   ```dart
   // ❌ 错误
   Log.i('用户密码: $password');
   Log.i('API Token: $token');
   
   // ✅ 正确
   Log.i('用户登录成功');
   Log.i('API 请求完成');
   ```

4. **错误日志必须包含完整信息**
   ```dart
   // ❌ 错误
   Log.e('操作失败');
   
   // ✅ 正确
   Log.e('操作失败', error, stackTrace);
   ```

## 📋 最佳实践

### 1. 函数日志模板

```dart
Future<void> myAsyncFunction() async {
  Log.enter('MyClass.myAsyncFunction');
  
  try {
    Log.i('开始执行');
    
    // 业务逻辑
    await someOperation();
    
    Log.business('执行完成', {'result': 'success'});
    
  } catch (e, stackTrace) {
    Log.e('执行失败', e, stackTrace);
    rethrow; // 或者处理错误
  } finally {
    Log.exit('MyClass.myAsyncFunction');
  }
}
```

### 2. 网络请求日志模板

```dart
Future<Response> makeApiRequest(String url, Map<String, dynamic> data) async {
  Log.enter('ApiService.makeApiRequest');
  
  try {
    Log.network('POST', url, data);
    
    final response = await http.post(Uri.parse(url), body: data);
    
    Log.network('POST', url, data, response.body);
    Log.business('API 请求成功', {'url': url, 'statusCode': response.statusCode});
    
    return response;
    
  } catch (e, stackTrace) {
    Log.e('API 请求失败', e, stackTrace);
    rethrow;
  } finally {
    Log.exit('ApiService.makeApiRequest');
  }
}
```

### 3. 状态管理日志

```dart
class MyState extends ChangeNotifier {
  void updateState(String newValue) {
    Log.enter('MyState.updateState');
    
    _value = newValue;
    Log.business('状态更新', {'newValue': newValue});
    
    notifyListeners();
    Log.exit('MyState.updateState');
  }
}
```

## 🎨 日志输出示例

```
[2024-01-15 10:30:45.123] ➡️  Entering: ApiService.createConversation
[2024-01-15 10:30:45.124] 🌐 GET: http://localhost:8080/conversations
[2024-01-15 10:30:45.456] 🌐 GET: http://localhost:8080/conversations
📥 Response: {"id": "conv_123", "title": "新对话"}
[2024-01-15 10:30:45.457] 💼 创建会话成功 | Params: {"id": "conv_123"}
[2024-01-15 10:30:45.458] ⬅️  Exiting: ApiService.createConversation
```

## 🔍 调试技巧

1. **使用函数进入/退出日志追踪调用流程**
2. **使用业务流程日志记录关键节点**
3. **使用网络日志监控 API 请求**
4. **使用错误日志快速定位问题**

## 📚 更多示例

查看 `log_example.dart` 文件获取更多使用示例。
