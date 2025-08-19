import 'log.dart';

/// 日志使用示例
/// 展示如何在项目中使用 Log 工具类
class LogExample {
  
  /// 示例：函数进入/退出日志
  void exampleFunction() {
    Log.enter('LogExample.exampleFunction');
    
    try {
      // 业务逻辑
      Log.i('开始执行业务逻辑');
      
      // 模拟一些操作
      final result = _processData();
      Log.business('数据处理完成', {'result': result});
      
    } catch (e, stackTrace) {
      Log.e('函数执行失败', e, stackTrace);
    } finally {
      Log.exit('LogExample.exampleFunction');
    }
  }
  
  /// 示例：网络请求日志
  Future<void> exampleNetworkRequest() async {
    Log.enter('LogExample.exampleNetworkRequest');
    
    try {
      final url = 'https://api.example.com/data';
      final data = {'key': 'value'};
      
      Log.network('POST', url, data);
      
      // 模拟网络请求
      await Future.delayed(Duration(seconds: 1));
      
      final response = {'status': 'success', 'data': 'response data'};
      Log.network('POST', url, data, response);
      
      Log.business('网络请求成功', {'url': url});
      
    } catch (e, stackTrace) {
      Log.e('网络请求失败', e, stackTrace);
    } finally {
      Log.exit('LogExample.exampleNetworkRequest');
    }
  }
  
  /// 示例：错误处理日志
  void exampleErrorHandling() {
    Log.enter('LogExample.exampleErrorHandling');
    
    try {
      // 模拟可能出错的代码
      throw Exception('这是一个示例错误');
      
    } catch (e, stackTrace) {
      // 错误日志必须包含 error 和 stackTrace
      Log.e('示例错误处理', e, stackTrace);
      
      // 可以添加警告日志
      Log.w('错误已处理，继续执行', e, stackTrace);
    } finally {
      Log.exit('LogExample.exampleErrorHandling');
    }
  }
  
  /// 示例：业务流程日志
  void exampleBusinessFlow() {
    Log.enter('LogExample.exampleBusinessFlow');
    
    // 用户登录
    Log.business('用户登录', {'userId': '12345', 'username': 'testuser'});
    
    // 数据验证
    Log.i('开始数据验证');
    final isValid = _validateData();
    Log.business('数据验证完成', {'isValid': isValid});
    
    // 业务处理
    if (isValid) {
      Log.business('开始业务处理', {'step': 'processing'});
      _processBusinessLogic();
      Log.business('业务处理完成', {'step': 'completed'});
    } else {
      Log.w('数据验证失败，跳过业务处理');
    }
    
    Log.exit('LogExample.exampleBusinessFlow');
  }
  
  /// 示例：调试日志（仅在 debug 模式输出）
  void exampleDebugLog() {
    Log.enter('LogExample.exampleDebugLog');
    
    // 这些日志只在 debug 模式下输出
    Log.d('调试信息：当前状态');
    Log.d('调试信息：变量值', {'var1': 'value1', 'var2': 42});
    
    // 函数进入/退出日志也只在 debug 模式下输出
    Log.enter('LogExample._internalFunction');
    Log.exit('LogExample._internalFunction');
    
    Log.exit('LogExample.exampleDebugLog');
  }
  
  // 私有方法示例
  String _processData() {
    Log.enter('LogExample._processData');
    Log.d('处理数据中...');
    
    // 模拟数据处理
    final result = 'processed_data';
    
    Log.exit('LogExample._processData');
    return result;
  }
  
  bool _validateData() {
    Log.enter('LogExample._validateData');
    Log.d('验证数据中...');
    
    // 模拟数据验证
    final isValid = true;
    
    Log.exit('LogExample._validateData');
    return isValid;
  }
  
  void _processBusinessLogic() {
    Log.enter('LogExample._processBusinessLogic');
    Log.i('执行业务逻辑');
    
    // 模拟业务处理
    Log.business('业务步骤1完成');
    Log.business('业务步骤2完成');
    
    Log.exit('LogExample._processBusinessLogic');
  }
}

/// 使用说明：
/// 
/// 1. 在类的顶部导入日志工具：
///    import '../utils/log.dart';
/// 
/// 2. 在函数开始处添加进入日志：
///    Log.enter('ClassName.methodName');
/// 
/// 3. 在函数结束处添加退出日志：
///    Log.exit('ClassName.methodName');
/// 
/// 4. 记录重要的业务流程：
///    Log.business('操作描述', {'参数': '值'});
/// 
/// 5. 记录网络请求：
///    Log.network('GET', url, requestData, responseData);
/// 
/// 6. 记录错误（必须包含 error 和 stackTrace）：
///    Log.e('错误描述', error, stackTrace);
/// 
/// 7. 记录警告：
///    Log.w('警告描述', error, stackTrace);
/// 
/// 8. 记录一般信息：
///    Log.i('信息描述');
/// 
/// 9. 记录调试信息（仅在 debug 模式输出）：
///    Log.d('调试信息', error, stackTrace);
/// 
/// 注意事项：
/// - 禁止使用 print() 函数
/// - 禁止在类中创建 Logger 实例
/// - 敏感信息不要记录在日志中
/// - 错误日志必须包含完整的错误信息和堆栈跟踪
