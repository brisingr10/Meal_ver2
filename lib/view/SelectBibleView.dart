import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:meal_ver2/viewmodel/MainViewModel.dart';

class SelectBibleView extends StatefulWidget {
  @override
  _SelectBibleViewState createState() => _SelectBibleViewState();
}

class _SelectBibleViewState extends State<SelectBibleView> {
  // 선택 상태를 저장하는 변수
  Map<String, bool> selectedBibles = {
    '개역개정': true,
    '개역한글': false,
    '새번역': false,
    'ESV': false,
    'NIV': false,
  };

  ThemeMode? selectedTheme;

  @override
  void initState() {
    super.initState();
    final viewModel = Provider.of<MainViewModel>(context, listen: false);
    selectedTheme = ThemeMode.system; // 초기 테마 설정
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<MainViewModel>(context, listen: false);


    return Scaffold(
      appBar: AppBar(
        title: Text("Select Bibles"),
      ),
      body: Column(
        children: [
          // // 테마 선택 드롭다운
          // Padding(
          //   padding: const EdgeInsets.all(16.0),
          //   child: Row(
          //     children: [
          //       Text('Theme: '),
          //       SizedBox(width: 16),
          //       DropdownButton<ThemeMode>(
          //         value: selectedTheme,
          //         items: [
          //           DropdownMenuItem(
          //             child: Text('System Default'),
          //             value: ThemeMode.system,
          //           ),
          //           DropdownMenuItem(
          //             child: Text('Light'),
          //             value: ThemeMode.light,
          //           ),
          //           DropdownMenuItem(
          //             child: Text('Dark'),
          //             value: ThemeMode.dark,
          //           ),
          //         ],
          //         onChanged: (ThemeMode? value) {
          //           setState(() {
          //             selectedTheme = value;
          //           });
          //           if (value != null) {
          //             viewModel.getThemeMode(value); // MainViewModel에 선택된 테마 전달
          //           }
          //         },
          //       ),
          //     ],
          //   ),
          // ),
          Expanded(
            child: ListView(
              children: selectedBibles.keys.map((String bible) {
                return CheckboxListTile(
                  title: Text(bible),
                  value: selectedBibles[bible],
                  onChanged: (bool? value) {
                    setState(() {
                      selectedBibles[bible] = value ?? false;  // 체크박스 상태 업데이트
                    });
                  },
                );
              }).toList(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () {
                // 선택된 파일들만 리스트로 필터링
                List<String> selectedFiles = selectedBibles.entries
                    .where((entry) => entry.value)  // 선택된 파일들만 필터링
                    .map((entry) => entry.key)
                    .toList();

                // 선택한 성경 파일들을 MainViewModel로 넘기고 처리
                viewModel.loadMultipleBibles(selectedFiles);

                // 창 종료
                Navigator.pop(context);
              },
              child: Text('완료'),
            ),
          ),
        ],
      ),
    );
  }
}