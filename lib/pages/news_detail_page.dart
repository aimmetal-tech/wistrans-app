import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import '../models/news.dart';
import '../style/app_theme.dart';
import '../utils/log.dart';

class NewsDetailPage extends StatefulWidget {
  final TranslatedNews news;
  final Function(TranslatedNews)? onTranslate; // 添加翻译回调

  const NewsDetailPage({super.key, required this.news, this.onTranslate});

  @override
  State<NewsDetailPage> createState() => _NewsDetailPageState();
}

class _NewsDetailPageState extends State<NewsDetailPage> {
  bool _showOriginal = false;
  bool _isTranslating = false; // 添加翻译状态

  @override
  Widget build(BuildContext context) {
    Log.enter('NewsDetailPage.build');
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(_showOriginal || !widget.news.isTranslated ? '原文新闻' : '翻译新闻'),
        actions: [
          // 翻译按钮（仅在未翻译时显示）
          if (!widget.news.isTranslated && widget.onTranslate != null)
            IconButton(
              icon: _isTranslating 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.translate),
              onPressed: _isTranslating ? null : _translateNews,
              tooltip: '翻译',
            ),
          // 切换按钮（仅在已翻译时显示）
          if (widget.news.isTranslated)
            IconButton(
              icon: Icon(_showOriginal ? Icons.translate : Icons.article),
              onPressed: () {
                setState(() {
                  _showOriginal = !_showOriginal;
                });
              },
              tooltip: _showOriginal ? '查看翻译' : '查看原文',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 新闻标题
            Text(
              _showOriginal || !widget.news.isTranslated
                ? widget.news.originalNews.title 
                : widget.news.translatedTitle,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            
            // 新闻信息
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: AppTheme.textSecondaryColor,
                ),
                const SizedBox(width: 4),
                Text(
                  _formatDateTime(widget.news.originalNews.fetchTime),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondaryColor,
                      ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    widget.news.isTranslated 
                      ? (_showOriginal ? '原文' : '已翻译') 
                      : '原文',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // 原文标题（仅在已翻译且查看翻译时显示）
            if (widget.news.isTranslated && !_showOriginal) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  widget.news.originalNews.title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // 分割线
            const Divider(),
            const SizedBox(height: 16),
            
            // 新闻内容
            Html(
              data: _showOriginal || !widget.news.isTranslated
                ? widget.news.originalNews.content 
                : widget.news.translatedContent,
              style: {
                "body": Style(
                  padding: HtmlPaddings.zero,
                  margin: Margins.zero,
                ),
                "p": Style(
                  padding: HtmlPaddings.zero,
                  margin: Margins.zero,
                  fontSize: FontSize.large,
                ),
                "h1": Style(
                  fontWeight: FontWeight.bold,
                  fontSize: FontSize.xxLarge,
                ),
                "h2": Style(
                  fontWeight: FontWeight.bold,
                  fontSize: FontSize.xLarge,
                ),
                "h3": Style(
                  fontWeight: FontWeight.bold,
                  fontSize: FontSize.large,
                ),
                "strong": Style(
                  fontWeight: FontWeight.bold,
                ),
                "blockquote": Style(
                  color: AppTheme.textSecondaryColor,
                  fontStyle: FontStyle.italic,
                ),
              },
            ),
          ],
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

  // 翻译新闻
  Future<void> _translateNews() async {
    if (widget.onTranslate == null) return;
    
    setState(() {
      _isTranslating = true;
    });
    
    try {
      await widget.onTranslate!(widget.news);
    } finally {
      if (mounted) {
        setState(() {
          _isTranslating = false;
        });
      }
    }
  }
}