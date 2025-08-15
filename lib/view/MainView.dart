import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:meal_ver2/model/Verse.dart';
import 'package:meal_ver2/model/Note.dart';
import 'package:meal_ver2/viewmodel/MainViewModel.dart';
import 'package:provider/provider.dart';
import 'package:meal_ver2/view/SelectBibleView.dart';
import 'package:meal_ver2/view/NoteEditorView.dart';
import 'package:meal_ver2/view/NotesListView.dart';
import 'package:url_launcher/url_launcher.dart';

import '../util/CustomTheme.dart';
import 'OptionView.dart'; // 성경 선택 화면을 import

class Meal2View extends StatefulWidget {
  @override
  _Meal2ViewState createState() => _Meal2ViewState();
}

class _Meal2ViewState extends State<Meal2View> {
  bool isLoading = true;
  String errorMessage = '';
  DateTime? selectedDate;
  late MainViewModel viewModel;
  
  // Selection mode variables
  bool isSelectionMode = false;
  Set<String> selectedVerseIds = {};
  List<VerseReference> selectedVerses = [];

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    viewModel =
        Provider.of<MainViewModel>(context, listen: false); // viewModel 가져오기
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      //await viewModel.loadPreferences(); // 초기화 작업을 한 번만 실행
      setState(() {
        isLoading = false; // 로딩 상태 종료
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Error loading data: $e';
        isLoading = false;
      });
    }
  }

  Future<void> _refreshData() async {
    try {
      await viewModel.refreshVersesForDate(DateTime.now()); // 날짜에 맞게 데이터 새로고침
      setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Error refreshing data : $e';
        isLoading = false;
      });
    }
  }

  void _changeDate(BuildContext context, bool isNextDay) {
    final viewModel = Provider.of<MainViewModel>(context, listen: false);
    final currentDate = viewModel.SelectedDate ?? DateTime.now();
    final newDate = isNextDay
        ? currentDate.add(Duration(days: 1))
        : currentDate.subtract(Duration(days: 1));

    // Exit selection mode when changing date
    if (isSelectionMode) {
      _exitSelectionMode();
    }
    
    viewModel.setSelectedDate(newDate);
    _scrollController.animateTo(
      0.0,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }
  
  void _enterSelectionMode() {
    setState(() {
      isSelectionMode = true;
      selectedVerseIds.clear();
      selectedVerses.clear();
    });
  }
  
  void _exitSelectionMode() {
    setState(() {
      isSelectionMode = false;
      selectedVerseIds.clear();
      selectedVerses.clear();
    });
  }
  
  void _toggleVerseSelection(Verse verse, String bibleType) {
    final verseRef = VerseReference.fromVerse(verse, bibleType);
    final verseId = verseRef.verseId;
    
    setState(() {
      if (selectedVerseIds.contains(verseId)) {
        selectedVerseIds.remove(verseId);
        selectedVerses.removeWhere((v) => v.verseId == verseId);
      } else {
        selectedVerseIds.add(verseId);
        selectedVerses.add(verseRef);
      }
    });
  }
  
  void _createNoteFromSelection() async {
    if (selectedVerses.isEmpty) return;
    
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NoteEditorView(
          selectedVerses: selectedVerses,
          date: viewModel.SelectedDate ?? DateTime.now(),
        ),
      ),
    );
    
    if (result == true) {
      // Note was created successfully
      _exitSelectionMode();
      // Refresh to show note indicators
      setState(() {});
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print('Building Meal2View...');
    return WillPopScope(
      onWillPop: () async {
        if (isSelectionMode) {
          _exitSelectionMode();
          return false;
        }
        return true;
      },
      child: GestureDetector(
        onHorizontalDragEnd: (details) {
          if (!isSelectionMode) {
            if (details.primaryVelocity! < 0) {
              _changeDate(context, true);
            } else if (details.primaryVelocity! > 0) {
              _changeDate(context, false);
            }
          }
        },
      child: ValueListenableBuilder<ThemeMode>(
        valueListenable: MainViewModel.themeMode,
        builder: (context, themeMode, child) {
          return MaterialApp(
            themeMode: themeMode,
            theme: ThemeData.light(),
            darkTheme: ThemeData.dark(),
            home: Scaffold(
              endDrawer: Drawer(
                child: ThemeAndBibleMenu(),
              ),
              body: SafeArea(
                child: Consumer<MainViewModel>(
                  builder: (context, viewModel, child) {
                    if (viewModel.IsLoading) {
                      print('UI: Loading state...');
                      return Center(child: CircularProgressIndicator());
                    }

                    print('UI: Displaying data.');
                    return Container(
                      color: Theme.of(context).colorScheme.background,
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Header(
                              selectedDate: selectedDate,
                              isSelectionMode: isSelectionMode,
                              selectedCount: selectedVerseIds.length,
                              onExitSelectionMode: _exitSelectionMode,
                              onSelectDate: () async {
                                final DateTime? pickedDate = await showDatePicker(
                                  context: context,
                                  initialDate: selectedDate ?? DateTime.now(),
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2030),
                                  initialEntryMode: DatePickerEntryMode.calendarOnly,
                                );
                                if (pickedDate != null &&
                                    pickedDate != selectedDate) {
                                  setState(() {
                                    selectedDate = pickedDate;
                                  });
                                  viewModel.setSelectedDate(pickedDate);
                                }
                              },
                            ),
                            //SizedBox(height: 16.0), // 헤더와 본문 사이에 간격 추가
                            Expanded(
                              child: RefreshIndicator(
                                onRefresh: _refreshData,
                                child: ListView.builder(
                                  controller: _scrollController,
                                  itemCount: viewModel.DataSource[0].length,
                                  itemBuilder: (context, index) {
                                    return Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        ...viewModel.DataSource.asMap().entries.map((entry) {
                                          int bibleIndex = entry.key;
                                          List<Verse> bibleVerses = entry.value;

                                          if (index < bibleVerses.length) {
                                            Verse verse = bibleVerses[index];
                                            bool isFirstBible = bibleIndex == 0;
                                            bool isSecondBible = bibleIndex == 1;
                                            bool isThirdBible = bibleIndex == 2;
                                            bool isFourthBible = bibleIndex == 3;

                                            final bibleType = viewModel.SelectedBibles.isNotEmpty && bibleIndex < viewModel.SelectedBibles.length
                                                ? viewModel.SelectedBibles[bibleIndex]
                                                : '';
                                            final verseRef = VerseReference.fromVerse(verse, bibleType);
                                            final isSelected = selectedVerseIds.contains(verseRef.verseId);
                                            final hasNote = viewModel.hasNoteForVerse(viewModel.SelectedDate ?? DateTime.now(), verseRef);
                                            
                                            return GestureDetector(
                                              onLongPress: () {
                                                if (!isSelectionMode) {
                                                  _enterSelectionMode();
                                                  _toggleVerseSelection(verse, bibleType);
                                                }
                                              },
                                              onTap: () {
                                                if (isSelectionMode) {
                                                  _toggleVerseSelection(verse, bibleType);
                                                }
                                              },
                                              child: Container(
                                                color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.1) : Colors.transparent,
                                                child: Row(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    if (isSelectionMode)
                                                      Checkbox(
                                                        value: isSelected,
                                                        onChanged: (bool? value) {
                                                          _toggleVerseSelection(verse, bibleType);
                                                        },
                                                      ),
                                                    Opacity(opacity: isFirstBible? 1.0: 0.1,
                                                    child: Container(
                                                      alignment: Alignment.centerRight,
                                                      width: MediaQuery.of(context).size.width * 0.05,
                                                      height: MediaQuery.of(context).size.width * 0.07,
                                                      child: Text('${verse.verse}. ',
                                                        style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color,
                                                          fontFamily: 'Biblefont',
                                                          fontWeight: FontWeight.bold,
                                                          fontSize: MediaQuery.of(context).size.width * 0.035,),
                                                          textAlign: TextAlign.center,
                                                      ),
                                                    ),
                                                  ),
                                                  SizedBox(width: MediaQuery.of(context).size.width * 0.01,),

                                                    Expanded(
                                                      child: Row(
                                                        children: [
                                                          Expanded(
                                                            child: SelectableText(
                                                              viewModel.DataSource.length > 1 // 성경이 여러 개인 경우 확인
                                                                  ? '${verse.bibleType} ${verse.btext}' // 여러 개일 경우 bibletype 포함
                                                                  : '${verse.btext}', // 하나일 경우 bibletype 없이 btext만 표시
                                                              style: TextStyle(color: isFirstBible? Theme.of(context).textTheme.bodyLarge?.color: isSecondBible? Colors.blueGrey : isThirdBible? Colors.brown : Colors.deepPurple,
                                                                fontWeight: FontWeight.normal,
                                                                fontFamily: 'Biblefont',
                                                                fontSize: viewModel.fontSize,
                                                                height: viewModel.lineSpacing,
                                                              ),
                                                            ),
                                                          ),
                                                          if (hasNote && !isSelectionMode)
                                                            Padding(
                                                              padding: EdgeInsets.only(left: 4),
                                                              child: Icon(
                                                                Icons.note,
                                                                size: 16,
                                                                color: Theme.of(context).primaryColor,
                                                              ),
                                                            ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          } else {
                                            return SizedBox.shrink();
                                          }
                                        }).toList(),
                                        // 절간 간격 추가
                                        SizedBox(height: viewModel.verseSpacing),
                                      ],
                                    );
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              floatingActionButton: isSelectionMode && selectedVerseIds.isNotEmpty
                  ? FloatingActionButton.extended(
                      onPressed: _createNoteFromSelection,
                      label: Text('노트 만들기'),
                      icon: Icon(Icons.note_add),
                      backgroundColor: Theme.of(context).primaryColor,
                    )
                  : null,
              floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
            ),
          );
        },
        ),
      ),
    );
  }
}
//SizedBox(height: viewModel.verseSpacing),
// 절간 간격 적용// 항목 사이 간격
class Header extends StatelessWidget {
  final DateTime? selectedDate;
  final VoidCallback onSelectDate;
  final bool isSelectionMode;
  final int selectedCount;
  final VoidCallback? onExitSelectionMode;

  Header({
    this.selectedDate, 
    required this.onSelectDate,
    this.isSelectionMode = false,
    this.selectedCount = 0,
    this.onExitSelectionMode,
  });

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<MainViewModel>(context);

    final today = DateTime.now();
    final todayString = DateFormat('yyy-MM-dd').format(today);

    // MainViewModel에서 SelectedDate를 가져옴
    final selectedDate = viewModel.SelectedDate;

    final displayDate = selectedDate != null
        ? DateFormat('MM/dd(E)', 'ko_KR').format(selectedDate)
        : DateFormat('MM/dd(E)', 'ko_KR').format(today);

    // 오늘의 계획 정보를 가져오기
    final todayPlanDescription = viewModel.TodayPlan != null
        ? '${viewModel.TodayPlan!.book} ${viewModel.TodayPlan!.fChap}:${viewModel.TodayPlan!.fVer} - ${viewModel.TodayPlan!.lChap}:${viewModel.TodayPlan!.lVer}'
        : '오늘의 계획이 없습니다';

    return Container(
      padding: EdgeInsets.symmetric(vertical: 0.1, horizontal: 5),
      color: Colors.transparent,
      child: Row(
        children: [
          if (isSelectionMode)
            IconButton(
              icon: Icon(Icons.close),
              onPressed: onExitSelectionMode,
            )
          else
            SizedBox(width: 10),
          Expanded(
            child: isSelectionMode
              ? Container(
                  alignment: Alignment.centerLeft,
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    '${selectedCount}개 선택됨',
                    style: TextStyle(
                      fontFamily: 'Mealfont',
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).brightness == Brightness.light
                          ? Colors.black
                          : Colors.white,
                    ),
                  ),
                )
              : GestureDetector( // 터치 이벤트를 감지할 수 있도록 GestureDetector로 감싸기
                  onTap: () {
                    onSelectDate(); // 날짜 선택 기능 호출
                  },
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end, // Row 내에서 하단 정렬
              children: [

                    Text(
                      todayPlanDescription,
                      textAlign: TextAlign.left,
                      style: TextStyle(
                        fontFamily: 'Mealfont',
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        //color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
                        color: Theme.of(context).brightness == Brightness.light
                            ? Colors.black // 라이트 테마일 때 회색
                            : Colors.white, // 다크 테마일 때 검은색
                      ),
                    ),
                SizedBox(width: 20), // 날짜와 계획 사이 간격
                Container(
                  //width: double.infinity,
                  alignment: Alignment.bottomLeft,
                  child:
                    Text(
                      displayDate,
                      textAlign: TextAlign.left,
                      style: TextStyle(fontFamily: 'Mealfont',fontSize: 13,
                        fontWeight: FontWeight.normal,
                        //color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black38,
                        color: Theme.of(context).brightness == Brightness.light
                            ? Colors.black45 // 라이트 테마일 때 회색
                            : Colors.white54, // 다크 테마일 때 검은색
                      ),
                    ),
                ),
                  ],
                ),
              ),
          ),
          if (!isSelectionMode) ...[  
            SizedBox(width: 10),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.notes),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => NotesListView(
                          date: viewModel.SelectedDate ?? DateTime.now(),
                        ),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: Icon(Icons.menu_book_sharp),
                  onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => SelectBibleView()),
                      );
                    },
                ),
                IconButton(
                  icon: Icon(Icons.settings), // 메뉴 버튼
                  onPressed: () {
                    Scaffold.of(context).openEndDrawer(); // Drawer 열기
                  },
                ),
              ],
            ),
          ],
        ],

      ),
    );
  }
}

