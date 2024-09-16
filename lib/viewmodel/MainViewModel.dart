import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  Bible? bible;
  late Plan todayPlan;
  Book? todayBook;
  late PlanData planData;
  String today="";
  String todayDescription = "";
  List<Verse> dataSource = [];
  List<bool> checkBoxList = [false, false, false];
  String scheduleDate = "";

  MainViewModel(){
    loadPreferences();
  }

  // SharedPreferences 로드
  Future<void> loadPreferences() async {
    _sharedPreferences = await SharedPreferences.getInstance();
    themeIndex = _sharedPreferences.getInt('themeIndex') ?? 0;

    await _configBible();

    // 성경이 제대로 로드되었다면 getTodayPlan을 호출
    if (bible != null && bible!.books.isNotEmpty) {
      getTodayPlan();
    }
  }

  Future<void> _configBible() async {
    try {
      // JSON 파일을 로드 (Flutter에서는 rootBundle을 사용하여 파일 읽기)
      String bibleJsonString = await rootBundle.loadString('lib/repository/bib_json/개역개정.json');

      // JSON 데이터를 파싱하여 Bible 객체로 변환
      final jsonData = jsonDecode(bibleJsonString) as List<dynamic>;
      bible = Bible.fromJson(jsonData);

      // bible이 올바르게 로드되었는지 확인
      if (bible != null && bible!.books.isNotEmpty) {
        print('Bible data loaded successfully');
      } else {
        print('Error: Bible data is empty');
      }

      // 초기화 작업
      planList = [];
      todayPlan = Plan();
      planData = PlanData();
      dataSource = [];

    } catch (e) {
      print('Error loading Bible data: $e');
    }
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
    if (bible == null || bible!.books.isEmpty) {
      print('Error: Bible has not been loaded or is empty.');
      return;
    }

    Plan? checkedPlan = _existTodayPlan();

    // 상태가 변경되었을 때만 업데이트 및 알림
    if (checkedPlan != null && todayPlan != checkedPlan) {
      todayPlan = checkedPlan;
      print("exist todayPlan: ${todayPlan.toString()}");
      _updateTodayPlan();

    } else if (checkedPlan == null) {
      print("Meal plan has not changed, skipping update.");
      _getMealPlan();  // API에서 meal plan을 가져오도록 함
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
        List<Plan> newPlanList = planListJson.map((plan) => Plan.fromJson(plan)).toList();

        // 새로운 planList와 기존의 planList가 다를 때만 업데이트
        if (!listEquals(newPlanList, planList)) {
          planList = newPlanList;
          _saveMealPlan();
          _getPlanData();
          // 상태가 변경될 때만 알림
          notifyListeners();
        } else {
          print("Meal plan has not changed, skipping update.");
        }
      }
    } catch (e) {
      print("Error fetching meal plan: $e");
    }
  }

// 리스트 비교 함수: 리스트가 같을 경우에는 상태 업데이트 방지
  bool listEquals<T>(List<T> list1, List<T> list2) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (list1[i] != list2[i]) return false;
    }
    return true;
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
    if (bible == null || bible!.books.isEmpty) {
      print('Error: Bible has not been loaded or is empty.');
      return;
    }
    // todayPlan.book의 값과 bible.books의 책 목록을 로그로 출력
    print('todayPlan.book: ${todayPlan.book}');
    //print('bible.books: ${bible!.books.map((book) => book.btext).toList()}');

    // todayBook을 bible 목록에서 찾기
    todayBook = bible!.books.firstWhere(
          (book) => book.book == todayPlan.book,
      orElse: () => Book(book: '', btext: '', chapter: 0, verse: 0, id: 0),
    );

    // todayBook이 제대로 초기화되었는지 확인
    if (todayBook!.book.isEmpty) {
      print("Error: todayBook could not be found in bible.books.");
      return;
    }
    // 오늘의 성경 구절 설명 설정
    todayDescription = "${todayPlan.book} ${todayPlan.fChap}:${todayPlan.fVer} - ${todayPlan.lChap}:${todayPlan.lVer}";

    // 날짜 업데이트
    scheduleDate = Globals.convertStringToDate(todayPlan.day!).toString();

    // 성경 구절 업데이트 (성경 데이터를 기반으로 구절을 업데이트하는 부분)
    List<String> verseList = [];
    List<int> verseNumList = [];
    int startChapterIndex = todayPlan.fChap!;
    int startVerse = todayPlan.fVer!;
    int endChapterIndex = todayPlan.lChap!;
    int endVerse = todayPlan.lVer!;

    // 시작 장과 끝 장이 같은 경우
    if (startChapterIndex == endChapterIndex) {
      // 장과 구절에 해당하는 Book 객체 찾기
      final chapterVerses = bible!.books.where((book) =>
      book.book == todayPlan.book &&
          book.chapter == startChapterIndex
      ).toList();

      // 구절을 추출하여 verseList에 추가
      verseList = chapterVerses
          .where((book) => book.verse >= startVerse && book.verse <= endVerse)
          .map((book) => book.btext)
          .toList();

      // 구절 번호 업데이트
      verseNumList = chapterVerses
          .where((book) => book.verse >= startVerse && book.verse <= endVerse)
          .map((book) => book.verse)
          .toList();

    }else {
      // 시작 장과 끝 장이 다른 경우
      for (int chapterIndex = startChapterIndex; chapterIndex <= endChapterIndex; chapterIndex++) {
        // 각 장에 해당하는 구절들을 찾기
        final chapterVerses = bible!.books.where((book) =>
        book.book == todayPlan.book &&
            book.chapter == chapterIndex
        ).toList();

        int sliceStartIndex = (chapterIndex == startChapterIndex) ? startVerse : 1;
        int sliceEndIndex = (chapterIndex == endChapterIndex) ? endVerse : chapterVerses.length;

        // 구절을 verseList와 verseNumList에 추가
        verseList.addAll(chapterVerses
            .where((book) => book.verse >= sliceStartIndex && book.verse <= sliceEndIndex)
            .map((book) => book.btext));

        verseNumList.addAll(chapterVerses
            .where((book) => book.verse >= sliceStartIndex && book.verse <= sliceEndIndex)
            .map((book) => book.verse));
      }
    }

    // 구절 리스트를 데이터 소스로 설정
    List<Verse> oldDataSource = List.from(dataSource);
    dataSource = List<Verse>.generate(verseList.length, (index) {
      return Verse(
        id: verseNumList[index],
        book: todayPlan.book ?? 'Unknown', // 오늘의 책을 할당
        chapter: startChapterIndex, // 해당 장을 할당
        verse: verseNumList[index], // 구절 번호를 할당
        btext: verseList[index], // 구절 텍스트를 할당
      );
    });
  for(var i in dataSource)
    {
      print(i.btext.toString());
    }
  }

  // 오늘의 인덱스 가져오기
  int? _getTodayIndex(List<Plan> planList) {
    today = Globals.todayString();
    for (int i = 0; i < planList.length; i++) {
      if (planList[i].day == today) {
        return i;
      }
    }
    return null;
  }
}