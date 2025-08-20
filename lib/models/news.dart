class News {
  final String url;
  final String title;
  final String content;
  final String summary;
  final String language;
  final String status;
  final DateTime fetchTime;
  final Map<String, dynamic> extractedData;

  News({
    required this.url,
    required this.title,
    required this.content,
    required this.summary,
    required this.language,
    required this.status,
    required this.fetchTime,
    required this.extractedData,
  });

  factory News.fromJson(Map<String, dynamic> json) {
    return News(
      url: json['url'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      summary: json['summary'] ?? '',
      language: json['language'] ?? '',
      status: json['status'] ?? '',
      fetchTime: DateTime.tryParse(json['fetch_time'] ?? '') ?? DateTime.now(),
      extractedData: json['extracted_data'] ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'title': title,
      'content': content,
      'summary': summary,
      'language': language,
      'status': status,
      'fetch_time': fetchTime.toIso8601String(),
      'extracted_data': extractedData,
    };
  }

  News copyWith({
    String? url,
    String? title,
    String? content,
    String? summary,
    String? language,
    String? status,
    DateTime? fetchTime,
    Map<String, dynamic>? extractedData,
  }) {
    return News(
      url: url ?? this.url,
      title: title ?? this.title,
      content: content ?? this.content,
      summary: summary ?? this.summary,
      language: language ?? this.language,
      status: status ?? this.status,
      fetchTime: fetchTime ?? this.fetchTime,
      extractedData: extractedData ?? this.extractedData,
    );
  }
}

class TranslatedNews {
  final News originalNews;
  final String translatedTitle;
  final String translatedContent;
  final String translatedSummary;
  final bool isTranslated; // 添加翻译状态标识

  TranslatedNews({
    required this.originalNews,
    required this.translatedTitle,
    required this.translatedContent,
    required this.translatedSummary,
    this.isTranslated = false, // 默认未翻译
  });

  TranslatedNews copyWith({
    News? originalNews,
    String? translatedTitle,
    String? translatedContent,
    String? translatedSummary,
    bool? isTranslated,
  }) {
    return TranslatedNews(
      originalNews: originalNews ?? this.originalNews,
      translatedTitle: translatedTitle ?? this.translatedTitle,
      translatedContent: translatedContent ?? this.translatedContent,
      translatedSummary: translatedSummary ?? this.translatedSummary,
      isTranslated: isTranslated ?? this.isTranslated,
    );
  }
}
