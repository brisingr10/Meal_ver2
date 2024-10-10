import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
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
  Bible? subbible;
  late Plan todayPlan;
  Book? todayBook;
  Book? subtodayBook;
  late PlanData planData;
  String today = "";
  String todayDescription = "";
  DateTime? selectedDate;
  List<Verse> dataSource = [];
  List<Verse> subdataSource = [];
  List<bool> checkBoxList = [false, false, false];
  String scheduleDate = "";
  bool _isBibleLoaded = false; // 플래그 추가
  bool _isLoading = true;

  bool get isLoading => _isLoading;

  MainViewModel(SharedPreferences sharedPreferences) {
    print('MainViewModel created');
    _sharedPreferences = sharedPreferences;
    loadPreferences();
  }

  // SharedPreferences 로드
  Future<void> loadPreferences() async {
    print("Loading SharedPreferences...");
    _isLoading = true;
    notifyListeners();

    try {
      //_sharedPreferences = await SharedPreferences.getInstance();
      print("SharedPreferences loaded.");
      themeIndex = _sharedPreferences.getInt('themeIndex') ?? 0;

      if (!_isBibleLoaded) {
        // 성경이 이미 로드되었는지 확인
        await _configBible();
      }

      // 성경이 제대로 로드되었다면 getTodayPlan을 호출
      if (bible != null && bible!.books.isNotEmpty) {
        getTodayPlan();
      }
    } catch (e) {
      print('Error loading preferences: $e');
    } finally {
      _isLoading = false; // 로딩 종료
      print('Finished loading preferences.'); // 로딩 완료 로그
      notifyListeners(); // UI 갱신
    }
  }

  Future<void> _configBible() async {
    if (_isBibleLoaded) return; // 이미 로드되었으면 바로 반환

    try {
      bible = await _loadBibleFile('lib/repository/bib_json/개역개정.json');
      subbible = await _loadBibleFile('lib/repository/bib_json/개역한글.json');

      if (bible != null && subbible != null) {
        _isBibleLoaded = true;
        print('Bible data loaded successfully');
      } else {
        print('Error: Bible data is empty');
      }

      planList.clear();
      todayPlan = Plan();
      planData = PlanData();
      dataSource.clear();
    } catch (e) {
      print('Error loading Bible data: $e');
    }
  }

  // 성경 파일 로드 함수
  Future<Bible?> _loadBibleFile(String path) async {
    try {
      String bibleJsonString = await rootBundle.loadString(path);
      final jsonData = jsonDecode(bibleJsonString) as List<dynamic>;
      return Bible.fromJson(jsonData);
    } catch (e) {
      print('Error loading Bible file from $path: $e');
      return null;
    }
  }

  Future<void> loadMultipleBibles(List<String> bibleFiles) async {
    try {
      bible = bibleFiles.contains('개역개정.json')
          ? await _loadBibleFile('lib/repository/bib_json/개역개정.json')
          : null;
      subbible = bibleFiles.contains('개역한글.json')
          ? await _loadBibleFile('lib/repository/bib_json/개역한글.json')
          : null;

      if (bible != null && subbible != null) {
        print('Bible data loaded successfully');
      } else {
        print('Error: Bible data is empty');
      }

      planList.clear();
      todayPlan = Plan();
      planData = PlanData();
      dataSource.clear();
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

  void setSelectedDate(DateTime? date) {
    selectedDate = date;
    getTodayPlan();
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
      _getMealPlan(); // API에서 meal plan을 가져오도록 함
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
    _isLoading = true; // 로딩 시작
    notifyListeners();

    try {
      final response = await http.get(Uri.parse("http://192.168.0.21:3000/mealPlan"));
      if (response.statusCode == 200) {
        List<dynamic> planListJson = jsonDecode(response.body);
        List<Plan> newPlanList =
            planListJson.map((plan) => Plan.fromJson(plan)).toList();

        // 새로운 planList와 기존의 planList가 다를 때만 업데이트
        if (!listEquals(newPlanList, planList)) {
          planList = newPlanList;
          _saveMealPlan();
          _getPlanData();
        } else {
          print("Meal plan has not changed, skipping update.");
        }
      }
    } catch (e) {
      print("Error fetching meal plan: $e");
    } finally {
      _isLoading = false; // 로딩 종료
      notifyListeners(); // UI 갱신
    }
  }

  // Select 로드
  Future<void> Selectload() async {
    if (!_isBibleLoaded) {
      // 성경이 이미 로드되었는지 확인하여 중복 로드 방지
      await _configBible(); // 성경 로드
    }
    List<String> savedBibles =
        _sharedPreferences.getStringList('selectedBibles') ?? [];

    // 성경 파일을 로드 (선택된 파일이 있는 경우)
    if (savedBibles.isNotEmpty) {
      await loadMultipleBibles(savedBibles); // 사용자가 선택한 성경 파일들을 로드
    }

    // 성경이 제대로 로드되었다면 getTodayPlan을 호출
    if (bible != null && bible!.books.isNotEmpty) {
      getTodayPlan();
    }
    //notifyListeners(); // 데이터 로드 후 UI에 알림
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
    String today = selectedDate != null
        ? DateFormat('yyyy-MM-dd').format(selectedDate!)
        : Globals.todayString(); // 선택한 날짜가 있으면 해당 날짜 사용

    try {
      todayPlan = planList.firstWhere((plan) => plan.day == today);
      print("downloaded todayPlan: $todayPlan");
      _updateTodayPlan();
    } catch (e) {
      print("Error: No plan found for the selected date.");
    }
  }

  // 오늘의 계획 업데이트
  void _updateTodayPlan() {
    if (bible == null ||
        bible!.books.isEmpty && subbible == null ||
        subbible!.books.isEmpty) {
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

    subtodayBook = subbible!.books.firstWhere(
      (book) => book.book == todayPlan.book,
      orElse: () => Book(book: '', btext: '', chapter: 0, verse: 0, id: 0),
    );

    // todayBook이 제대로 초기화되었는지 확인
    if (todayBook!.book.isEmpty && subtodayBook!.book.isEmpty) {
      print("Error: todayBook could not be found in bible.books.");
      return;
    }
    // 오늘의 성경 구절 설명 설정
    todayDescription =
        "${todayPlan.book} ${todayPlan.fChap}:${todayPlan.fVer} - ${todayPlan.lChap}:${todayPlan.lVer}";

    // 날짜 업데이트
    scheduleDate = Globals.convertStringToDate(todayPlan.day!).toString();

    _updateVerseList(todayPlan);
  }

  void _updateVerseList(Plan plan) {
    dataSource.clear();
    subdataSource.clear();

    List<Book> chapterVerses = _getBookChapters(bible!, plan);
    List<Book> subchapterVerses = _getBookChapters(subbible!, plan);

    dataSource = chapterVerses
        .map((book) => Verse(
            id: book.verse,
            book: plan.book ?? 'UnKnown',
            chapter: book.chapter,
            verse: book.verse,
            btext: book.btext))
        .toList();
    subdataSource = subchapterVerses
        .map((book) => Verse(
            id: book.verse,
            book: plan.book ?? 'UnKnown',
            chapter: book.chapter,
            verse: book.verse,
            btext: book.btext))
        .toList();

    dataSource.forEach((verse) => print(verse.btext));
    subdataSource.forEach((verse) => print(verse.btext));
  }

  List<Book> _getBookChapters(Bible bible, Plan plan) {
    List<Book> chapters = [];
    for (int chapterIndex = plan.fChap!;
        chapterIndex <= plan.lChap!;
        chapterIndex++) {
      int startVerse = chapterIndex == plan.fChap ? plan.fVer! : 1;
      int endVerse =
          chapterIndex == plan.lChap ? plan.lVer! : bible.books.length;
      chapters.addAll(bible.books
          .where((book) =>
              book.book == plan.book &&
              book.chapter == chapterIndex &&
              book.verse >= startVerse &&
              book.verse <= endVerse)
          .toList());
    }
    return chapters;
  }

  DateTime _stripTime(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  // 오늘의 인덱스 가져오기
  int? _getTodayIndex(List<Plan> planList) {
    final selectedOrToday = selectedDate != null
        ? _stripTime(selectedDate!)
        : _stripTime(DateTime.now());
    return planList.indexWhere(
        (plan) => _stripTime(DateTime.parse(plan.day!)) == selectedOrToday);
  }
}
