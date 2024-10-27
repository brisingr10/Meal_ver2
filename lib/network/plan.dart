import 'package:json_annotation/json_annotation.dart';

// 'Plan.g.dart' 파일을 이 파일의 일부로 포함
part 'plan.g.dart';

@JsonSerializable()
class Plan {
  String? day;
  String? book;
  String? fullName;
  int? fChap;
  int? fVer;
  int? lChap;
  int? lVer;

  Plan({
    this.day,
    this.book,
    this.fullName,
    this.fChap,
    this.fVer,
    this.lChap,
    this.lVer,
  });

  @override
  String toString() {
    return 'Plan(day: $day, book: $book, fullName: $fullName, fChap: $fChap, fVer: $fVer, lChap: $lChap, lVer: $lVer)';
  }
  // JSON 직렬화/역직렬화 함수
  factory Plan.fromJson(Map<String, dynamic> json) => _$PlanFromJson(json);
  Map<String, dynamic> toJson() => _$PlanToJson(this);
}