import 'package:json_annotation/json_annotation.dart';

part 'Plan.g.dart';

@JsonSerializable()
class Plan {
  String? day;
  String? book;
  int? fChap;
  int? fVer;
  int? lChap;
  int? lVer;

  Plan({
    this.day,
    this.book,
    this.fChap,
    this.fVer,
    this.lChap,
    this.lVer,
  });

  factory Plan.fromJson(Map<String, dynamic> json) => _$PlanFromJson(json);
  Map<String, dynamic> toJson() => _$PlanToJson(this);
}