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
import '../util/Globals.Dart';
import '../network/plan.dart';
import '../model/Verse.dart';

class MainViewModel extends ChangeNotifier {
  late SharedPreferences _sharedPreferences;
  int themeIndex = 0;
  List<Plan> planList = [];
  Bible? bible;
  late Plan todayPlan = Plan();
  List<List<Verse>> dataSource = [];
  String todayDescription = "";
  DateTime? selectedDate;
  bool _isBibleLoaded = false;
  bool _isLoading = true;
  List<String> selectedBibles = [];


  bool get isLoading => _isLoading;

  MainViewModel(SharedPreferences sharedPreferences) {
    _sharedPreferences = sharedPreferences;
    //deleteMealPlan();
    FireBaseFunction.signInAnonymously();
    loadPreferences();
  }

  Future<bool> loadPreferences() async {
    try {
      _isLoading = true;
      notifyListeners();

      _sharedPreferences = await SharedPreferences.getInstance();
      themeIndex = _sharedPreferences.getInt('themeIndex') ?? 0;

      if (!_isBibleLoaded) {
        await _configBible();
      }

      if (bible != null && bible!.books.isNotEmpty) {
        getTodayPlan();
      }
      return true;
    } catch (e) {
      print('Error loading preferences: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSelectedBibles(List<String> bibles) {
    selectedBibles = bibles;
    notifyListeners();
  }

  Future<void> refreshVersesForDate(DateTime? date) async {
    selectedDate = date;
    getTodayPlan();
    await loadMultipleBibles(selectedBibles); // 선택된 성경만 새로 로드
  }

  Future<bool> deleteMealPlan() async {
    try {
      await _sharedPreferences.remove('mealPlan');
      planList.clear();
      notifyListeners();
      return true;
    } catch (e) {
      print('Error deleting meal plan: $e');
      return false;
    }
  }

  Future<bool> _configBible() async {
    try {
      bible = await _loadBibleFile('lib/repository/bib_json/개역개정.json');
      if (bible != null) {
        _isBibleLoaded = true;
        return true;
      } else {
        print('Error: Bible data is empty');
        return false;
      }
    } catch (e) {
      print('Error loading Bible data: $e');
      return false;
    }
  }

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
    getTodayPlan();
    setSelectedBibles(bibleFiles);
    dataSource.clear();

    for (String bibleFile in bibleFiles) {
      Bible? loadedBible = await _loadBibleFile('lib/repository/bib_json/$bibleFile.json');
      if (loadedBible != null) {
        List<Verse> versesInPlanRange = loadedBible.books.where((book) =>
        book.book == todayPlan.book &&
            ((book.chapter > todayPlan.fChap! && book.chapter < todayPlan.lChap!) ||
                (book.chapter == todayPlan.fChap! && book.verse >= todayPlan.fVer!) ||
                (book.chapter == todayPlan.lChap! && book.verse <= todayPlan.lVer!)
            )
        ).map((book) => Verse(
            book: book.book,
            btext: book.btext,
            fullName: book.fullName,
            chapter: book.chapter,
            id: book.id,
            verse: book.verse)).toList();
        dataSource.add(versesInPlanRange);
      } else {
        print('Error loading Bible file: $bibleFile');
      }
    }
    notifyListeners();
  }

  void changeTheme(int index) {
    themeIndex = index;
    _sharedPreferences.setInt('themeIndex', themeIndex);
    notifyListeners();
  }

  ThemeMode getThemeMode(themeIndex) {
    switch (themeIndex) {
      case ThemeMode.light:
        return ThemeMode.light;
      case ThemeMode.dark:
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  List<Plan>? _readSavedMealPlan() {
    String mealPlanStr = _sharedPreferences.getString("mealPlan") ?? "";
    if (mealPlanStr.isNotEmpty) {
      List<dynamic> decodedPlans = jsonDecode(mealPlanStr);
      return decodedPlans.map((plan) => Plan.fromJson(plan)).toList();
    }
    else
        _getMealPlan();

    return null;
  }

  void setSelectedDate(DateTime? date) {
    selectedDate = date;
    getTodayPlan();
    loadMultipleBibles(selectedBibles); // 선택된 성경으로 데이터를 다시 로드
    notifyListeners();
  }

  void getTodayPlan() {
    if (bible == null || bible!.books.isEmpty) return;
    Plan? checkedPlan = _existTodayPlan();
    if (checkedPlan != null && todayPlan != checkedPlan) {
      todayPlan = checkedPlan;
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

  Future<void> _getMealPlan() async {
    _isLoading = true;
    notifyListeners();

    try {
      String downLoadURL = await FireBaseFunction.downloadFile();
      final response = await http.get(Uri.parse(downLoadURL));
      if (response.statusCode == 200) {
        String decodedResponse = utf8.decode(response.bodyBytes);
        List<dynamic> planListJson = jsonDecode(decodedResponse)['mealPlan'];
        List<Plan> newPlanList =
        planListJson.map((plan) => Plan.fromJson(plan)).toList();

        if (!listEquals(newPlanList, planList)) {
          planList = newPlanList;
          _saveMealPlan();
          _getPlanData();
        }
      }
    } catch (e) {
      print("Error fetching meal plan: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> selectLoad() async {
    if (!_isBibleLoaded) {
      await _configBible();
    }
    List<String> savedBibles = _sharedPreferences.getStringList('selectedBibles') ?? [];
    if (savedBibles.isNotEmpty) {
      await loadMultipleBibles(savedBibles);
    }
    if (bible != null && bible!.books.isNotEmpty) {
      getTodayPlan();
    }
  }

  bool listEquals<T>(List<T> list1, List<T> list2) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (list1[i] != list2[i]) return false;
    }
    return true;
  }

  void _saveMealPlan() {
    String jsonString = jsonEncode(planList);
    _sharedPreferences.setString("mealPlan", jsonString);
  }

  void _getPlanData() {
    String today = selectedDate != null
        ? DateFormat('yyyy-MM-dd').format(selectedDate!)
        : Globals.todayString();

    try {
      todayPlan = planList.firstWhere((plan) => plan.day == today);
      _updateTodayPlan();
    } catch (e) {
      print("Error: No plan found for the selected date.");
    }
  }

  void _updateTodayPlan() {
    if (bible == null || bible!.books.isEmpty) return;
    // todayPlan의 fullName 설정
    final matchingBook = bible!.books.firstWhere(
          (book) => book.book == todayPlan.book,
      orElse: () => Book(book: '',btext: '', fullName: '',chapter: 0, id: 0, verse: 0),
    );

    if (matchingBook.fullName.isNotEmpty) {
      todayPlan.fullName = matchingBook.fullName;
    }


    List<Verse> versesInRange = bible!.books.where((book) =>
    book.book == todayPlan.book &&
        ((book.chapter > todayPlan.fChap! && book.chapter < todayPlan.lChap!) ||
            (book.chapter == todayPlan.fChap! && book.verse >= todayPlan.fVer!) ||
            (book.chapter == todayPlan.lChap! && book.verse <= todayPlan.lVer!)
        )
    ).map((book) => Verse(
      id: book.id,
      book: book.book,
      chapter: book.chapter,
      fullName: book.fullName,
      verse: book.verse,
      btext: book.btext,
    )).toList();

    dataSource.clear();
    dataSource.add(versesInRange);

    print("DataSource updated with verses for ${todayPlan.book} ${todayPlan.fullName} ${todayPlan.fChap}:${todayPlan.fVer} - ${todayPlan.lChap}:${todayPlan.lVer}");
    notifyListeners();
  }

  int? _getTodayIndex(List<Plan> planList) {
    final selectedOrToday = selectedDate != null
        ? DateTime(selectedDate!.year, selectedDate!.month, selectedDate!.day)
        : DateTime.now();
    return planList.indexWhere(
            (plan) => DateTime.parse(plan.day!).difference(selectedOrToday).inDays == 0);
  }
}
