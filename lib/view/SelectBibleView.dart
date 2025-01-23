import 'dart:collection';

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

    Map<String, bool> updatedSelectedBibles = LinkedHashMap();

    // ViewModel의 SelectedBibles 순서대로 selectedBibles 업데이트
    for (String bible in viewModel.SelectedBibles) {
      if (selectedBibles.containsKey(bible)) {
        updatedSelectedBibles[bible] = selectedBibles[bible] ?? false;
        updatedSelectedBibles[bible] = true;
        selectedOrder.add(bible);
      }
    }

    // 이전에 없던 selectedBibles의 항목 유지 (선택되지 않은 항목 포함)
    selectedBibles.forEach((key, value) {
      if (!updatedSelectedBibles.containsKey(key)) {
        updatedSelectedBibles[key] = value;
      }
    });

    // updatedSelectedBibles를 selectedBibles로 교체
    selectedBibles = updatedSelectedBibles;

    // selectedOrder도 viewModel.SelectedBibles의 순서로 초기화
    //selectedOrder = viewModel.SelectedBibles.where((bible) => selectedBibles[bible] == true).toList();
  }

  // void _addBible() {
  //   showDialog(
  //     context: context,
  //     builder: (context) {
  //       List<String> availableBibles = selectedBibles.entries
  //           .where((entry) => entry.value == false) // value가 true인 항목만 필터링
  //           .map((entry) => entry.key)            // key만 추출
  //           .toList();
  //       return AlertDialog(
  //         title: Text("추가할 성경 선택"),
  //         content:SizedBox(
  //       width: 400,  // 너비 제한 추가
  //         child : ConstrainedBox(
  //           constraints: BoxConstraints(
  //             maxHeight: 300, // 최대 높이 제한
  //             minWidth: 300,  // 최소 너비 제한
  //             maxWidth: 400,  // 최대 너비 제한 추가
  //           ),
  //
  //         child: availableBibles.isNotEmpty
  //             ? ListView.builder(
  //           shrinkWrap: true,
  //           itemCount: availableBibles.length,
  //           itemBuilder: (context, index) {
  //             String bible = availableBibles[index];
  //             return ListTile(
  //               title: Text(bible),
  //               onTap: () {
  //                 setState(() {
  //                   selectedBibles[bible] = true;
  //                   selectedOrder.add(bible);
  //                 });
  //                 Navigator.pop(context);
  //               },
  //             );
  //           },
  //         )
  //             : Text("추가 가능한 성경이 없습니다."),
  //       ),
  //         ),
  //         actions: [
  //           TextButton(
  //             onPressed: () {
  //               Navigator.pop(context);
  //             },
  //             child: Text("닫기"),
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }

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
              TextButton(
                onPressed: selectedOrder.isNotEmpty
                    ? () {
                  viewModel.loadMultipleBibles(selectedOrder);
                  Navigator.pop(context); // 화면 종료
                }
                    : null, // 선택된 항목이 없으면 버튼 비활성화
              child: Text(
                '확인',
                style: TextStyle(
                  fontSize: 16, // 글자 크기
                  color: selectedOrder.isNotEmpty
                      ? (themeMode == ThemeMode.dark ? Colors.white : Colors.black)
                      : Colors.grey, // 비활성화 상태일 때 색상 변경
                ),
              ),
              ),
            ],
          ),
              body: Column(
                children: [
                  Expanded(
                    child: ReorderableListView(
                      onReorder: (int oldIndex, int newIndex) {
                        setState(() {
                          // 체크된 항목만 리스트에서 추출
                          final checkedItems = selectedBibles.entries
                              .where((entry) => entry.value == true)
                              .map((entry) => entry.key)
                              .toList();

                          final uncheckedItems = selectedBibles.entries
                              .where((entry) => entry.value == false)
                              .map((entry) => entry.key)
                              .toList();

                          // `checkedItems` 내에서만 reorder 적용
                          if (oldIndex < checkedItems.length) { // 체크된 항목 내에서만 reorder 허용
                            final String movedBible = checkedItems.removeAt(oldIndex);
                            if (newIndex > oldIndex) newIndex--;
                            checkedItems.insert(newIndex, movedBible);
                          }

                          // 최종 순서 생성: checkedItems + uncheckedItems
                          selectedOrder = checkedItems;

                          // `selectedBibles`는 체크된 항목과 체크되지 않은 항목 모두 포함
                          final updatedBibles = LinkedHashMap<String, bool>();
                          for (final bible in selectedOrder) {
                            updatedBibles[bible] = true; // 체크된 항목
                          }
                          for (final bible in uncheckedItems) {
                            updatedBibles[bible] = false; // 체크되지 않은 항목
                          }
                          selectedBibles = updatedBibles;
                        });
                      },
                      children: selectedBibles.keys.map((String bible) {
                        final isChecked = selectedBibles[bible] ?? false;
                        return ListTile(
                          key: ValueKey(bible), // 체크되지 않은 항목은 Key를 null로 설정
                          leading: Checkbox(
                            value: isChecked,
                            onChanged: (bool? value) {
                              setState(() {
                                selectedBibles[bible] = value ?? false;
                                if (value == true) {
                                  if (!selectedOrder.contains(bible)) {
                                    selectedOrder.add(bible);
                                  }
                                } else {
                                  selectedOrder.remove(bible);
                                }
                              });
                            },
                          ),
                          title: Text(
                            bible,
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: isChecked
                                  ? (themeMode == ThemeMode.dark ? Colors.white : Colors.black)
                                  : Colors.grey, // 체크되지 않은 항목은 흐리게 표시
                            ),
                          ),
                          trailing: isChecked
                              ? ReorderableDragStartListener(
                            index: selectedOrder.indexOf(bible), // 체크된 항목만 드래그 가능
                            child: Icon(Icons.drag_handle),
                          )
                              : null, // 체크되지 않은 항목은 드래그 비활성화
                        );
                      }).toList(),
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
