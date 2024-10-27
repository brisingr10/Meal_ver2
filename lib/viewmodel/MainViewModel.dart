import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:meal_ver2/network/FirebaseFunction.dart';
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
  //Bible? subbible;
  late Plan todayPlan = Plan();
  Book? todayBook;
  //Book? subtodayBook;
  late PlanData planData;
  String today = "";
  String todayDescription = "";
  DateTime? selectedDate;
  List<List<Verse>> dataSource = [];
  //List<Verse> subdataSource = [];
  //ist<Verse> dataSource = [];
  List<bool> checkBoxList = [false, false, false];
  String scheduleDate = "";
  bool _isBibleLoaded = false; // 플래그 추가
  bool _isLoading = true;

  bool get isLoading => _isLoading;

  MainViewModel(SharedPreferences sharedPreferences) {
    print('MainViewModel created');
    _sharedPreferences = sharedPreferences;
    //deleteMealPlan();
    FireBaseFunction.signInAnonymously();
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

  Future<void> deleteMealPlan() async {
    try {
      // "mealPlan" 키에 해당하는 데이터 삭제
      await _sharedPreferences.remove('mealPlan');
      print("Meal plan deleted successfully.");

      // 삭제 후, 기존 데이터를 비우기
      planList.clear();
      notifyListeners(); // UI 갱신을 위해 알림

    } catch (e) {
      print('Error deleting meal plan: $e');
    }
  }

  Future<void> _configBible() async {
    if (_isBibleLoaded) return; // 이미 로드되었으면 바로 반환

    try {
      bible = await _loadBibleFile('lib/repository/bib_json/개역개정.json');
      //subbible = await _loadBibleFile('lib/repository/bib_json/개역한글.json');

      if (bible != null) {
        _isBibleLoaded = true;

        dataSource.add(bible!.books.map((book) => Verse(
            book: book.book,
            btext: book.btext,
            chapter: book.chapter,
            id: book.id,
            verse: book.verse)).toList());
        print('Bible data loaded successfully');
      } else {
        print('Error: Bible data is empty');
      }

      //planList.clear();
      //todayPlan = Plan();
      //planData = PlanData();
      //dataSource.clear();
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
      dataSource.clear();  // 새로 불러올 때만 초기화
      for (String bibleFile in bibleFiles) {
        Bible? loadedBible = await _loadBibleFile('lib/repository/bib_json/$bibleFile.json');
        if (loadedBible != null) {
          List<Verse> versesInPlanRange = loadedBible.books.where((book) =>
          book.book == todayPlan.book &&
              (book.chapter > todayPlan.fChap! ||
                  book.chapter < todayPlan.lChap! ||
                  (book.chapter == todayPlan.fChap! && book.verse >= todayPlan.fVer!) ||
                  (book.chapter == todayPlan.lChap! && book.verse <= todayPlan.lVer!))
          ).map((book) => Verse(
              book: book.book,
              btext: book.btext,
              chapter: book.chapter,
              id: book.id,
              verse: book.verse
          )).toList();
          dataSource.add(versesInPlanRange);
        } else {
          print('Error loading Bible file: $bibleFile');
        }
      }
      print('DataSource loaded with ${dataSource.length} entries.');
      notifyListeners();
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
    // 필요한 경우 _existTodayPlan과 _updateTodayPlan 로직 유지
    Plan? checkedPlan = _existTodayPlan();
    if (checkedPlan != null && todayPlan != checkedPlan) {
      todayPlan = checkedPlan;
      print("exist todayPlan: ${todayPlan.toString()}");
      // 오늘의 계획을 설정한 후 dataSource를 업데이트
      _updateTodayPlan();
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
      String downLoadURL = await FireBaseFunction.downloadFile();
      final response = await http.get(Uri.parse(downLoadURL));
      if (response.statusCode == 200) {
        String decodedResponse = utf8.decode(response.bodyBytes);
        List<dynamic> planListJson = jsonDecode(decodedResponse)['mealPlan'];
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
    if (bible == null || bible!.books.isEmpty) {
      print('Error: Bible has not been loaded or is empty.');
      return;
    }

    // todayPlan 범위에 맞는 성경 구절을 dataSource에 추가
    List<Verse> versesInRange = bible!.books
        .where((book) =>
    book.book == todayPlan.book &&
        ((book.chapter > todayPlan.fChap! && book.chapter < todayPlan.lChap!) ||
            (book.chapter == todayPlan.fChap! && book.verse >= todayPlan.fVer!) ||
            (book.chapter == todayPlan.lChap! && book.verse <= todayPlan.lVer!)))
        .map((book) => Verse(
      id: book.id,
      book: book.book,
      chapter: book.chapter,
      verse: book.verse,
      btext: book.btext,
    ))
        .toList();

    dataSource.clear();
    dataSource.add(versesInRange);

    print("DataSource updated with verses for ${todayPlan.book} ${todayPlan.fChap}:${todayPlan.fVer} - ${todayPlan.lChap}:${todayPlan.lVer}");

    notifyListeners();
  }

  void _updateVerseList(Plan plan) {
    dataSource.clear();

    // 범위에 맞는 구절 찾기
    if (bible != null) {
      List<Verse> versesInRange = bible!.books
          .where((book) =>
      book.book == plan.book &&
          ((book.chapter > plan.fChap! && book.chapter < plan.lChap!) ||
              (book.chapter == plan.fChap! && book.verse >= plan.fVer!) ||
              (book.chapter == plan.lChap! && book.verse <= plan.lVer!)))
          .map((book) => Verse(
        id: book.id,
        book: book.book,
        chapter: book.chapter,
        verse: book.verse,
        btext: book.btext,
      ))
          .toList();

      dataSource.add(versesInRange);
      print("DataSource updated with verses for ${plan.book} ${plan.fChap}:${plan.fVer} - ${plan.lChap}:${plan.lVer}");
    }

    notifyListeners();
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
