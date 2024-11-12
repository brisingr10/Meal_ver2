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
    '개역개정': false,
    '개역한글': false,
    '새번역': false,
    'ESV': false,
    'NIV': false,
  };
  int selectedCount = 0;
  List<String> selectedOrder = [];
  bool isLoading = false;
  ThemeMode? selectedTheme;

  @override
  void initState() {
    super.initState();
    // ViewModel에서 저장된 선택 상태를 가져와 Map에 반영
    final viewModel = Provider.of<MainViewModel>(context, listen: false);

    for (String bible in viewModel.SelectedBibles) {
      if (selectedBibles.containsKey(bible)) {
        selectedBibles[bible] = true;
        selectedCount++;
        selectedOrder.add(bible);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<MainViewModel>(context, listen: false);

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: MainViewModel.themeMode,
      builder: (context, themeMode, child) {
        bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
        return MaterialApp(
            themeMode: themeMode,
            theme: ThemeData.light(),
            darkTheme: ThemeData.dark(),
            home: Scaffold(
          appBar: AppBar(
            title: Text(
              "성경 버전",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: themeMode == ThemeMode.dark ? Colors.white : Colors.black,
                  ),
            ),
          ),
          body: Column(
            children: [
              Expanded(
                child: ListView(
                  children: selectedBibles.keys.map((String bible) {
                    return CheckboxListTile(
                      title: Text(
                        bible,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: themeMode == ThemeMode.dark ? Colors.white : Colors.black,
                            ),
                      ),
                      value: selectedBibles[bible],
                      onChanged: (bool? value) {
                        setState(() {
                          selectedBibles[bible] =
                              value ?? false; // 체크박스 상태 업데이트
                          selectedCount += (value ?? false)?1:-1;
                          if (value == true) {
                            selectedOrder.add(bible); // 선택하면 순서에 추가
                          } else {
                            selectedOrder.remove(bible); // 선택 해제 시 순서에서 제거
                          }
                        });
                      },
                      activeColor: Theme.of(context).colorScheme.primary,
                      checkColor: Theme.of(context).colorScheme.onPrimary,
                    );
                  }).toList(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  onPressed: selectedCount > 0 ? () {
                    // 선택된 파일들만 리스트로 필터링
                    viewModel.loadMultipleBibles(selectedOrder);
                    // 창 종료
                    Navigator.pop(context);
                  } : null,
                  child: Text(
                    '완료',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: themeMode == ThemeMode.dark ? Colors.white : Colors.black,
                        ),
                  ),
                ),
              ),
            ],
          ),
                   ),
        );
      },
    );
  }
}
