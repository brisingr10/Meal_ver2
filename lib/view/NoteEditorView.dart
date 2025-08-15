import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:meal_ver2/model/Note.dart';
import 'package:meal_ver2/viewmodel/MainViewModel.dart';

class NoteEditorView extends StatefulWidget {
  final List<VerseReference> selectedVerses;
  final DateTime date;
  final Note? existingNote;

  const NoteEditorView({
    Key? key,
    required this.selectedVerses,
    required this.date,
    this.existingNote,
  }) : super(key: key);

  @override
  _NoteEditorViewState createState() => _NoteEditorViewState();
}

class _NoteEditorViewState extends State<NoteEditorView> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  String? _selectedColor;
  final List<String> _colorOptions = [
    '#FFE5B4', // Peach
    '#E6E6FA', // Lavender
    '#F0E68C', // Khaki
    '#FFB6C1', // Light Pink
    '#B0E0E6', // Powder Blue
    '#DDA0DD', // Plum
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.existingNote?.title ?? '');
    _contentController = TextEditingController(text: widget.existingNote?.content ?? '');
    _selectedColor = widget.existingNote?.color;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _saveNote() {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('제목을 입력해주세요')),
      );
      return;
    }

    final viewModel = Provider.of<MainViewModel>(context, listen: false);
    
    if (widget.existingNote != null) {
      // Update existing note
      final updatedNote = widget.existingNote!.copyWith(
        title: _titleController.text,
        content: _contentController.text,
        selectedVerses: widget.selectedVerses,
        color: _selectedColor,
      );
      viewModel.updateNote(updatedNote);
    } else {
      // Create new note
      final newNote = Note.create(
        date: widget.date,
        title: _titleController.text,
        content: _contentController.text,
        selectedVerses: widget.selectedVerses,
        color: _selectedColor,
      );
      viewModel.addNote(newNote);
    }

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('yyyy년 MM월 dd일', 'ko_KR').format(widget.date);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.existingNote != null ? '노트 수정' : '새 노트',
          style: TextStyle(fontFamily: 'Settingfont'),
        ),
        actions: [
          TextButton(
            onPressed: _saveNote,
            child: Text(
              '저장',
              style: TextStyle(
                fontFamily: 'Settingfont',
                fontSize: 16,
                color: Theme.of(context).brightness == Brightness.light
                    ? Colors.black
                    : Colors.white,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date display
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                dateStr,
                style: TextStyle(
                  fontFamily: 'Mealfont',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: 16),
            
            // Selected verses section
            Text(
              '선택된 구절',
              style: TextStyle(
                fontFamily: 'Settingfont',
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Container(
              constraints: BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.all(12),
                itemCount: widget.selectedVerses.length,
                separatorBuilder: (context, index) => Divider(),
                itemBuilder: (context, index) {
                  final verse = widget.selectedVerses[index];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        verse.fullReference,
                        style: TextStyle(
                          fontFamily: 'Mealfont',
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        verse.text,
                        style: TextStyle(
                          fontFamily: 'Biblefont',
                          fontSize: 14,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            SizedBox(height: 24),
            
            // Color selection
            Text(
              '색상 선택',
              style: TextStyle(
                fontFamily: 'Settingfont',
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ..._colorOptions.map((color) => GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedColor = _selectedColor == color ? null : color;
                    });
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Color(int.parse(color.replaceAll('#', '0xFF'))),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _selectedColor == color 
                            ? Theme.of(context).primaryColor 
                            : Colors.grey.withOpacity(0.3),
                        width: _selectedColor == color ? 3 : 1,
                      ),
                    ),
                  ),
                )),
                // No color option
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedColor = null;
                    });
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _selectedColor == null 
                            ? Theme.of(context).primaryColor 
                            : Colors.grey.withOpacity(0.3),
                        width: _selectedColor == null ? 3 : 1,
                      ),
                    ),
                    child: Icon(
                      Icons.clear,
                      size: 20,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 24),
            
            // Title input
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: '제목',
                labelStyle: TextStyle(fontFamily: 'Settingfont'),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              style: TextStyle(
                fontFamily: 'Mealfont',
                fontSize: 16,
              ),
            ),
            SizedBox(height: 16),
            
            // Content input
            TextField(
              controller: _contentController,
              maxLines: 10,
              decoration: InputDecoration(
                labelText: '내용',
                labelStyle: TextStyle(fontFamily: 'Settingfont'),
                alignLabelWithHint: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              style: TextStyle(
                fontFamily: 'Mealfont',
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}