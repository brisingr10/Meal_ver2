class Verse {
  final String book;
  final String btext;
  final int chapter;
  final int id;
  final int verse;

  Verse({
    required this.book,
    required this.btext,
    required this.chapter,
    required this.id,
    required this.verse,
  });

  factory Verse.fromJson(Map<String, dynamic> json) {
    return Verse(
      book: json['book'] ?? 0, // null 처리: 기본값 0
      btext: json['btext'] ?? '', // null 처리: 기본값 빈 문자열
      chapter: json['chapter'] ?? 0, // null 처리: 기본값 0
      id: json['id'] ?? 0, // null 처리: 기본값 0
      verse: json['verse'] ?? 0, // null 처리: 기본값 0
    );
  }
}