// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bible.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Bible _$BibleFromJson(Map<String, dynamic> json) => Bible(
      books: (json['books'] as List<dynamic>)
          .map((e) => Book.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$BibleToJson(Bible instance) => <String, dynamic>{
      'books': instance.books,
    };

Book _$BookFromJson(Map<String, dynamic> json) => Book(
      abbrev: json['abbrev'] as String,
      chapters: (json['chapters'] as List<dynamic>)
          .map((e) => (e as List<dynamic>).map((e) => e as String).toList())
          .toList(),
      name: json['name'] as String,
    );

Map<String, dynamic> _$BookToJson(Book instance) => <String, dynamic>{
      'abbrev': instance.abbrev,
      'chapters': instance.chapters,
      'name': instance.name,
    };
