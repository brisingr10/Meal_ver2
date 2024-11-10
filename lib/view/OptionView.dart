import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:meal_ver2/viewmodel/MainViewModel.dart';

import '../viewmodel/CustomThemeMode.dart';
import 'SelectBibleView.dart';

class OptionView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold();
  }

  void showTransparentWindow(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Option View",
      barrierColor: Colors.black.withOpacity(0.0),
      // 배경 투명 처리
      transitionDuration: Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return TransparentWindow();
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return FadeTransition(
          opacity: anim1,
          child: child,
        );
      },
    );
  }
}

class TransparentWindow extends StatelessWidget {
  Future<void> _selectDate(BuildContext context, MainViewModel viewModel) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: viewModel.selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2024, 12, 31),
    );
    if (pickedDate != null) {
      viewModel.setSelectedDate(pickedDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<MainViewModel>(context, listen: false);

    return Scaffold(
        backgroundColor: Colors.transparent,

        body: GestureDetector(
          onTap: () {
            Navigator.of(context).pop(); // OptionView 닫기
          },
          onPanUpdate: (_) {
            Navigator.of(context).pop(); // OptionView 스크롤 시 닫기
          },

          child:Column(

            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Header
              Container(

                padding: EdgeInsets.all(16.0),
                color: Colors.blue.withOpacity(1),
                child: Center(

                  child: Text(
                    '끼니',
                    style: TextStyle(
                      fontFamily: 'Mealfont',
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              // 중간 영역은 비어 있도록 설정하여 MainView의 화면이 그대로 보이게 함
              Expanded(child: Container(color: Colors.transparent)),
              // Bottom
              Container(

                padding: EdgeInsets.all(16.0),
                color: Colors.white.withOpacity(0.8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    // 테마 선택 버튼
                    ValueListenableBuilder<ThemeMode>(
                      valueListenable: MainViewModel.themeMode,
                      builder: (BuildContext context, ThemeMode value, Widget? child) {
                        return IconButton(
                          onPressed: () {
                            HapticFeedback.mediumImpact();
                            viewModel.toggleTheme();
                          },
                          icon: Icon(
                            value == ThemeMode.light ? Icons.light_mode : Icons.dark_mode,
                          ),
                        );
                      },
                    ),
                    // 날짜 선택 버튼
                    IconButton(
                      icon: Icon(Icons.calendar_today),
                        onPressed: () {_selectDate(context, viewModel);},
                    ),
                    // 성경 선택 버튼
                    IconButton(
                      icon: Icon(Icons.menu_book),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => SelectBibleView()),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ));
  }
}

// class SelectBibleView extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     // 성경 선택을 위한 View 구현
//     return Scaffold(
//       appBar: AppBar(
//         title: Text("Select Bible"),
//       ),
//       body: Center(
//         child: Text("성경 선택 화면"),
//       ),
//     );
//   }
// }
