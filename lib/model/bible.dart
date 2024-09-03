import 'package:json_annotation/json_annotation.dart';

part 'bible.g.dart';

@JsonSerializable()
class Bible {
  List<Book> books;

  Bible({required this.books});

  factory Bible.fromJson(List<dynamic> json) => Bible(
    books: json.map((e) => Book.fromJson(e as Map<String, dynamic>)).toList(),
  );

  List<dynamic> toJson() => books.map((book) => book.toJson()).toList();
}

@JsonSerializable()
class Book {
  @JsonKey(name: 'abbrev')
  final String abbrev;

  @JsonKey(name: 'chapters')
  final List<List<String>> chapters;

  @JsonKey(name: 'name')
  final String name;

  Book({
    required this.abbrev,
    required this.chapters,
    required this.name,
  });

  factory Book.fromJson(Map<String, dynamic> json) => _$BookFromJson(json);

  Map<String, dynamic> toJson() => _$BookToJson(this);
}