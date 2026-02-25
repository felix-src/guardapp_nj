class Memo {
  final int id;
  final String title;
  final String fileName;
  final String createdAt;

  Memo({
    required this.id,
    required this.title,
    required this.fileName,
    required this.createdAt,
  });

  factory Memo.fromJson(Map<String, dynamic> json) {
    return Memo(
      id: json['id'],
      title: json['title'],
      fileName: json['fileName'] ?? json['filename'],
      createdAt: json['createdAt'],
    );
  }
}
