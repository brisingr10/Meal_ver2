import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:meal_ver2/model/Verse.dart';
import 'package:meal_ver2/viewmodel/MainViewModel.dart';
import 'package:provider/provider.dart';
import 'package:meal_ver2/view/SelectBibleView.dart';

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

    viewModel.setSelectedDate(newDate);
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print('Building Meal2View...');
    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity! < 0) {
          _changeDate(context, true);
        } else if (details.primaryVelocity! > 0) {
          _changeDate(context, false);
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
              // 우측에서 열리는 메뉴 추가
              endDrawer: Drawer(
                child: ThemeAndBibleMenu(),
              ),
              body: SafeArea(
                child: Consumer<MainViewModel>(
                  builder: (context, viewModel, child) {
                    // 로딩 중일 때
                    if (viewModel.IsLoading) {
                      print('UI: Loading state...');
                      return Center(child: CircularProgressIndicator());
                    }

                    // 로딩이 끝났지만 데이터가 없는 경우
                    if (viewModel.DataSource.isEmpty) {
                      print('UI: No data available.');
                      return Center(child: Text('No data available'));
                    }

                    // 로딩이 끝나고 데이터가 있는 경우
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
                              onSelectDate: () async {
                                final DateTime? pickedDate =
                                    await showDatePicker(
                                  context: context,
                                  initialDate: selectedDate ?? DateTime.now(),
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2024, 12, 31),
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
                            SizedBox(height: 16.0), // 헤더와 본문 사이에 간격 추가
                            Expanded(
                              child: RefreshIndicator(
                                onRefresh: _refreshData, // 새로고침 호출
                                child: ListView.builder(
                                  controller: ScrollController(),
                                  itemCount: viewModel.DataSource[0].length,
                                  // 각 성경의 구절 수로 설정 (동일한 절 수라고 가정)
                                  itemBuilder: (context, index) {
                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: viewModel.DataSource.asMap()
                                              .entries
                                              .map((entry) {
                                            int bibleIndex = entry.key;
                                            List<Verse> bibleVerses =
                                                entry.value;

                                            if (index < bibleVerses.length) {
                                              Verse verse = bibleVerses[index];
                                              bool isFirstBible = bibleIndex ==
                                                  0; // 첫 번째 성경인지 확인

                                              return GestureDetector(
                                                onLongPress: () {
                                                  // 구절 전체를 복사
                                                  final textToCopy =
                                                      '${verse.verse}. ${verse.btext}';
                                                  Clipboard.setData(
                                                      ClipboardData(
                                                          text: textToCopy));
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                          '구절이 복사되었습니다: $textToCopy'),
                                                    ),
                                                  );
                                                },
                                                child: Row(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      '${verse.verse}. ',
                                                      style: TextStyle(
                                                        color: Theme.of(context)
                                                            .textTheme
                                                            .bodyLarge
                                                            ?.color,
                                                        fontFamily: 'Biblefont',
                                                        fontSize: MediaQuery.of(
                                                                    context)
                                                                .size
                                                                .width *
                                                            0.025,
                                                      ),
                                                    ),
                                                    Expanded(
                                                      child: SelectableText(
                                                        verse.btext,
                                                        style: TextStyle(
                                                          color: isFirstBible
                                                              ? Theme.of(
                                                                      context)
                                                                  .textTheme
                                                                  .bodyLarge
                                                                  ?.color
                                                              : Colors.grey,
                                                          fontWeight:
                                                              FontWeight.normal,
                                                          fontFamily:
                                                              'Biblefont',
                                                          fontSize: isFirstBible
                                                              ? viewModel.fontSize
                                                              : viewModel.fontSize * 0.9,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            } else {
                                              return SizedBox.shrink();
                                            }
                                          }).toList(),
                                        ),
                                        SizedBox(height: viewModel.lineSpacing), // 절간 간격 적용// 항목 사이 간격
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
            ),
          );
        },
      ),
    );
  }
}

class Header extends StatelessWidget {
  final DateTime? selectedDate;
  final VoidCallback onSelectDate;

  Header({this.selectedDate, required this.onSelectDate});

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<MainViewModel>(context);

    final today = DateTime.now();
    final todayString = DateFormat('yyy-MM-dd').format(today);

    // MainViewModel에서 SelectedDate를 가져옴
    final selectedDate = viewModel.SelectedDate;

    final displayDate = selectedDate != null
        ? DateFormat('yyyy-MM-dd').format(selectedDate)
        : todayString;

    // 오늘의 계획 정보를 가져오기
    final todayPlanDescription = viewModel.TodayPlan != null
        ? '${viewModel.TodayPlan!.fullName} ${viewModel.TodayPlan!.fChap}:${viewModel.TodayPlan!.fVer} - ${viewModel.TodayPlan!.lChap}:${viewModel.TodayPlan!.lVer} 절'
        : '오늘의 계획이 없습니다';

    return Container(
      padding: EdgeInsets.fromLTRB(5, 0, 0, 0),
      color: Colors.transparent,
      child: Row(
        children: [
          SizedBox(width: 10),
          Expanded(
            child: Column(
              children: [
                Text(
                  displayDate,
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    fontFamily: 'Mealfont',
                    fontSize: 20, // 날짜는 조금 작게
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
                  ),
                ),
                SizedBox(height: 4), // 날짜와 계획 사이 간격
                Text(
                  todayPlanDescription,
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    fontFamily: 'Mealfont',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyLarge?.color ??
                        Colors.black,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 10),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 날짜 선택 버튼
              IconButton(
                icon: Icon(Icons.calendar_today),
                onPressed: () {
                  onSelectDate();
                },
              ),
              IconButton(
                icon: Icon(Icons.menu), // 메뉴 버튼
                onPressed: () {
                  Scaffold.of(context).openEndDrawer(); // Drawer 열기
                },
              ),
            ],
          ),
        ],

      ),
    );
  }
}

class ThemeAndBibleMenu extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<MainViewModel>(context, listen: true);

    return Drawer(
      child: SafeArea(
        child: Stack(
          children: [
        ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              color: Theme.of(context).colorScheme.surface,
              padding: EdgeInsets.fromLTRB(10, 10, 10, 10),
              height: 60, // 원하는 높이 설정
              child: Text(
                '설정',
                style: TextStyle(
                  fontFamily: 'Mealfont',
                  color: Theme.of(context).textTheme.bodyLarge?.color ??
                      Colors.black,
                  fontSize: 24,
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
                  fontFamily: 'Mealfont',
                  color: Theme.of(context).textTheme.bodyLarge?.color ??
                      Colors.black,
                  fontSize: 24,
                ),
              ),
              onTap: () {
                viewModel.toggleTheme(); // 테마 변경 로직 호출
                Navigator.of(context).pop(); // Drawer 닫기
              },
            ),
            ListTile(
              leading: Icon(Icons.menu_book),
              title: Text(
                '성경 선택',
                style: TextStyle(
                  fontFamily: 'Mealfont',
                  color: Theme.of(context).textTheme.bodyLarge?.color ??
                      Colors.black,
                  fontSize: 24,
                ),
              ),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => SelectBibleView()),
                );
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
                      fontFamily: 'Mealfont',
                      fontSize: 16,
                      color: Theme.of(context).textTheme.bodyLarge?.color ??
                          Colors.black,
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
                      fontFamily: 'Mealfont',
                      fontSize: 16,
                      color: Theme.of(context).textTheme.bodyLarge?.color ??
                          Colors.black,
                    ),
                  ),
                  Slider(
                    value: viewModel.lineSpacing,
                    min: 8.0,
                    max: 32.0,
                    divisions: 12, // 슬라이더 구간 나누기
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
                        'First Create By InPyo Hong',
                        style: TextStyle(
                          fontFamily: 'Mealfont',
                          fontSize: 16,
                          color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
                        ),
                      ),
                      SizedBox(height: 4), // 간격 추가
                      Text(
                        'ⓒ 2024. 대한성서공회 all rights reserved.',
                        style: TextStyle(
                          fontFamily: 'Mealfont',
                          fontSize: 16,
                          color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
                        ),
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