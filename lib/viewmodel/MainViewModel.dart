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
  static ValueNotifier<ThemeMode> _themeMode =  ValueNotifier(ThemeMode.light);
  static ValueNotifier<ThemeMode> get themeMode => _themeMode;
  late SharedPreferences _SharedPreferences;
  List<Plan> PlanList = [];
  Bible? _Bible;
  late Plan? TodayPlan = Plan();
  List<List<Verse>> DataSource = [];
  DateTime? SelectedDate;
  bool _IsBibleLoaded = false;
  bool _IsLoading = true;
  List<String> SelectedBibles = [];


  bool get IsLoading => this._IsLoading;

  MainViewModel(SharedPreferences sharedPreferences) {
    _SharedPreferences = sharedPreferences;
    //deleteMealPlan();
    FireBaseFunction.signInAnonymously();
    loadPreferences();
  }

  Future<bool> loadPreferences() async {
    try {
      this._IsLoading = true;
      notifyListeners();

      _SharedPreferences = await SharedPreferences.getInstance();

      if (!this._IsBibleLoaded) {
        await _configBible();
      }

      if (this._Bible != null && this._Bible!.books.isNotEmpty) {
        this.TodayPlan = getTodayPlan();
        _updateTodayPlan();
      }
      return true;
    } catch (e) {
      print('Error loading preferences: $e');
      return false;
    } finally {
      this._IsLoading = false;
      notifyListeners();
    }
  }

  void setSelectedBibles(List<String> bibles) {
    this.SelectedBibles = bibles;
    notifyListeners();
  }

  Future<void> refreshVersesForDate(DateTime? date) async {
    this.SelectedDate = date;
    this.TodayPlan = getTodayPlan();
    _updateTodayPlan();
    await loadMultipleBibles(this.SelectedBibles); // 선택된 성경만 새로 로드
  }

  Future<bool> deleteMealPlan() async {
    try {
      await _SharedPreferences.remove('mealPlan');
      this.PlanList.clear();
      notifyListeners();
      return true;
    } catch (e) {
      print('Error deleting meal plan: $e');
      return false;
    }
  }

  Future<bool> _configBible() async {
    try {
      this._Bible = await _loadBibleFile('lib/repository/bib_json/개역개정.json');
      if (this._Bible != null) {
        this._IsBibleLoaded = true;
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
    this.DataSource.clear();
    this.TodayPlan = getTodayPlan();
    _updateTodayPlan();
    setSelectedBibles(bibleFiles);
    if(bibleFiles.length > 1 )
    {this.DataSource.clear();
    for (String bibleFile in bibleFiles) {
      Bible? loadedBible = await _loadBibleFile(
          'lib/repository/bib_json/$bibleFile.json');
      if (loadedBible != null) {
        List<Verse> versesInPlanRange = loadedBible.books.where((book) =>
        book.book == this.TodayPlan?.book && ((book.chapter > this.TodayPlan!.fChap! && book.chapter < this.TodayPlan!.lChap!) || ((book.chapter == this.TodayPlan!.fChap! && book.verse >= this.TodayPlan!.fVer!) && (book.chapter == this.TodayPlan!.lChap! && book.verse <= this.TodayPlan!.lVer!)))).map((book) =>
            Verse(
                book: book.book,
                btext: book.btext,
                fullName: book.fullName,
                chapter: book.chapter,
                id: book.id,
                verse: book.verse)).toList();
        this.DataSource.add(versesInPlanRange);
      } else {
        print('Error loading Bible file: $bibleFile');
      }
    }
    }
    notifyListeners();
  }
  void toggleTheme() {
    _themeMode.value = _themeMode.value == ThemeMode.light
        ? ThemeMode.dark
        : ThemeMode.light;
    notifyListeners();
  }

  List<Plan>? _readSavedMealPlan() {
    String mealPlanStr = _SharedPreferences.getString("mealPlan") ?? "";
    if (mealPlanStr.isNotEmpty) {
      List<dynamic> decodedPlans = jsonDecode(mealPlanStr);
      return decodedPlans.map((plan) => Plan.fromJson(plan)).toList();
    }
    else
        _getMealPlan();

    return null;
  }

  void setSelectedDate(DateTime? date) {
    this.SelectedDate = date;
    this.TodayPlan = getTodayPlan();
    _updateTodayPlan();
    loadMultipleBibles(this.SelectedBibles); // 선택된 성경으로 데이터를 다시 로드
    notifyListeners();
  }

  Plan? getTodayPlan() {
    var plan = Plan();
    if (this._Bible == null || this._Bible!.books.isEmpty) return null;
    Plan? checkedPlan = _existTodayPlan();
    if (checkedPlan != null && this.TodayPlan != checkedPlan) {
      return plan = checkedPlan;
      //_updateTodayPlan();
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
    this._IsLoading = true;
    notifyListeners();

    try {
      String downLoadURL = await FireBaseFunction.downloadFile();
      final response = await http.get(Uri.parse(downLoadURL));
      if (response.statusCode == 200) {
        String decodedResponse = utf8.decode(response.bodyBytes);
        List<dynamic> planListJson = jsonDecode(decodedResponse)['mealPlan'];
        List<Plan> newPlanList =
        planListJson.map((plan) => Plan.fromJson(plan)).toList();

        if (!listEquals(newPlanList, this.PlanList)) {
          this.PlanList = newPlanList;
          _saveMealPlan();
          _getPlanData();
        }
      }
    } catch (e) {
      print("Error fetching meal plan: $e");
    } finally {
      this._IsLoading = false;
      notifyListeners();
    }
  }

  Future<void> selectLoad() async {
    if (!this._IsBibleLoaded) {
      await _configBible();
    }
    List<String> savedBibles = _SharedPreferences.getStringList('selectedBibles') ?? [];
    if (savedBibles.isNotEmpty) {
      await loadMultipleBibles(savedBibles);
    }
    if (this._Bible != null && this._Bible!.books.isNotEmpty) {
      this.TodayPlan = getTodayPlan();
      _updateTodayPlan();
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
    String jsonString = jsonEncode(this.PlanList);
    _SharedPreferences.setString("mealPlan", jsonString);
  }

  void _getPlanData() {
    String today = this.SelectedDate != null
        ? DateFormat('yyyy-MM-dd').format(this.SelectedDate!)
        : Globals.todayString();

    try {
      TodayPlan = this.PlanList.firstWhere((plan) => plan.day == today);
      _updateTodayPlan();
    } catch (e) {
      print("Error: No plan found for the selected date.");
    }
  }

  void _updateTodayPlan() {
    if (this._Bible == null || this._Bible!.books.isEmpty) return;
    // todayPlan의 fullName 설정
    final matchingBook = this._Bible!.books.firstWhere(
          (book) => book.book == this.TodayPlan?.book,
      orElse: () => Book(book: '',btext: '', fullName: '',chapter: 0, id: 0, verse: 0),
    );

    if (matchingBook.fullName.isNotEmpty) {
      this.TodayPlan?.fullName = matchingBook.fullName;
    }


    List<Verse> versesInRange = this._Bible!.books.where((book) =>
    book.book == this.TodayPlan?.book &&
        ((book.chapter > this.TodayPlan!.fChap! && book.chapter < this.TodayPlan!.lChap!) ||
            ((book.chapter == this.TodayPlan!.fChap! && book.verse >= this.TodayPlan!.fVer!) &&
            (book.chapter == this.TodayPlan!.lChap! && book.verse <= this.TodayPlan!.lVer!))
        )
    ).map((book) => Verse(
      id: book.id,
      book: book.book,
      chapter: book.chapter,
      fullName: book.fullName,
      verse: book.verse,
      btext: book.btext,
    )).toList();

    this.DataSource.clear();
    this.DataSource.add(versesInRange);

    print("DataSource updated with verses for ${this.TodayPlan!.book} ${this.TodayPlan!.fullName} ${this.TodayPlan!.fChap}:${this.TodayPlan!.fVer} - ${this.TodayPlan!.lChap}:${this.TodayPlan!.lVer}");
    notifyListeners();
  }

  int? _getTodayIndex(List<Plan> planList) {
    final selectedOrToday = this.SelectedDate != null
        ? DateTime(this.SelectedDate!.year, this.SelectedDate!.month, this.SelectedDate!.day)
        : DateTime.now();
    return planList.indexWhere(
            (plan) => DateTime.parse(plan.day!).difference(selectedOrToday).inDays == 0);
  }
}
