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
      book: json['book'] as String,
      btext: json['btext'] as String,
      fullName: json['fullName'] as String,
      chapter: (json['chapter'] as num).toInt(),
      verse: (json['verse'] as num).toInt(),
      id: (json['id'] as num).toInt(),
    );

Map<String, dynamic> _$BookToJson(Book instance) => <String, dynamic>{
      'book': instance.book,
      'btext': instance.btext,
      'fullName': instance.fullName,
      'chapter': instance.chapter,
      'verse': instance.verse,
      'id': instance.id,
    };
