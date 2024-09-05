class Verse{
  final int number;
  final String text;

  Verse({required this.number, required this.text});

  factory Verse.fromJson(Map<String, dynamic> json){
    return Verse(
      number: json['number'] as int,
      text: json['text'] as String,
    );
  }

  Map<String, dynamic> toJson(){
    return {
      'number':number,
      'text':text,
    };
  }
}