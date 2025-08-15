import 'package:intl/intl.dart';

class Note {
  final String id;
  final DateTime date; // The date this note belongs to
  final String title;
  final String content;
  final List<VerseReference> selectedVerses; // Selected verses from that day
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? color;

  Note({
    required this.id,
    required this.date,
    required this.title,
    required this.content,
    required this.selectedVerses,
    required this.createdAt,
    required this.updatedAt,
    this.color,
  });

  // Create a new note with auto-generated ID
  factory Note.create({
    required DateTime date,
    required String title,
    required String content,
    required List<VerseReference> selectedVerses,
    String? color,
  }) {
    final now = DateTime.now();
    return Note(
      id: 'note_${now.millisecondsSinceEpoch}',
      date: date,
      title: title,
      content: content,
      selectedVerses: selectedVerses,
      createdAt: now,
      updatedAt: now,
      color: color,
    );
  }

  // Copy with method for updating
  Note copyWith({
    String? title,
    String? content,
    List<VerseReference>? selectedVerses,
    String? color,
  }) {
    return Note(
      id: id,
      date: date,
      title: title ?? this.title,
      content: content ?? this.content,
      selectedVerses: selectedVerses ?? this.selectedVerses,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      color: color ?? this.color,
    );
  }

  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'title': title,
      'content': content,
      'selectedVerses': selectedVerses.map((v) => v.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'color': color,
    };
  }

  // Create from JSON
  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'],
      date: DateTime.parse(json['date']),
      title: json['title'],
      content: json['content'],
      selectedVerses: (json['selectedVerses'] as List)
          .map((v) => VerseReference.fromJson(v))
          .toList(),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      color: json['color'],
    );
  }

  // Get formatted date string for grouping
  String get dateKey => DateFormat('yyyy-MM-dd').format(date);
}

class VerseReference {
  final String bibleType;
  final String book;
  final int chapter;
  final int verse;
  final String text; // Store the actual verse text

  VerseReference({
    required this.bibleType,
    required this.book,
    required this.chapter,
    required this.verse,
    required this.text,
  });

  // Create a unique identifier for this verse
  String get verseId => '$bibleType:$book:$chapter:$verse';

  // Get display reference (e.g., "창세기 1:1")
  String get reference => '$book $chapter:$verse';

  // Get full reference with Bible type
  String get fullReference => '[$bibleType] $book $chapter:$verse';

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'bibleType': bibleType,
      'book': book,
      'chapter': chapter,
      'verse': verse,
      'text': text,
    };
  }

  // Create from JSON
  factory VerseReference.fromJson(Map<String, dynamic> json) {
    return VerseReference(
      bibleType: json['bibleType'],
      book: json['book'],
      chapter: json['chapter'],
      verse: json['verse'],
      text: json['text'],
    );
  }

  // Create from Verse model
  factory VerseReference.fromVerse(dynamic verse, String bibleType) {
    return VerseReference(
      bibleType: bibleType.isEmpty ? verse.bibleType : bibleType,
      book: verse.book,
      chapter: verse.chapter,
      verse: verse.verse,
      text: verse.btext,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VerseReference &&
          runtimeType == other.runtimeType &&
          verseId == other.verseId;

  @override
  int get hashCode => verseId.hashCode;
}