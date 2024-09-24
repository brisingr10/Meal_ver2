import 'package:flutter/material.dart';
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
  ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadData();

    _scrollController.addListener(() {
      if (_scrollController.position.atEdge &&
          _scrollController.position.pixels != 0) {
        _refreshData();
      }
    });
  }

  Future<void> _loadData() async {
    try {
      final viewModel = Provider.of<MainViewModel>(context, listen: false);
      await viewModel.loadPreferences(); // 초기화 작업을 한 번만 실행
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
      final viewModel = Provider.of<MainViewModel>(context, listen: false);
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

    @override
    void dispose() {
      _scrollController.dispose();
      super.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<MainViewModel>(context, listen: false);

    if (isLoading) {
      // 로딩 중일 때 로딩 인디케이터 표시
      return Scaffold(
        appBar: AppBar(title: Text('Meal Plan')),
        body: Center(child: CircularProgressIndicator()),
      );
    } else if (errorMessage.isNotEmpty) {
      // 오류 발생 시 오류 메시지 표시
      return Scaffold(
        appBar: AppBar(title: Text('Meal Plan')),
        body: Center(child: Text(errorMessage)),
      );
    }

    // 데이터 로딩이 완료된 경우 실제 화면 표시
    return Scaffold(
      //appBar: AppBar(
      //title: Text('Meal Plan'),
      // ),
      body: Container(
        color: Theme.of(context).colorScheme.background,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Header(),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refreshData,
                  child: ListView.builder(
                    controller: _scrollController, // 스크롤 컨트롤러 연결
                    itemCount: viewModel.dataSource.length,
                    itemBuilder: (context, index) {
                      final verse = viewModel.dataSource[index];
                      final subverse = viewModel.subdataSource[index];
                      return ListTile(
                        title: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${verse.verse}절',
                                style: TextStyle(
                                    fontFamily: 'Biblefont',
                                    fontSize:
                                        MediaQuery.of(context).size.width *
                                            0.04)),
                            Text(verse.btext,
                                style: TextStyle(
                                    fontFamily: 'Biblefont',
                                    fontSize:
                                        MediaQuery.of(context).size.width *
                                            0.04)),
                            Text(subverse.btext,
                                style: TextStyle(
                                    fontFamily: 'Biblefont',
                                    fontSize:
                                        MediaQuery.of(context).size.width *
                                            0.035)),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<MainViewModel>(context);

    return Column(
      children: [
        Stack(
          children: [
            Center(
              child: Text('끼니',
                  style: TextStyle(
                      fontFamily: 'Mealfont',
                      fontSize: MediaQuery.of(context).size.width * 0.10,
                      color: Theme.of(context).textTheme.bodyLarge?.color)
              ),
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
            Text('오늘 날짜: ${viewModel.today}',
                style: TextStyle(
                    fontFamily: 'Biblefont',
                    fontSize: MediaQuery.of(context).size.width * 0.035,
                    color: Theme.of(context).textTheme.bodyLarge?.color)),
            IconButton(
              icon: Icon(Icons.calendar_today),
              onPressed: () {
                // 캘린더 기능 구현
              },
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
