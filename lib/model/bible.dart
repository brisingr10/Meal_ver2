import 'package:json_annotation/json_annotation.dart';

part 'bible.g.dart';

@JsonSerializable()
class Bible {
  List<Book> books;

  Bible({required this.books});

  factory Bible.fromJson(List<dynamic> json) {
    // 로그를 추가하여 JSON 데이터 확인
//    for (var entry in json) {
//      print('Processing entry: $entry'); // 각 엔트리를 출력하여 확인
//    }

    return Bible(
      books: json.map((e) {
//        print('Mapping entry: $e'); // 각 엔트리 맵핑을 로그로 출력
        return Book.fromJson(e as Map<String, dynamic>);
      }).toList(),
    );
  }

  List<dynamic> toJson() => books.map((book) => book.toJson()).toList();
}

@JsonSerializable()
class Book {
  @JsonKey(name: 'book')
  final String book;

  @JsonKey(name: 'btext')
  final String btext;

  @JsonKey(name: 'fullName')
  final String fullName;

  @JsonKey(name: 'chapter')
  final int chapter;

  @JsonKey(name: 'verse')
  final int verse;

  @JsonKey(name: 'id')
  final int id;

  Book({
    required this.book,
    required this.btext,
    required this.fullName,
    required this.chapter,
    required this.verse,
    required this.id,
  });

  factory Book.fromJson(Map<String, dynamic> json) {
    // 로그를 추가하여 각 필드 확인
//    print('Parsing Book: $json');

    final bookValue = json['book'];
    final bookString = bookValue is int ? bookValue.toString() : bookValue as String;

    return Book(
      book: json['book'] ?? '', // null 처리: 빈 문자열로 기본값 설정
      btext: json['btext'] ??'',
      fullName: json['fullName'] ?? '',
      chapter: json['chapter'] ?? 0, // 장 번호
      verse: json['verse'] ?? 0, // 구절 번호
      id: json['id'] ?? 0, // 구절 고유 ID
    );
  }

  Map<String, dynamic> toJson() => _$BookToJson(this);
}