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
    '공동번역' : false,
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

    // 초기화: ViewModel에서 가져온 데이터를 반영
    for (String bible in viewModel.SelectedBibles) {
      if (selectedBibles.containsKey(bible) && !selectedOrder.contains(bible)) {
        selectedBibles[bible] = true;
        selectedOrder.add(bible);
      }
    }

    // 화면 내 모든 성경을 selectedBibles에 포함
    selectedBibles.forEach((key, value) {
      if (value == true && !selectedOrder.contains(key)) {
        selectedOrder.add(key);
      }
    });

  }

  void _addBible() {
    showDialog(
      context: context,
      builder: (context) {
        List<String> availableBibles = selectedBibles.entries
            .where((entry) => entry.value == false) // value가 true인 항목만 필터링
            .map((entry) => entry.key)            // key만 추출
            .toList();
        return AlertDialog(
          title: Text("추가할 성경 선택"),
          content:SizedBox(
        width: 400,  // 너비 제한 추가
          child : ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: 300, // 최대 높이 제한
              minWidth: 300,  // 최소 너비 제한
              maxWidth: 400,  // 최대 너비 제한 추가
            ),

          child: availableBibles.isNotEmpty
              ? ListView.builder(
            shrinkWrap: true,
            itemCount: availableBibles.length,
            itemBuilder: (context, index) {
              String bible = availableBibles[index];
              return ListTile(
                title: Text(bible),
                onTap: () {
                  setState(() {
                    selectedBibles[bible] = true;
                    selectedOrder.add(bible);
                  });
                  Navigator.pop(context);
                },
              );
            },
          )
              : Text("추가 가능한 성경이 없습니다."),
        ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("닫기"),
            ),
          ],
        );
      },
    );
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
            actions: [
              IconButton(
                icon: Icon(Icons.add),
                onPressed: _addBible,
              ),
            ],
          ),
              body: Column(
                children: [
                  Expanded(
                    child: ReorderableListView(
                      onReorder: (int oldIndex, int newIndex) {
                        setState(() {
                          if (newIndex > oldIndex) newIndex--;
                          final String movedBible = selectedOrder.removeAt(oldIndex);
                          selectedOrder.insert(newIndex, movedBible);
                        });
                      },
              children: selectedOrder.map((String bible) {
                return Dismissible(
                  key: ValueKey(bible),
                  direction: DismissDirection.endToStart,
                  onDismissed: (direction) {
                    setState(() {
                      selectedOrder.remove(bible);
                      selectedBibles.remove(bible);
                    });
                  },
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: EdgeInsets.only(right: 20),
                    child: Icon(Icons.delete, color: Colors.white),
                  ),
                  child: ListTile(
                    title: Text(
                      bible,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    trailing: Icon(Icons.list, color: Theme.of(context).colorScheme.primary), // 항상 List 아이콘 표시
                    // `onTap` 제거
                  ),
                );
              }).toList(),
            ),
                  ),
                      // children: selectedBibles.keys.map((String bible) {
                      //   int orderIndex = selectedOrder.indexOf(bible) + 1;
                      //   return ListTile(
                      //     key: ValueKey(bible), // 고유 키 설정
                          // leading: CircleAvatar(
                          //   backgroundColor: (selectedBibles[bible] ?? false)
                          //       ? Theme.of(context).colorScheme.primary
                          //       : Colors.grey[300],
                          //   child: Text(
                          //     (selectedBibles[bible] ?? false) ? '$orderIndex' : '',
                          //     style: TextStyle(
                          //       color: (selectedBibles[bible] ?? false) ? Colors.white : Colors.black,
                          //     ),
                          //   ),
                          // ),
                    //       title: Text(
                    //         bible,
                    //         style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    //           color: themeMode == ThemeMode.dark ? Colors.white : Colors.black,
                    //         ),
                    //       ),
                    //       trailing: selectedBibles[bible] == true
                    //           ? Icon(
                    //         Icons.check,
                    //         color: Theme.of(context).colorScheme.primary,
                    //       )
                    //           : null, // 선택된 경우 체크 아이콘 표시
                    //       onTap: () {
                    //         setState(() {
                    //           if (selectedBibles[bible] ?? false) {
                    //             selectedBibles[bible] = false;
                    //             selectedOrder.remove(bible);
                    //           } else {
                    //             selectedBibles[bible] = true;
                    //             selectedOrder.add(bible);
                    //           }
                    //         });
                    //       },
                    //     );
                    //   }).toList(),
                    // ),
                  //),
                  // Expanded(
                  //   child: ListView(
                  //     children: selectedBibles.keys.map((String bible) {
                  //       int orderIndex = selectedOrder.indexOf(bible) + 1;
                  //       return
                  //         ListTile(
                  //         leading: CircleAvatar(
                  //           backgroundColor: (selectedBibles[bible] ?? false)
                  //               ? Theme.of(context).colorScheme.primary
                  //               : Colors.grey[300],
                  //           child: Text(
                  //             (selectedBibles[bible] ?? false) ? '$orderIndex' : '',
                  //             style: TextStyle(
                  //               color: (selectedBibles[bible] ?? false) ? Colors.white : Colors.black,
                  //             ),
                  //           ),
                  //         ),
                  //         title: Text(
                  //           bible,
                  //           style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  //             color: themeMode == ThemeMode.dark
                  //                 ? Colors.white
                  //                 : Colors.black,
                  //           ),
                  //         ),
                  //         onTap: () {
                  //           setState(() {
                  //             if (selectedBibles[bible] ?? false) {
                  //               selectedBibles[bible] = false;
                  //               selectedOrder.remove(bible);
                  //             } else {
                  //               selectedBibles[bible] = true;
                  //               selectedOrder.add(bible);
                  //             }
                  //           });
                  //         },
                  //       );
                  //     }
                  //     ).toList(),
                  //   ),
                  // ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  onPressed: selectedOrder.isNotEmpty ? () {
                    viewModel.loadMultipleBibles(selectedOrder);
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
