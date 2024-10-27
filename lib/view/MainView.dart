import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:meal_ver2/model/Verse.dart';
import 'package:meal_ver2/viewmodel/MainViewModel.dart';
import 'package:provider/provider.dart';
import 'package:meal_ver2/view/SelectBibleView.dart'; // 성경 선택 화면을 import

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
      await viewModel.loadPreferences(); // 데이터를 다시 로드
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

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print('Building Meal2View...');
    return Scaffold(
      body: Consumer<MainViewModel>(
        builder: (context, viewModel, child) {
          // 로딩 중일 때
          if (viewModel.isLoading) {
            print('UI: Loading state...');
            return Center(child: CircularProgressIndicator());
          }

          // 로딩이 끝났지만 데이터가 없는 경우
          if (viewModel.dataSource.isEmpty) {
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
                      final DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: selectedDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2024, 12, 31),
                      );
                      if (pickedDate != null && pickedDate != selectedDate) {
                        setState(() {
                          selectedDate = pickedDate;
                        });
                        viewModel.setSelectedDate(pickedDate);
                      }
                    },
                  ),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: _refreshData, // 새로고침 호출
                      child: ListView.builder(
                        controller: ScrollController(),
                        itemCount: viewModel.dataSource[0].length, // 각 성경의 구절 수로 설정 (동일한 절 수라고 가정)
                        itemBuilder: (context, index) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: viewModel.dataSource.asMap().entries.map((entry) {
                              int bibleIndex = entry.key;
                              List<Verse> bibleVerses = entry.value;

                              if (index < bibleVerses.length) {
                                Verse verse = bibleVerses[index];
                                bool isFirstBible = bibleIndex == 0; // 첫 번째 성경인지 확인

                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${verse.verse}. ',
                                      style: TextStyle(
                                        color: Colors.black54,
                                        fontFamily: 'Biblefont',
                                        fontSize: MediaQuery.of(context).size.width * 0.025,
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        verse.btext,
                                        style: TextStyle(
                                          color: isFirstBible ? Colors.black : Colors.black54, // 첫 번째 성경은 파란색
                                          fontWeight: isFirstBible ? FontWeight.bold : FontWeight.normal, // 첫 번째 성경은 굵게
                                          fontFamily: 'Biblefont',
                                          fontSize: MediaQuery.of(context).size.width * 0.03,
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              } else {
                                return SizedBox.shrink();
                              }
                            }).toList(),
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

    final displayDate = selectedDate != null
        ? DateFormat('yyyy-MM-dd').format(selectedDate!)
        : todayString;

    return Column(
      children: [
        Stack(
          children: [
            Center(
              child: Text('끼니',
                  style: TextStyle(
                      fontFamily: 'Mealfont',
                      fontSize: MediaQuery.of(context).size.width * 0.10,
                      color: Theme.of(context).textTheme.bodyLarge?.color)),
            ),
            Positioned(
              right: 0,
              child: IconButton(
                icon: Icon(Icons.settings),
                onPressed: () {
                  // 성경 선택 화면으로 이동
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SelectBibleView()),
                  );
                },
              ),
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
                '오늘 날짜: ${viewModel.selectedDate != null ? DateFormat('yyyy-MM-dd').format(viewModel.selectedDate!) : todayString}',
                style: TextStyle(
                    fontFamily: 'Biblefont',
                    fontSize: MediaQuery.of(context).size.width * 0.035,
                    color: Theme.of(context).textTheme.bodyLarge?.color)),
            IconButton(
              icon: Icon(Icons.calendar_today),
              onPressed: onSelectDate,
            ),
          ],
        ),
        Divider(color: Colors.grey),
        Text('',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.bodyLarge?.color)),
      ],
    );
  }
}
