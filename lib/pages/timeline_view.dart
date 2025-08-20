import 'package:flutter/material.dart';
import '../style/app_theme.dart';
import 'notes_page.dart';

class TimelineView extends StatefulWidget {
  final List<Note> notes;
  
  const TimelineView({super.key, required this.notes});

  @override
  State<TimelineView> createState() => _TimelineViewState();
}

class _TimelineViewState extends State<TimelineView> with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // 按年月分组笔记
  Map<String, List<Note>> _groupNotesByMonthYear(List<Note> notes) {
    final Map<String, List<Note>> groupedMap = {};
    
    for (final note in notes) {
      // 生成分组的key，格式: "2023-08" (用于排序)
      final year = note.createdAt.year;
      final month = note.createdAt.month.toString().padLeft(2, '0');
      final key = '$year-$month';
      
      if (groupedMap.containsKey(key)) {
        groupedMap[key]!.add(note);
      } else {
        groupedMap[key] = [note];
      }
    }
    
    return groupedMap;
  }

  // 获取格式化的月份显示文本
  String _formatMonthYear(String monthKey) {
    final parts = monthKey.split('-');
    return '${parts[0]}年${int.parse(parts[1])}月';
  }

  // 构建单个悬浮标题
  Widget _buildStickyHeader(String monthKey) {
    final displayTitle = _formatMonthYear(monthKey);
    
    return Container(
      height: 40, // 标题高度
      color: AppTheme.primaryColor.withOpacity(0.9),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.centerLeft,
      child: Text(
        displayTitle,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 1. 分组数据
    final groupedNotes = _groupNotesByMonthYear(widget.notes);
    
    // 2. 获取排序后的月份key（从新到旧）
    final sortedMonthKeys = groupedNotes.keys.toList()
      ..sort((a, b) => b.compareTo(a)); // 倒序排序

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: FadeTransition(
        opacity: _animation,
        child: CustomScrollView(
          slivers: <Widget>[
            // 主AppBar
            SliverAppBar(
              pinned: true,
              title: const Text('时光轴'),
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              actions: [
                // 添加视图切换按钮
                IconButton(
                  icon: const Icon(Icons.list),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ],
            ),

            // 3. 循环构建每个月份的分组
            for (final monthKey in sortedMonthKeys) ...[
              // 悬浮标题 - 使用SliverPersistentHeader
              SliverPersistentHeader(
                pinned: true, // 设置为true使其在滚动时保持悬浮
                delegate: _StickyHeaderDelegate(
                  child: _buildStickyHeader(monthKey),
                ),
              ),

              // 该月份的笔记列表
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final note = groupedNotes[monthKey]![index];
                    return Padding(
                      padding: EdgeInsets.only(
                        left: 8.0,
                        right: 16.0,
                        bottom: index == groupedNotes[monthKey]!.length - 1 ? 24.0 : 0,
                      ),
                      child: TimelineTile(
                        note: note,
                        isFirst: index == 0,
                        isLast: index == groupedNotes[monthKey]!.length - 1,
                        onDelete: () {
                          // 这里应该调用删除笔记的逻辑
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('笔记已删除')),
                          );
                        },
                      ),
                    );
                  },
                  childCount: groupedNotes[monthKey]!.length,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// SliverPersistentHeader的delegate实现
class _StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _StickyHeaderDelegate({required this.child});

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  double get maxExtent => 40; // 标题的最大高度

  @override
  double get minExtent => 40; // 标题的最小高度（与maxExtent相同使其高度固定）

  @override
  bool shouldRebuild(covariant _StickyHeaderDelegate oldDelegate) {
    return oldDelegate.child != child;
  }
}

class TimelineTile extends StatefulWidget {
  final Note note;
  final bool isFirst;
  final bool isLast;
  final VoidCallback onDelete;

  const TimelineTile({
    super.key,
    required this.note,
    required this.isFirst,
    required this.isLast,
    required this.onDelete,
  });

  @override
  State<TimelineTile> createState() => _TimelineTileState();
}

class _TimelineTileState extends State<TimelineTile> with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  IconData _getIconForCategory(String category) {
    switch (category) {
      case '待办事项':
        return Icons.checklist;
      case '灵感记录':
        return Icons.lightbulb_outline;
      default:
        return Icons.menu_book;
    }
  }

  Color _getColorForCategory(String category) {
    switch (category) {
      case '待办事项':
        return Colors.green;
      case '灵感记录':
        return Colors.orange;
      default:
        return AppTheme.primaryColor;
    }
  }

  void _showQuickActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('编辑'),
                onTap: () {
                  Navigator.pop(context);
                  // 这里应该导航到编辑页面
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('删除'),
                onTap: () {
                  Navigator.pop(context);
                  widget.onDelete();
                },
              ),
              ListTile(
                leading: const Icon(Icons.push_pin_outlined),
                title: const Text('置顶'),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 22.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 中央时间轴
          SizedBox(
            width: 30,
            child: Column(
              children: [
                // 上半部分连接线（如果不是第一个）
                if (!widget.isFirst)
                  Container(
                    width: 2,
                    height: 20,
                    color: AppTheme.borderColor,
                  ),
                // 中心节点图标
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: _getColorForCategory(widget.note.category),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: _getColorForCategory(widget.note.category).withValues(alpha: 0.5),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    _getIconForCategory(widget.note.category),
                    size: 12,
                    color: Colors.white,
                  ),
                ),
                // 下半部分连接线（如果不是最后一个）
                if (!widget.isLast)
                  Container(
                    width: 2,
                    height: 20,
                    color: AppTheme.borderColor,
                  ),
              ],
            ),
          ),
          
          const SizedBox(width: 16),
          
          // 右侧卡片内容
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: Dismissible(
                key: Key(widget.note.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: AppTheme.errorColor,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (direction) {
                  widget.onDelete();
                },
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: GestureDetector(
                    onTap: () {
                      _scaleController.forward().then((_) {
                        _scaleController.reverse();
                      });
                    },
                    onLongPress: () => _showQuickActions(context),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceColor,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 标题行
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  widget.note.title.isEmpty ? '无标题' : widget.note.title,
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    height: 1.3,
                                  ),
                                ),
                              ),
                              // 分类标签
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _getColorForCategory(widget.note.category).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  widget.note.category,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: _getColorForCategory(widget.note.category),
                                    fontWeight: FontWeight.w500,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // 内容预览
                          Text(
                            widget.note.content.isEmpty 
                                ? (widget.note.category == '待办事项' 
                                    ? '点击添加待办事项' 
                                    : '(无内容)')
                                : widget.note.content,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: widget.note.content.isEmpty 
                                  ? AppTheme.textSecondaryColor.withValues(alpha: 0.6) 
                                  : AppTheme.textSecondaryColor,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                          // 时间戳
                          Text(
                            _formatDateTime(widget.note.updatedAt ?? widget.note.createdAt),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textSecondaryColor,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
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