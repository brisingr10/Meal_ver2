import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:meal_ver2/model/Note.dart';
import 'package:meal_ver2/viewmodel/MainViewModel.dart';
import 'package:meal_ver2/view/NoteEditorView.dart';

class NotesListView extends StatefulWidget {
  final DateTime date;

  const NotesListView({
    Key? key,
    required this.date,
  }) : super(key: key);

  @override
  _NotesListViewState createState() => _NotesListViewState();
}

class _NotesListViewState extends State<NotesListView> {
  late DateTime currentDate;

  @override
  void initState() {
    super.initState();
    currentDate = widget.date;
  }

  void _changeDate(bool isNextDay) {
    setState(() {
      currentDate = isNextDay
          ? currentDate.add(Duration(days: 1))
          : currentDate.subtract(Duration(days: 1));
    });
  }

  void _editNote(Note note) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NoteEditorView(
          selectedVerses: note.selectedVerses,
          date: note.date,
          existingNote: note,
        ),
      ),
    );

    if (result == true) {
      setState(() {}); // Refresh the list
    }
  }

  void _deleteNote(Note note) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          '노트 삭제',
          style: TextStyle(fontFamily: 'Settingfont'),
        ),
        content: Text(
          '이 노트를 삭제하시겠습니까?',
          style: TextStyle(fontFamily: 'Mealfont'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('취소'),
          ),
          TextButton(
            onPressed: () {
              final viewModel = Provider.of<MainViewModel>(context, listen: false);
              viewModel.deleteNote(note.id);
              Navigator.pop(context);
              setState(() {}); // Refresh the list
            },
            child: Text(
              '삭제',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<MainViewModel>(context);
    final notes = viewModel.getNotesForDate(currentDate);
    final dateStr = DateFormat('yyyy년 MM월 dd일', 'ko_KR').format(currentDate);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '노트',
          style: TextStyle(fontFamily: 'Settingfont'),
        ),
      ),
      body: Column(
        children: [
          // Date navigation header
          Container(
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.05),
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).dividerColor,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(Icons.chevron_left),
                  onPressed: () => _changeDate(false),
                ),
                Text(
                  dateStr,
                  style: TextStyle(
                    fontFamily: 'Mealfont',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.chevron_right),
                  onPressed: () => _changeDate(true),
                ),
              ],
            ),
          ),
          
          // Notes list
          Expanded(
            child: notes.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.note_outlined,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          '이 날짜에 작성된 노트가 없습니다',
                          style: TextStyle(
                            fontFamily: 'Mealfont',
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '성경 구절을 길게 눌러 노트를 작성해보세요',
                          style: TextStyle(
                            fontFamily: 'Mealfont',
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: notes.length,
                    itemBuilder: (context, index) {
                      final note = notes[index];
                      final timeStr = DateFormat('HH:mm').format(note.createdAt);
                      final hasColor = note.color != null;
                      
                      return Card(
                        margin: EdgeInsets.only(bottom: 12),
                        color: hasColor 
                            ? Color(int.parse(note.color!.replaceAll('#', '0xFF'))).withOpacity(0.3)
                            : null,
                        child: InkWell(
                          onTap: () => _editNote(note),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        note.title,
                                        style: TextStyle(
                                          fontFamily: 'Mealfont',
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        Text(
                                          timeStr,
                                          style: TextStyle(
                                            fontFamily: 'Mealfont',
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        PopupMenuButton<String>(
                                          onSelected: (value) {
                                            if (value == 'edit') {
                                              _editNote(note);
                                            } else if (value == 'delete') {
                                              _deleteNote(note);
                                            }
                                          },
                                          itemBuilder: (context) => [
                                            PopupMenuItem(
                                              value: 'edit',
                                              child: Row(
                                                children: [
                                                  Icon(Icons.edit, size: 20),
                                                  SizedBox(width: 8),
                                                  Text('수정'),
                                                ],
                                              ),
                                            ),
                                            PopupMenuItem(
                                              value: 'delete',
                                              child: Row(
                                                children: [
                                                  Icon(Icons.delete, size: 20, color: Colors.red),
                                                  SizedBox(width: 8),
                                                  Text('삭제', style: TextStyle(color: Colors.red)),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                if (note.content.isNotEmpty) ...[
                                  SizedBox(height: 8),
                                  Text(
                                    note.content,
                                    style: TextStyle(
                                      fontFamily: 'Mealfont',
                                      fontSize: 14,
                                    ),
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                                SizedBox(height: 12),
                                // Verse references
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 4,
                                  children: note.selectedVerses.map((verse) {
                                    return Container(
                                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        verse.reference,
                                        style: TextStyle(
                                          fontFamily: 'Mealfont',
                                          fontSize: 12,
                                          color: Theme.of(context).primaryColor,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                                if (note.updatedAt != note.createdAt) ...[
                                  SizedBox(height: 8),
                                  Text(
                                    '수정됨: ${DateFormat('MM/dd HH:mm').format(note.updatedAt)}',
                                    style: TextStyle(
                                      fontFamily: 'Mealfont',
                                      fontSize: 11,
                                      color: Colors.grey,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}