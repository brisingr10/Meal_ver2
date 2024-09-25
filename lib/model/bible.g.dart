// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bible.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Book _$BookFromJson(Map<String, dynamic> json) => Book(
  book: json['book'] ?? '', // null 처리: 빈 문자열로 기본값 설정
  btext: json['btext'] ??'',
  chapter: json['chapter'] ?? 0, // 장 번호
  verse: json['verse'] ?? 0, // 구절 번호
  id: json['id'] ?? 0, // 구절 고유 ID
    );

Map<String, dynamic> _$BookToJson(Book instance) => <String, dynamic>{
      'book': instance.book,
      'btext' : instance.btext,
      'chapter': instance.chapter,
      'verse': instance.verse,
      'id' : instance.id
    };
