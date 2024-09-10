import 'package:flutter/material.dart';
import 'view/meal2_view.dart';

void main() { runApp(MyApp());}

  class MyApp extends StatelessWidget {
    @override
    Widget build(BuildContext context) {
      return MaterialApp(
        title: 'Meal App',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: Meal2View(), // Import한 뷰를 메인 화면으로 설정합니다.
      );
    }
  }