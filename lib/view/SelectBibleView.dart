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
    '새번역': false,
    'NASB': false,
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
                        int orderIndex = selectedOrder.indexOf(bible) + 1;
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: (selectedBibles[bible] ?? false)
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey[300],
                            child: Text(
                              (selectedBibles[bible] ?? false) ? '$orderIndex' : '',
                              style: TextStyle(
                                color: (selectedBibles[bible] ?? false) ? Colors.white : Colors.black,
                              ),
                            ),
                          ),
                          title: Text(
                            bible,
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: themeMode == ThemeMode.dark
                                  ? Colors.white
                                  : Colors.black,
                            ),
                          ),
                          onTap: () {
                            setState(() {
                              if (selectedBibles[bible] ?? false) {
                                selectedBibles[bible] = false;
                                selectedOrder.remove(bible);
                              } else {
                                selectedBibles[bible] = true;
                                selectedOrder.add(bible);
                              }
                            });
                          },
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
