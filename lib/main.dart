import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:meal_ver2/util/CustomTheme.dart';
import 'package:meal_ver2/viewmodel/CustomThemeMode.dart';
import 'package:provider/provider.dart';
import 'package:meal_ver2/viewmodel/MainViewModel.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'view/MainView.dart'; // MainView import
import 'view/SelectBibleView.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'view/OptionView.dart';
import 'firebase_options.dart'; // Firebase 옵션 파일이 있어야 합니다.

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Flutter 엔진 초기화
  try {
    final results = await Future.wait([
      Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform),
      SharedPreferences.getInstance(),
    ]);
    final SharedPreferences sharedPreferences = results[1] as SharedPreferences;
    await initializeDateFormatting('ko_KR', null); // 로케일 초기화
    // SharedPreferences를 미리 로드
    //SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    //print('SharedPreferences initialized successfully.');

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
    return
      //Consumer<MainViewModel>(
      //builder: (context, mode, child) {
      ValueListenableBuilder<ThemeMode>(
          valueListenable: MainViewModel.themeMode,
          builder: (context, themeMode, child) {
            return MaterialApp(

              darkTheme: CustomThemeData.dark,
              theme: CustomThemeData.light,
              themeMode: themeMode,
              locale: Locale('ko', 'KR'), // 한국어 설정
              supportedLocales: [
                Locale('en', 'US'),
                Locale('ko', 'KR'), // 한국어 추가
              ],
              localizationsDelegates: [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              home: Meal2View(),
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaleFactor: 1.0,
                ),
                child: child!,
              ),
              //home: OptionView(),
            );
          });
    //);
    //}
  }
}