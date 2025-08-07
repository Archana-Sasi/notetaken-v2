class Note {
  final String id;
  final String folderId;
  final String title;
  final String content;
  final String? imageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  Note({
    required this.id,
    required this.folderId,
    required this.title,
    required this.content,
    this.imageUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'folderId': folderId,
      'title': title,
      'content': content,
      'imageUrl': imageUrl,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'] ?? '',
      folderId: map['folderId'] ?? '',
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      imageUrl: map['imageUrl'],
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }
} 