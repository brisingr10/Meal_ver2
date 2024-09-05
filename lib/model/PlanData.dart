class PlanData {
  final String name;
  final List<String> verses;

  //생성자
  PlanData({this.name = '', this.verses = const[]});

  //JSON 직렬화를 위한 팩토리 메서드
  factory PlanData.fromJson(Map<String, dynamic> json){
    return PlanData(
      name: json['name'] as String? ?? '',
      verses: List<String>.from(json['verses'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'verses': verses,
    };
  }
}