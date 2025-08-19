import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../models/word_record.dart';
import '../style/app_theme.dart';
import '../utils/log.dart';

class VocabularyPage extends StatefulWidget {
  const VocabularyPage({super.key});

  @override
  State<VocabularyPage> createState() => _VocabularyPageState();
}

class _VocabularyPageState extends State<VocabularyPage> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  final Map<String, bool> _flippedCards = {};
  final Map<String, bool> _masteredWords = {};

  @override
  void initState() {
    super.initState();
    Log.enter('VocabularyPage.initState');
    _loadWordRecords();
    Log.exit('VocabularyPage.initState');
  }

  @override
  void dispose() {
    Log.enter('VocabularyPage.dispose');
    _pageController.dispose();
    Log.i('生词本页面资源释放完成');
    super.dispose();
    Log.exit('VocabularyPage.dispose');
  }

  Future<void> _loadWordRecords() async {
    Log.enter('VocabularyPage._loadWordRecords');
    final appState = context.read<AppState>();
    if (appState.isLoggedIn) {
      await appState.loadWordRecords();
      Log.i('Fetched vocabulary: ${appState.wordRecords.length}');
    } else {
      Log.w('用户未登录，无法加载单词记录');
    }
    Log.exit('VocabularyPage._loadWordRecords');
  }

  void _toggleCard(String wordId) {
    setState(() {
      _flippedCards[wordId] = !(_flippedCards[wordId] ?? false);
    });
    Log.i('Card flipped for word: $wordId');
  }

  void _markAsMastered(String wordId) {
    setState(() {
      _masteredWords[wordId] = true;
    });
    Log.i('Word marked as mastered: $wordId');
    
    // 显示成功提示
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('已标记为掌握！'),
        backgroundColor: AppTheme.successColor,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _reviewAgain(String wordId) {
    setState(() {
      _masteredWords[wordId] = false;
    });
    Log.i('Word marked for review again: $wordId');
    
    // 显示提示
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('已添加到复习列表'),
        backgroundColor: AppTheme.warningColor,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    Log.enter('VocabularyPage.build');
    final app = Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('生词本'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadWordRecords,
          ),
        ],
      ),
      body: Consumer<AppState>(
        builder: (context, appState, child) {
          if (!appState.isLoggedIn) {
            return _buildLoginPrompt();
          }

          if (appState.isLoadingWordRecords) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (appState.wordRecords.isEmpty) {
            return _buildEmptyState();
          }

          final unmasteredWords = appState.wordRecords
              .where((word) => !(_masteredWords[word.id] ?? false))
              .toList();

          if (unmasteredWords.isEmpty) {
            return _buildAllMasteredState();
          }

          return Column(
            children: [
              // 进度指示器
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Text(
                      '学习进度: ${_currentIndex + 1}/${unmasteredWords.length}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const Spacer(),
                    Text(
                      '已掌握: ${_masteredWords.length}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.successColor,
                      ),
                    ),
                  ],
                ),
              ),
              
              // 单词卡片
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: _onPageChanged,
                  itemCount: unmasteredWords.length,
                  itemBuilder: (context, index) {
                    final word = unmasteredWords[index];
                    return _buildWordCard(word);
                  },
                ),
              ),
              
              // 操作按钮
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        final word = unmasteredWords[_currentIndex];
                        _reviewAgain(word.id);
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('再次复习'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.warningColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        final word = unmasteredWords[_currentIndex];
                        _markAsMastered(word.id);
                      },
                      icon: const Icon(Icons.check),
                      label: const Text('标记已掌握'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.successColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
    
    Log.exit('VocabularyPage.build');
    return app;
  }

  Widget _buildWordCard(WordRecord word) {
    final isFlipped = _flippedCards[word.id] ?? false;
    
    return Container(
      margin: const EdgeInsets.all(16),
      child: GestureDetector(
        onTap: () => _toggleCard(word.id),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(isFlipped ? 3.14159 : 0),
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              height: 400,
              padding: const EdgeInsets.all(24),
              child: isFlipped ? _buildCardBack(word) : _buildCardFront(word),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardFront(WordRecord word) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.touch_app,
          size: 48,
          color: AppTheme.primaryColor,
        ),
        const SizedBox(height: 16),
        Text(
          '点击翻转',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTheme.textSecondaryColor,
          ),
        ),
        const SizedBox(height: 32),
        Text(
          word.word,
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          '[音标]',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: AppTheme.textSecondaryColor,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.backgroundColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '来自: ${word.originalText}',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildCardBack(WordRecord word) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.translate,
          size: 48,
          color: AppTheme.secondaryColor,
        ),
        const SizedBox(height: 16),
        Text(
          '释义',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppTheme.secondaryColor,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          word.translatedText ?? '暂无翻译',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: AppTheme.textPrimaryColor,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.backgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '例句',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                word.originalText,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          '点击翻转查看单词',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.textSecondaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginPrompt() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.login,
            size: 80,
            color: AppTheme.textSecondaryColor,
          ),
          const SizedBox(height: 24),
          Text(
            '请先登录',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),
          Text(
            '登录后可以查看您的单词记录',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pushReplacementNamed('/login');
            },
            child: const Text('去登录'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.book_outlined,
            size: 80,
            color: AppTheme.textSecondaryColor,
          ),
          const SizedBox(height: 24),
          Text(
            '暂无单词记录',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),
          Text(
            '开始翻译文本，系统会自动记录生词',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAllMasteredState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.celebration,
            size: 80,
            color: AppTheme.successColor,
          ),
          const SizedBox(height: 24),
          Text(
            '恭喜！',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: AppTheme.successColor,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '您已经掌握了所有单词',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _masteredWords.clear();
              });
            },
            child: const Text('重新开始'),
          ),
        ],
      ),
    );
  }
}
