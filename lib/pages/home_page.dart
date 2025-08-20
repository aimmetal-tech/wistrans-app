import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:typed_data';
import '../services/app_state.dart';
import '../models/news.dart';
import '../style/app_theme.dart';
import '../utils/log.dart';
import 'news_detail_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final Map<String, bool> _playingStates = {};

  @override
  void initState() {
    Log.enter('HomePage.initState');
    super.initState();
    // 页面加载时获取新闻
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Log.i('主页初始化完成，开始获取新闻');
      context.read<AppState>().fetchAndTranslateNews();
    });
    Log.exit('HomePage.initState');
  }

  @override
  void dispose() {
    Log.enter('HomePage.dispose');
    _audioPlayer.dispose();
    Log.i('主页资源释放完成');
    super.dispose();
    Log.exit('HomePage.dispose');
  }

  Future<void> _playTTS(String newsId, String title) async {
    Log.enter('HomePage._playTTS');
    try {
      setState(() {
        _playingStates[newsId] = true;
      });

      Log.i('Playing TTS for article: $title');
      
      // 调用TTS API生成音频
      final audioBytes = await context.read<AppState>().generateTTS(title);
      
      if (audioBytes != null) {
        // 播放音频
        await _audioPlayer.play(BytesSource(Uint8List.fromList(audioBytes)));
        
        // 监听播放完成
        _audioPlayer.onPlayerComplete.listen((_) {
          setState(() {
            _playingStates[newsId] = false;
          });
          Log.i('TTS playback completed for: $title');
        });
      } else {
        setState(() {
          _playingStates[newsId] = false;
        });
        Log.w('TTS generation failed for: $title');
      }
    } catch (e, stackTrace) {
      setState(() {
        _playingStates[newsId] = false;
      });
      Log.e('TTS playback failed', e, stackTrace);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('播放失败: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
    Log.exit('HomePage._playTTS');
  }

  void _stopTTS() async {
    Log.enter('HomePage._stopTTS');
    try {
      await _audioPlayer.stop();
      setState(() {
        _playingStates.clear();
      });
      Log.i('TTS playback stopped');
    } catch (e, stackTrace) {
      Log.e('Failed to stop TTS', e, stackTrace);
    }
    Log.exit('HomePage._stopTTS');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Wistrans 学习助手'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<AppState>().fetchAndTranslateNews();
            },
          ),
        ],
      ),
      body: Consumer<AppState>(
        builder: (context, appState, child) {
          if (appState.isLoadingNews) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('正在获取最新新闻...'),
                ],
              ),
            );
          }

          if (appState.newsError != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: AppTheme.errorColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '获取新闻失败',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    appState.newsError!,
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      appState.clearNewsError();
                      appState.fetchAndTranslateNews();
                    },
                    child: const Text('重试'),
                  ),
                ],
              ),
            );
          }

          if (appState.newsList.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.newspaper,
                    size: 64,
                    color: AppTheme.textSecondaryColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '暂无新闻',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '点击刷新按钮获取最新新闻',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              await appState.fetchAndTranslateNews();
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: appState.newsList.length,
              itemBuilder: (context, index) {
                final news = appState.newsList[index];
                return NewsCard(
                  news: news,
                  onPlayTTS: _playTTS,
                  onStopTTS: _stopTTS,
                  isPlaying: _playingStates[news.originalNews.url] ?? false,
                  onTranslate: (news) => context.read<AppState>().translateNews(news), // 传递翻译回调
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class NewsCard extends StatelessWidget {
  final TranslatedNews news;
  final Function(String, String) onPlayTTS;
  final VoidCallback onStopTTS;
  final bool isPlaying;
  final Function(TranslatedNews) onTranslate; // 添加翻译回调

  const NewsCard({
    super.key,
    required this.news,
    required this.onPlayTTS,
    required this.onStopTTS,
    required this.isPlaying,
    required this.onTranslate, // 添加翻译回调参数
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          // 跳转到新闻详情页面
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NewsDetailPage(news: news, onTranslate: onTranslate),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // 标题部分
              Row(
                children: [
                  Icon(
                    Icons.newspaper,
                    color: AppTheme.primaryColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      news.isTranslated ? news.translatedTitle : news.originalNews.title,
                      style: Theme.of(context).textTheme.titleLarge,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // 翻译按钮
                  if (!news.isTranslated)
                    IconButton(
                      onPressed: () => onTranslate(news),
                      icon: const Icon(Icons.translate),
                      color: AppTheme.primaryColor,
                      tooltip: '翻译',
                    ),
                  // TTS播放按钮
                  IconButton(
                    onPressed: () {
                      if (isPlaying) {
                        onStopTTS();
                      } else {
                        onPlayTTS(
                          news.originalNews.url, 
                          news.isTranslated ? news.translatedTitle : news.originalNews.title
                        );
                      }
                    },
                    icon: Icon(
                      isPlaying ? Icons.stop : Icons.play_arrow,
                      color: isPlaying ? AppTheme.errorColor : AppTheme.primaryColor,
                    ),
                    tooltip: isPlaying ? '停止播放' : '播放朗读',
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // 底部信息
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: AppTheme.textSecondaryColor,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      _formatDateTime(news.originalNews.fetchTime),
                      style: Theme.of(context).textTheme.bodySmall,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  if (isPlaying) ...[                    
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.errorColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.volume_up,
                            size: 12,
                            color: AppTheme.errorColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '播放中',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.errorColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      news.isTranslated ? '已翻译' : '原文',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}天前';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}小时前';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}分钟前';
    } else {
      return '刚刚';
    }
  }
}
