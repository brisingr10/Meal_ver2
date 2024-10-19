import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:meal_ver2/viewmodel/MainViewModel.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'view/MainView.dart'; // MainView import
import 'view/SelectBibleView.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Flutter 엔진 초기화
  await Firebase.initializeApp(); // Firebase 초기화
  print('Initializing SharedPreferences...');

  try {
    // SharedPreferences를 미리 로드
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    print('SharedPreferences initialized successfully.');

    print("Loaded Theme Index: ${sharedPreferences.getInt('themeIndex')}");
    runApp(
      ChangeNotifierProvider(
        create: (context) => MainViewModel(sharedPreferences),
        // MainViewModel을 앱 전체에서 한 번만 생성
        child: MyApp(),
      ),
    );
  } catch (e) {
    print('Error initializing SharedPreferences: $e');
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<MainViewModel>(
      builder: (context, viewModel, child) {
        return MaterialApp(
          // 여기에서 getThemeMode()를 호출하여 themeMode 설정
          themeMode: viewModel.getThemeMode(),
          home: Meal2View(),
        );
      },
    );
  }
}