class ThemeAndBibleMenu extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<MainViewModel>(context, listen: true);
    final List<double> values = [1.0, 1.2, 1.4, 1.6, 1.8, 2.0 , 2.2, 2.4];

    return Drawer(
      child: SafeArea(
        child: Stack(
          children: [
        ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              color: Theme.of(context).textTheme.bodyLarge?.backgroundColor,
              padding: EdgeInsets.fromLTRB(10, 10, 10, 10),
              height: 60, // 원하는 높이 설정
              child: Text(
                '설정',
                style: TextStyle(
                  fontFamily: 'Settingfont',
                  color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
                  fontSize: 16,
                ),
              ),
            ),
            ListTile(
              leading: Icon(
                MainViewModel.themeMode.value == ThemeMode.light
                    ? Icons.light_mode
                    : Icons.dark_mode,
              ),
              title: Text(
                '테마 변경',
                style: TextStyle(
                  fontFamily: 'Settingfont',
                  color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
                  fontSize: 16,
                ),
              ),
              onTap: () {
                viewModel.toggleTheme(); // 테마 변경 로직 호출
                Navigator.of(context).pop(); // Drawer 닫기
              },
            ),

            Divider(),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '글자 크기',
                    style: TextStyle(
                      fontFamily: 'Settingfont',
                      fontSize: 14,
                      color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
                    ),
                  ),
                  Slider(
                    value: viewModel.fontSize,
                    min: 12.0,
                    max: 36.0,
                    divisions: 12, // 슬라이더 구간 나누기
                    label: viewModel.fontSize.toStringAsFixed(1),
                    onChanged: (value) {
                      viewModel.updateFontSize(value);
                    },
                  ),
                  SizedBox(height: 16),
                  Text(
                    '절간 간격',
                    style: TextStyle(
                      fontFamily: 'Settingfont',
                      fontSize: 14,
                      color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
                    ),
                  ),
                  Slider(
                    value: viewModel.verseSpacing,
                    min: 8.0,
                    max: 32.0,
                    divisions: 12, // 슬라이더 구간 나누기
                    label: viewModel.verseSpacing.toStringAsFixed(1),
                    onChanged: (value) {
                      viewModel.updateVerseSpacing(value);
                    },
                  ),
                  SizedBox(height: 16),
                  Text(
                    '줄간 간격',
                    style: TextStyle(
                      fontFamily: 'Settingfont',
                      fontSize: 14,
                      color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
                    ),
                  ),

                  Slider(
                    value: viewModel.lineSpacing,
                    min: 1.0,
                    max: 3.0,
                    divisions: values.length - 1, // 슬라이더 구간 나누기
                    label: viewModel.lineSpacing.toStringAsFixed(1),
                    onChanged: (value) {
                      viewModel.updateLineSpacing(value);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Opacity(
                opacity: 0.5, // 투명도 설정
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [

                      Text(
                        'Originally created by InPyo Hong',
                        style: TextStyle(
                          fontFamily: 'Mealfont',
                          fontSize: 10,
                          color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
                        ),
                      ),
                      SizedBox(height: 4), // 간격 추가
                      Text(
                        'Futher developed by TMTB',
                        style: TextStyle(
                          fontFamily: 'Mealfont',
                          fontSize: 10,
                          color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
                        ),
                      ),
                      SizedBox(height: 4), // 간격 추가
                      Text(
                        'ⓒ 2024. 대한성서공회 all rights reserved.',
                        style: TextStyle(
                          fontFamily: 'Mealfont',
                          fontSize: 10,
                          color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
                        ),
                      ),
                      Text(
                        'New Americal Standard Bible Copyright ⓒ 1960, 1971, 1995, 2020 by The Lockman Foundation, La Habra, Calif. All rights reserved. For Permission to Quote Information visit www.lockman.org',
                        style: TextStyle(
                          fontFamily: 'Mealfont',
                          fontSize: 10,
                          color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      ListTile(
                        title:
                        Text(
                          textAlign: TextAlign.center,
                          'FeedBack',
                          style: TextStyle(
                            fontFamily: 'Mealfont',
                            color: Colors.blueAccent, // 라이트 테마일 때 회색// 다크 테마일 때 검은색
                            fontSize: 10,
                            decoration: TextDecoration.underline,
                            decorationColor:Colors.blueAccent,
                          ),
                        ),
                        onTap: () async {
                          const url = 'https://docs.google.com/forms/d/e/1FAIpQLScboAaHnboWAq8FJcDYStHRE6ZeqYAmY0AAuatoxeXO1X_WtA/viewform?usp=sharing';
                          if (await canLaunchUrl(Uri.parse(url))) {
                            await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                          } else {
                            // URL을 열 수 없을 경우 처리
                            print('Could not launch $url');
                          }
                          Navigator.of(context).pop(); // Drawer 닫기
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}