// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plan.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Plan _$PlanFromJson(Map<String, dynamic> json) => Plan(
      day: json['day'] as String?,
      book: json['book'] as String?,
      fullName: json['fullName'] as String?,
      fChap: (json['fChap'] as num?)?.toInt(),
      fVer: (json['fVer'] as num?)?.toInt(),
      lChap: (json['lChap'] as num?)?.toInt(),
      lVer: (json['lVer'] as num?)?.toInt(),
    );

Map<String, dynamic> _$PlanToJson(Plan instance) => <String, dynamic>{
      'day': instance.day,
      'book': instance.book,
      'fullName': instance.fullName,
      'fChap': instance.fChap,
      'fVer': instance.fVer,
      'lChap': instance.lChap,
      'lVer': instance.lVer,
    };
