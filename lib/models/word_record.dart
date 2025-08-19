class WordRecord {
  final String id;
  final String userId;
  final String word;
  final String originalText;
  final String? translatedText;
  final String targetLanguage;
  final String? modelName;
  final DateTime createdAt;

  WordRecord({
    required this.id,
    required this.userId,
    required this.word,
    required this.originalText,
    this.translatedText,
    required this.targetLanguage,
    this.modelName,
    required this.createdAt,
  });

  factory WordRecord.fromJson(Map<String, dynamic> json) {
    return WordRecord(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      word: json['word'] ?? '',
      originalText: json['original_text'] ?? '',
      translatedText: json['translated_text'],
      targetLanguage: json['target_language'] ?? '',
      modelName: json['model_name'],
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'word': word,
      'original_text': originalText,
      'translated_text': translatedText,
      'target_language': targetLanguage,
      'model_name': modelName,
      'created_at': createdAt.toIso8601String(),
    };
  }

  WordRecord copyWith({
    String? id,
    String? userId,
    String? word,
    String? originalText,
    String? translatedText,
    String? targetLanguage,
    String? modelName,
    DateTime? createdAt,
  }) {
    return WordRecord(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      word: word ?? this.word,
      originalText: originalText ?? this.originalText,
      translatedText: translatedText ?? this.translatedText,
      targetLanguage: targetLanguage ?? this.targetLanguage,
      modelName: modelName ?? this.modelName,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'WordRecord(id: $id, word: $word, targetLanguage: $targetLanguage, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WordRecord && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
