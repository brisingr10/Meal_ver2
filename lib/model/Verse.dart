class Verse {
  final String bibleType;
  final String book;
  final String btext;
  final String fullName;
  final int chapter;
  final int id;
  final int verse;

  Verse({
    required this.bibleType,
    required this.book,
    required this.btext,
    required this.fullName,
    required this.chapter,
    required this.id,
    required this.verse,
  });

  factory Verse.fromJson(Map<String, dynamic> json) {
    return Verse(
      bibleType: '',
      book: json['book'] ?? 0, // null 처리: 기본값 0
      btext: json['btext'] ?? '', // null 처리: 기본값 빈 문자열
      fullName: json['fullName'] ?? '',
      chapter: json['chapter'] ?? 0, // null 처리: 기본값 0
      id: json['id'] ?? 0, // null 처리: 기본값 0
      verse: json['verse'] ?? 0, // null 처리: 기본값 0
    );
  }
}