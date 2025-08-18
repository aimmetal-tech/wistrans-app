# Wistrans 学习助手

一个专为学生设计的明亮风格学习型APP，集成了AI对话、双语新闻阅读、学习笔记等功能。

## 功能特色

### 🎯 主要功能
- **AI对话**: 支持多种大模型（Qwen、DeepSeek、GPT-4o），实现流式对话和Markdown渲染
- **双语新闻**: 自动获取新华网英文新闻并翻译为中文，提供中英双语阅读体验
- **学习笔记**: 创建、编辑、删除学习笔记，支持本地存储
- **个人中心**: 用户信息管理、学习统计、应用设置

### 🎨 界面设计
- **明亮风格**: 采用清新的蓝色主题，适合学生学习使用
- **响应式布局**: 使用弹性布局，避免UI溢出和偏移
- **现代化UI**: Material Design 3设计语言，提供优秀的用户体验

## 技术架构

### 前端技术栈
- **Flutter**: 跨平台移动应用开发框架
- **Provider**: 状态管理
- **HTTP**: 网络请求
- **Markdown**: 文本渲染
- **SharedPreferences**: 本地存储

### 后端服务
- **Go服务** (端口8080): 处理AI对话、新闻获取等核心功能
- **Python服务** (端口8000): 提供翻译、OCR、语音合成等功能

## 项目结构

```
lib/
├── main.dart                 # 应用入口
├── models/                   # 数据模型
│   ├── conversation.dart     # 对话相关模型
│   └── news.dart            # 新闻相关模型
├── pages/                   # 页面组件
│   ├── main_app_page.dart   # 主应用页面
│   ├── home_page.dart       # 主页（新闻）
│   ├── chat_page.dart       # 对话页面
│   ├── notes_page.dart      # 笔记页面
│   └── profile_page.dart    # 个人页面
├── services/                # 服务层
│   ├── api_service.dart     # API服务
│   └── app_state.dart       # 应用状态管理
├── style/                   # 样式主题
│   └── app_theme.dart       # 应用主题
└── docs/                    # API文档
    ├── Go-api.md           # Go后端API文档
    └── Python-api.md       # Python后端API文档
```

## 安装和运行

### 环境要求
- Flutter SDK 3.9.0+
- Dart SDK 3.9.0+
- Android Studio / VS Code

### 安装步骤

1. **克隆项目**
   ```bash
   git clone <repository-url>
   cd wistrans_demo01
   ```

2. **安装依赖**
   ```bash
   flutter pub get
   ```

3. **启动后端服务**
   - 启动Go服务 (端口8080)
   - 启动Python服务 (端口8000)

4. **运行应用**
   ```bash
   flutter run
   ```

## 使用说明

### 底部导航栏
- **笔记**: 创建和管理学习笔记
- **主页**: 浏览双语新闻
- **对话**: 与AI进行智能对话
- **我的**: 个人设置和统计信息

### AI对话功能
1. 点击"对话"标签页
2. 选择AI模型（Qwen Turbo、DeepSeek、GPT-4o）
3. 在输入框中输入问题
4. 支持Markdown格式的回复显示

### 新闻阅读功能
1. 点击"主页"标签页
2. 自动获取最新英文新闻
3. 显示中英双语内容
4. 下拉刷新获取更多新闻

### 笔记功能
1. 点击"笔记"标签页
2. 点击右上角"+"按钮创建笔记
3. 输入标题和内容
4. 支持删除笔记

## API接口

### Go后端接口 (localhost:8080)
- `GET /health` - 健康检查
- `GET /conversations` - 创建对话
- `GET /conversations/stream` - 流式对话
- `POST /fetch` - 获取新闻内容

### Python后端接口 (localhost:8000)
- `POST /translate` - 文本翻译
- `POST /ocr` - OCR文字识别
- `POST /trans-word` - 单词翻译
- `POST /tts` - 文本转语音

详细API文档请参考 `lib/docs/` 目录下的文档。

## 开发计划

### 已完成功能
- ✅ 基础UI框架和主题
- ✅ 底部导航栏
- ✅ AI对话界面
- ✅ 新闻阅读界面
- ✅ 笔记管理界面
- ✅ 个人中心界面
- ✅ API服务集成
- ✅ 状态管理

### 待开发功能
- 🔄 翻译工具页面
- 🔄 语音合成页面
- 🔄 设置页面
- 🔄 用户登录/注册
- 🔄 数据持久化
- 🔄 离线模式

## 贡献指南

1. Fork 项目
2. 创建功能分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 打开 Pull Request

## 许可证

本项目采用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情。

## 联系方式

如有问题或建议，请通过以下方式联系：
- 项目Issues: [GitHub Issues](https://github.com/your-repo/issues)
- 邮箱: your-email@example.com

---

**Wistrans 学习助手** - 让学习更智能、更高效！ 🚀
