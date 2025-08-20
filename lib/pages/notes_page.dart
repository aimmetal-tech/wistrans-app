import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lottie/lottie.dart';
import '../style/app_theme.dart';
import 'timeline_view.dart';

class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  final List<Note> _notes = [];
  final List<String> _categories = ['灵感记录', '待办清单', '读书笔记'];
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = '灵感记录';
  bool _isAddingNote = false;
  bool _isEditingNote = false;
  String _editingNoteId = '';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadNotes();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.trim();
    });
  }

  Future<void> _loadNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final notesString = prefs.getString('notes') ?? '[]';
    final notesJson = json.decode(notesString) as List;
    
    setState(() {
      _notes.clear();
      _notes.addAll(notesJson.map((note) => Note.fromJson(note)).toList());
    });
  }

  Future<void> _saveNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final notesJson = _notes.map((note) => note.toJson()).toList();
    final notesString = json.encode(notesJson);
    await prefs.setString('notes', notesString);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _addNote() {
    setState(() {
      _isAddingNote = true;
      _isEditingNote = false;
      _titleController.clear();
      _contentController.clear();
      _selectedCategory = '学习笔记';
    });
  }

  void _editNote(Note note) {
    setState(() {
      _isAddingNote = true;
      _isEditingNote = true;
      _editingNoteId = note.id;
      _titleController.text = note.title;
      _contentController.text = note.content;
      _selectedCategory = note.category;
    });
  }

  void _saveNote() {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    
    if (title.isNotEmpty && content.isNotEmpty) {
      setState(() {
        if (_isEditingNote) {
          // 更新现有笔记
          final index = _notes.indexWhere((note) => note.id == _editingNoteId);
          if (index != -1) {
            _notes[index] = Note(
              id: _editingNoteId,
              title: title,
              content: content,
              category: _selectedCategory,
              createdAt: _notes[index].createdAt,
              updatedAt: DateTime.now(),
            );
          }
        } else {
          // 添加新笔记
          _notes.add(Note(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            title: title,
            content: content,
            category: _selectedCategory,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ));
        }
        _isAddingNote = false;
        _isEditingNote = false;
        _titleController.clear();
        _contentController.clear();
      });
      _saveNotes(); // 保存到本地存储
    }
  }

  void _cancelAdd() {
    setState(() {
      _isAddingNote = false;
      _isEditingNote = false;
      _titleController.clear();
      _contentController.clear();
    });
  }

  void _deleteNote(String id) {
    setState(() {
      _notes.removeWhere((note) => note.id == id);
    });
    _saveNotes(); // 更新本地存储
  }

  List<Note> _filterNotes() {
    List<Note> filteredNotes = _notes;
    
    // 根据搜索查询过滤
    if (_searchQuery.isNotEmpty) {
      filteredNotes = filteredNotes.where((note) {
        return note.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               note.content.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }
    
    return filteredNotes;
  }

  @override
  Widget build(BuildContext context) {
    final filteredNotes = _filterNotes();
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          _isAddingNote || _isEditingNote ? '编辑笔记' : '我的笔记',
        ),
        actions: [
          if (!_isAddingNote && !_isEditingNote) ...[
            IconButton(
              icon: const Icon(Icons.view_timeline),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TimelineView(notes: filteredNotes),
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _startAddNewNote,
            ),
          ] else ...[
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveNote,
            ),
            IconButton(
              icon: const Icon(Icons.cancel),
              onPressed: _cancelAddOrEdit,
            ),
          ]
        ],
      ),
      body: _isAddingNote || _isEditingNote
          ? _buildNoteForm()
          : _buildNoteList(filteredNotes),
      // 添加悬浮按钮
      floatingActionButton: (!_isAddingNote && !_isEditingNote)
          ? FloatingActionButton(
              onPressed: _startAddNewNote,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
  
  Widget _buildNoteForm() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: '笔记标题',
              hintText: '输入笔记标题',
            ),
          ),
          const SizedBox(height: 16),
          
          // 分类选择
          DropdownButtonFormField<String>(
            value: _selectedCategory,
            items: _categories.map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: (String? newValue) {
              if (newValue != null) {
                setState(() {
                  _selectedCategory = newValue;
                });
              }
            },
            decoration: const InputDecoration(
              labelText: '分类',
            ),
          ),
          const SizedBox(height: 16),
          
          TextField(
            controller: _contentController,
            decoration: const InputDecoration(
              labelText: '笔记内容',
              hintText: '输入笔记内容',
            ),
            maxLines: 6,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _cancelAdd,
                  child: const Text('取消'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _saveNote,
                  child: Text(_isEditingNote ? '更新' : '保存'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildNoteList(List<Note> filteredNotes) {
    return Column(
      children: [
        // 搜索栏
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: '搜索笔记...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
              ),
            ),
          ),
        ),
        
        // 笔记列表
        Expanded(
          child: filteredNotes.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredNotes.length,
                  itemBuilder: (context, index) {
                    final note = filteredNotes[index];
                    return NoteCard(
                      note: note,
                      onEdit: () => _editNote(note),
                      onDelete: () => _deleteNote(note.id),
                    );
                  },
                ),
        ),
      ],
    );
  }
  
  void _startAddNewNote() {
    setState(() {
      _isAddingNote = true;
      _isEditingNote = false;
      _titleController.clear();
      _contentController.clear();
      // 保持当前选中的分类，而不是重置为默认值
    });
  }
  
  void _cancelAddOrEdit() {
    setState(() {
      _isAddingNote = false;
      _isEditingNote = false;
      _titleController.clear();
      _contentController.clear();
    });
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 添加Lottie动画插画
          SizedBox(
            width: 200,
            height: 200,
            child: Lottie.asset(
              'assets/empty_note.json',
              repeat: true,
              animate: true,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _searchQuery.isEmpty ? '这里还空荡荡的呢…' : '未找到匹配的笔记',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty 
                ? '记录下第一个灵感吧' 
                : '请尝试其他关键词',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          // 添加快速创建引导按钮
          if (_searchQuery.isEmpty) ...[
            const Text(
              '快速创建',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    _selectedCategory = '灵感记录';
                    _startAddNewNote();
                  },
                  icon: const Icon(Icons.lightbulb_outline, size: 18),
                  label: const Text('记录灵感'),
                ),
                const SizedBox(width: 16),
                OutlinedButton.icon(
                  onPressed: () {
                    _selectedCategory = '待办清单';
                    _startAddNewNote();
                  },
                  icon: const Icon(Icons.checklist, size: 18),
                  label: const Text('待办清单'),
                ),
                const SizedBox(width: 16),
                OutlinedButton.icon(
                  onPressed: () {
                    _selectedCategory = '读书笔记';
                    _startAddNewNote();
                  },
                  icon: const Icon(Icons.menu_book, size: 18),
                  label: const Text('读书笔记'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class Note {
  final String id;
  final String title;
  final String content;
  final String category;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Note({
    required this.id,
    required this.title,
    required this.content,
    required this.category,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'category': category,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      category: json['category'] as String? ?? '学习笔记',
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null 
          ? null 
          : DateTime.parse(json['updatedAt'] as String),
    );
  }
}

class NoteCard extends StatelessWidget {
  final Note note;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const NoteCard({
    super.key,
    required this.note,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.note,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    note.title,
                    style: Theme.of(context).textTheme.titleLarge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: onEdit,
                  color: AppTheme.primaryColor,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: onDelete,
                  color: AppTheme.errorColor,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              note.content,
              style: Theme.of(context).textTheme.bodyMedium,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
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
                    _formatDateTime(note.updatedAt ?? note.createdAt),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    note.category,
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