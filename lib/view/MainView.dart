import 'package:flutter/material.dart';
import 'package:meal_ver2/viewmodel/MainViewModel.dart';
import 'package:provider/provider.dart';

class Meal2View extends StatefulWidget {
  @override
  _Meal2ViewState createState() => _Meal2ViewState();
}

class _Meal2ViewState extends State<Meal2View> {
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadData();
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
      appBar: AppBar(
        title: Text('Meal Plan'),
      ),
      body: Container(
        color: Theme.of(context).colorScheme.background,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Header(),
              Expanded(
                child: ListView.builder(
                  itemCount: viewModel.dataSource.length,
                  itemBuilder: (context, index) {
                    final verse = viewModel.dataSource[index];
                    return ListTile(
                      title: Text(verse.btext),
                      subtitle: Text('Chapter ${verse.chapter}, Verse ${verse.verse}'),
                    );
                  },
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
        Text('끼니', style: TextStyle(fontFamily: 'Myfont',fontSize: 80, color: Theme.of(context).textTheme.bodyLarge?.color)),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Today Info: ${viewModel.today}', style: TextStyle(fontSize: 16, color: Theme.of(context).textTheme.bodyLarge?.color)),
            IconButton(
              icon: Icon(Icons.calendar_today),
              onPressed: () {
                // 캘린더 기능 구현
              },
            ),
          ],
        ),
        Divider(color: Colors.grey),
        Text('Additional Info', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color)),
      ],
    );
  }
}