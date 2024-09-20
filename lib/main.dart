import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:meal_ver2/viewmodel/MainViewModel.dart';
import 'MainActivity.dart'; // MainActivity를 정의한 파일을 가져오기

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => MainViewModel(),
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<MainViewModel>(
      builder: (context, viewModel, child) {
        return MaterialApp(
          // 여기에서 getThemeMode()를 호출하여 themeMode 설정
          themeMode: viewModel.getThemeMode(),
          home: MainActivity(),
        );
      },
    );
  }
}