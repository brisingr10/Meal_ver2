import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../model/PlanData.dart';
import '../model/bible.dart';
import '../util//Globals.Dart';
import '../network/plan.dart';
import '../model/Verse.dart';

class MainViewModel extends ChangeNotifier {
  late SharedPreferences _sharedPreferences;
  int themeIndex = 0;
  List<Plan> planList = [];
  late Bible bible;
  late Plan todayPlan;
  late Book todaybook;
  late PlanData planData;
  String todayDescription = "";
  List<Verse> dataSource = [];
  List<bool> checkBoxList = [false, false, false];
  String scheduleDate = "";

  MainViewModel(){
    _loadPreferences();
  }

  // SharedPreferences 로드
  Future<void> _loadPreferences() async {
    _sharedPreferences = await SharedPreferences.getInstance();
    themeIndex = _sharedPreferences.getInt('themeIndex') ?? 0;
    getTodayPlan();
    notifyListeners();
  }

  // 테마 변경
  void changeTheme(int index) {
    themeIndex = index;
    _sharedPreferences.setInt('themeIndex', themeIndex);
    notifyListeners();
  }

  // 테마 설정 반환
  ThemeMode getThemeMode() {
    switch (themeIndex) {
      case 0:
        return ThemeMode.light;
      case 1:
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  // JSON 문자열로 저장된 meal plan 불러오기
  List<Plan>? _readSavedMealPlan() {
    String mealPlanStr = _sharedPreferences.getString("mealPlan") ?? "";

    if (mealPlanStr.isNotEmpty) {
      List<dynamic> decodedPlans = jsonDecode(mealPlanStr);
      return decodedPlans.map((plan) => Plan.fromJson(plan)).toList();
    }
    return null;
  }

  // 오늘의 계획 불러오기
  void getTodayPlan() {
    Plan? checkedPlan = _existTodayPlan();

    if (checkedPlan != null) {
      todayPlan = checkedPlan;
      print("exist todayPlan: ${todayPlan.toString()}");
      _updateTodayPlan();
    } else {
      _getMealPlan();
    }
  }

  Plan? _existTodayPlan() {
    List<Plan>? mealPlan = _readSavedMealPlan();
    int? todayIndex = _getTodayIndex(mealPlan ?? []);

    if (mealPlan != null && todayIndex != null) {
      return mealPlan[todayIndex];
    }
    return null;
  }

  // API로부터 meal plan 받아오기
  Future<void> _getMealPlan() async {
    try {
      final response = await http.get(Uri.parse("http://10.0.2.2:3000/mealPlan"));
      if (response.statusCode == 200) {
        List<dynamic> planListJson = jsonDecode(response.body);
        planList = planListJson.map((plan) => Plan.fromJson(plan)).toList();
        _saveMealPlan();
        _getPlanData();
      }
    } catch (e) {
      print("Error fetching meal plan: $e");
    }
  }

  // meal plan 저장
  void _saveMealPlan() {
    String jsonString = jsonEncode(planList);
    _sharedPreferences.setString("mealPlan", jsonString);
  }

  // 오늘의 계획 데이터 처리
  void _getPlanData() {
    String today = Globals.todayString();
    todayPlan = planList.firstWhere((plan) => plan.day == today);
    print("downloaded todayPlan: $todayPlan");
    _updateTodayPlan();
  }

  // 오늘의 계획 업데이트
  void _updateTodayPlan() {
    todayDescription = "${todayPlan.book} ${todayPlan.fChap}:${todayPlan.fVer} - ${todayPlan.lChap}:${todayPlan.lVer}";

    // 날짜 업데이트
    scheduleDate = Globals.convertStringToDate(todayPlan.day!).toString();
    notifyListeners();
  }

  // 오늘의 인덱스 가져오기
  int? _getTodayIndex(List<Plan> planList) {
    String todayString = Globals.todayString();
    for (int i = 0; i < planList.length; i++) {
      if (planList[i].day == todayString) {
        return i;
      }
    }
    return null;
  }
}