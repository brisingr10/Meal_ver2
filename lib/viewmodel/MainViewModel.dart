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
import '../model/Note.dart';
import '../util/Globals.dart';
import '../network/plan.dart';
import '../model/Verse.dart';

class MainViewModel extends ChangeNotifier {
  static ValueNotifier<ThemeMode> _themeMode = ValueNotifier(ThemeMode.light);

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
  DateTime? lastViewedDate;
  bool get IsLoading => this._IsLoading;
  double _fontSize = 16.0;
  double _verseSpacing = 16.0;
  double _lineSpacing = 1.8;
  Bible? _newRevisedBible;
  Bible? _newStandardBible;
  Bible? _commonTransBible;
  Bible? _nasbBible;
  String bibleType = '';
  
  // Notes management
  Map<String, List<Note>> _notesByDate = {}; // Key: "yyyy-MM-dd"

  double get fontSize => _fontSize;
  double get verseSpacing => _verseSpacing;
  double get lineSpacing => _lineSpacing;




  MainViewModel(SharedPreferences sharedPreferences) {
    _SharedPreferences = sharedPreferences;
    //deleteMealPlan();
    FireBaseFunction.signInAnonymously();


    _initialize();

  }


  Future<void> _initialize() async{

    await loadSliderSettings();
    await loadPreferences();
    await _loadSelectedBibles();
    await loadNotes();
    await selectLoad();
    notifyListeners();
  }

  void updateFontSize(double size) async{
    _fontSize = size;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('fontSize', _fontSize);
    notifyListeners();
  }

  void updateVerseSpacing(double spacing) async{
    _verseSpacing = spacing;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('verseSpacing', _verseSpacing); // setDouble 사용
    notifyListeners();
  }

  void updateLineSpacing(double spacing) async{
    _lineSpacing = spacing;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('lineSpacing', _lineSpacing);
    notifyListeners();
  }

  Future<void> loadSliderSettings() async{
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _fontSize = prefs.getDouble('fontSize') ?? 16.0; // 기본값 16.0
    _verseSpacing = prefs.getDouble('verseSpacing') ?? 16.0; // 기본값 16.0
    _lineSpacing = prefs.getDouble('lineSpacing') ?? 1.8; //
    notifyListeners();
  }


  // 선택한 바이블을 SharedPreferences에 저장
  Future<void> saveSelectedBibles() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('selectedBibles', SelectedBibles);
  }

  // SharedPreferences에서 선택한 바이블 불러오기
  Future<void> _loadSelectedBibles() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // 첫 실행 여부 확인
    bool isFirstRun = prefs.getBool('isFirstRun') ?? true;
    await Prefinitial(isFirstRun, prefs);

    // 테마 모드 불러오기
    String? savedTheme = prefs.getString('themeMode');
    if (savedTheme != null) {
      _themeMode.value = savedTheme == 'dark' ? ThemeMode.dark : ThemeMode.light;
    }

    // 마지막 본 날짜 불러오기
    String? savedDate = prefs.getString('lastViewedDate');
    if (savedDate != null) {
      lastViewedDate = DateTime.tryParse(savedDate);
    }

    // 선택된 성경 불러오기
    this.SelectedBibles = prefs.getStringList('selectedBibles') ?? [];
    if (SelectedBibles.isEmpty) {
      // 기본값으로 "개역개정" 추가
      SelectedBibles.add("개역개정");
      await saveSelectedBibles();
    }
  }

  Future<void> Prefinitial(bool isfirstrun, SharedPreferences prefs) async
  {
    if (isfirstrun) {
      // 앱 설치 후 첫 실행 시 수행할 작업
      print('앱 최초 실행: 초기화 진행 중...');
      await performInitialSetup(prefs);

      // 'isFirstRun'을 false로 설정

    } else {
      print('앱 재실행: 초기화 필요 없음');
    }
  }

Future<void> performInitialSetup(SharedPreferences prefs) async {
  // 초기화 작업 수행
  await prefs.setStringList('selectedBibles', ['개역개정']); // 기본 성경 추가
  await prefs.setString('themeMode', 'light'); // 기본 테마 설정
  await prefs.setDouble('fontSize', 16.0); // 기본 글꼴 크기
  await prefs.setDouble('verseSpacing', 16.0); // 기본 줄 간격
  await prefs.setString('newRevisedBible', jsonEncode(_newRevisedBible!.toJson()));
  await prefs.setString('newStandardBible',  jsonEncode(_newStandardBible!.toJson()));
  await prefs.setString('commonTransBible',  jsonEncode(_commonTransBible!.toJson()));
  await prefs.setString('nasbBible',  jsonEncode(_nasbBible!.toJson()));

  await prefs.setBool('isFirstRun', false);
  print('초기 설정 완료');
}


  Future<bool> loadPreferences() async {
    try {
      this._IsLoading = true;

      await loadAllbible();
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
    }
  }

  void setSelectedBibles(List<String> bibles) {
    this.SelectedBibles = bibles;
    saveSelectedBibles(); // 선택 상태 저장
    //notifyListeners();
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
      this._Bible = await _loadBibleFile('bib_json/개역개정.json');

      if (this._Bible != null) {
        this._IsBibleLoaded = true;

        // 중복 방지 로직 추가
        if (!this.SelectedBibles.contains("개역개정")) {
          this.SelectedBibles.add("개역개정");
        }

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

  Future<void> loadAllbible() async
  {
    this._newRevisedBible = await _loadBibleFile('bib_json/개역개정.json');
    this._newStandardBible = await _loadBibleFile('bib_json/새번역.json');
    this._commonTransBible = await _loadBibleFile('bib_json/공동번역.json');
    this._nasbBible = await _loadBibleFile('bib_json/NASB.json');
  }

  Future<Bible?> _loadBibleFile(String _path) async {
    try {
      String bibleJsonString = await rootBundle.loadString(_path, cache: false); // 파일 로드
      final jsonData = jsonDecode(bibleJsonString) as List<dynamic>; // JSON 디코드
      return Bible.fromJson(jsonData); // 객체 생성 후 반환
    } catch (e) {
      print('Error loading Bible file from $_path: $e');
      return null;
    }
  }

  Future<void> loadMultipleBibles(List<String> bibleFiles) async {
    this._IsLoading = true;
    List<List<Verse>> newDataSource = [];
    try {
      // DataSource 초기화 및 현재 계획 업데이트
      this.DataSource.clear();
      setSelectedBibles(bibleFiles);

      // 중복 방지: 새로 추가된 성경만 추가
      for (String bibleFile in bibleFiles) {
        if (!this.SelectedBibles.contains(bibleFile)) {
          this.SelectedBibles.add(bibleFile);
        }
      }
      // 모든 성경 파일 로드
      await Future.forEach<String>(bibleFiles, (bibleFile) async {
        try {
          print('Current path being loaded: $bibleFile');
          Bible? loadedBible = await selectBible(bibleFile);
          this.bibleType = await getBibleType(bibleFile);

          if (loadedBible != null) {
            List<Verse> versesInPlanRange = loadedBible.books
                .where((book) =>
            book.book == this.TodayPlan?.book &&
                ((book.chapter == this.TodayPlan!.fChap! &&
                    book.chapter == this.TodayPlan!.lChap! &&
                    book.verse >= this.TodayPlan!.fVer! &&
                    book.verse <= this.TodayPlan!.lVer!) ||
                    (book.chapter > this.TodayPlan!.fChap! &&
                        book.chapter < this.TodayPlan!.lChap!) ||
                    (book.chapter == this.TodayPlan!.fChap &&
                        book.verse >= this.TodayPlan!.fVer! &&
                        this.TodayPlan!.fChap != this.TodayPlan!.lChap) ||
                    (book.chapter == this.TodayPlan!.lChap &&
                        book.verse <= this.TodayPlan!.lVer! &&
                        this.TodayPlan!.fChap != this.TodayPlan!.lChap)))
                .map((book) => Verse(
              bibleType: this.bibleType,
              book: book.book,
              btext: book.btext,
              fullName: book.fullName,
              chapter: book.chapter,
              id: book.id,
              verse: book.verse,
            )).toList();


            print('Added data for $bibleFile. Current newDataSource length: ${newDataSource.length}');
            newDataSource.add(versesInPlanRange);
          } else {
            print('Error loading Bible file: $bibleFile');
          }

        } catch (e) {
          print('Error processing Bible file $bibleFile: $e');
        }

      });

      // 모든 데이터 로드 후 DataSource에 반영
      this.DataSource = newDataSource;
      print('Finished loading all bibles. Final DataSource length: ${this.DataSource.length}');
    } finally {
      this._IsLoading = false;
      notifyListeners();
    }
  }

  Future<String> getBibleType(String bibleFile) async
  {
    switch (bibleFile){
      case "개역개정":
        return "[개역개정]";
      case "새번역":
        return "[새번역]";
      case "공동번역":
        return "[공동번역]";
      case "NASB":
        return "[NASB]";
      default:
        return "[Not Select]";
    }
  }


  Future<Bible?> selectBible(String bibleFile) async
  {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    Bible newbible;
    switch (bibleFile) {
      case "개역개정":
        String? revisedJson = prefs.getString('newRevisedBible');
        return Bible.fromJson(jsonDecode(revisedJson!));
      case "새번역":
        String? standardJson  = prefs.getString('newStandardBible');
        return Bible.fromJson(jsonDecode(standardJson!));
      case "공동번역":
        String? commonTransJson   = prefs.getString('commonTransBible');
        return Bible.fromJson(jsonDecode(commonTransJson!));
      case "NASB":
        String? nasbJson   = prefs.getString('nasbBible');
        return Bible.fromJson(jsonDecode(nasbJson!));
    }
  }


  void toggleTheme() {
    _themeMode.value =
        _themeMode.value == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    _SharedPreferences.setString('themeMode', _themeMode.value.toString().split('.').last);
    notifyListeners();
  }

  List<Plan>? _readSavedMealPlan() {
    String mealPlanStr = _SharedPreferences.getString("mealPlan") ?? "";
    if (mealPlanStr.isNotEmpty) {
      List<dynamic> decodedPlans = jsonDecode(mealPlanStr);
      return decodedPlans.map((plan) => Plan.fromJson(plan)).toList();
    } else
      _getMealPlan();

    return null;
  }

  void setSelectedDate(DateTime? date) async{
    SharedPreferences prefs = await SharedPreferences.getInstance();
    this.SelectedDate = date;
    this.TodayPlan = getTodayPlan();
    lastViewedDate = date;
    prefs.setString('lastViewedDate', this.SelectedDate.toString());
    _updateTodayPlan();
    _addDataSource();
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
    //notifyListeners();

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
      //notifyListeners();
    }
  }

  Future<void> selectLoad() async {
    try {
      // 설정된 성경이 없으면 기본값으로 "개역개정" 추가
      this.TodayPlan = getTodayPlan();
      _updateTodayPlan();
      _addDataSource();
      // 설정된 성경 로드
      await loadMultipleBibles(this.SelectedBibles);

    } catch (e) {
      print("Error during selectLoad: $e");
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

  Future<void> _updateTodayPlan() async{
    if (this._Bible == null || this._Bible!.books.isEmpty) return;
    // todayPlan의 fullName 설정
    final matchingBook = this._Bible!.books.firstWhere(
          (book) => book.book == this.TodayPlan?.book,
          orElse: () => Book(
              book: '', btext: '', fullName: '', chapter: 0, id: 0, verse: 0),
        );

    if (matchingBook.fullName.isNotEmpty) {
      this.TodayPlan?.fullName = matchingBook.fullName;
    }
  }

  Future<void> _addDataSource() async
  {
    if (this._Bible == null || this._Bible!.books.isEmpty) return;
    List<Verse> versesInRange = this._Bible!.books.where((book) =>
    book.book == this.TodayPlan?.book &&
        (// fChap와 lChap이 같은 장인 경우
            (book.chapter == this.TodayPlan!.fChap! &&
                book.chapter == this.TodayPlan!.lChap! &&
                book.verse >= this.TodayPlan!.fVer! &&
                book.verse <= this.TodayPlan!.lVer!) ||

                // fChap와 lChap이 다른 장인 경우
                (book.chapter > this.TodayPlan!.fChap! &&
                    book.chapter < this.TodayPlan!.lChap!) ||

// 시작 장인 경우: fVer 이후의 구절만 포함
                (book.chapter == this.TodayPlan!.fChap &&
                    book.verse >= this.TodayPlan!.fVer!) && this.TodayPlan!.fChap != this.TodayPlan!.lChap ||

                // 끝 장인 경우: lVer 이전의 구절만 포함
                (book.chapter == this.TodayPlan!.lChap &&
                    book.verse <= this.TodayPlan!.lVer!) && this.TodayPlan!.fChap != this.TodayPlan!.lChap
        ))
        .map((book) => Verse(
      bibleType: this.bibleType,
      id: book.id,
      book: book.book,
      chapter: book.chapter,
      fullName: book.fullName,
      verse: book.verse,
      btext: book.btext,
    ))
        .toList();

    this.DataSource.clear();
    this.DataSource.add(versesInRange);

    print(
        "DataSource updated with verses for ${this.TodayPlan!.book} ${this.TodayPlan!.fullName} ${this.TodayPlan!.fChap}:${this.TodayPlan!.fVer} - ${this.TodayPlan!.lChap}:${this.TodayPlan!.lVer}");
    //notifyListeners();
  }

  int? _getTodayIndex(List<Plan> planList) {
    final selectedOrToday = this.SelectedDate != null
        ? DateTime(this.SelectedDate!.year, this.SelectedDate!.month,
            this.SelectedDate!.day)
        : DateTime.now();
    return planList.indexWhere((plan) =>
        DateTime.parse(plan.day!).difference(selectedOrToday).inDays == 0);
  }
  
  // ==================== Notes Management Methods ====================
  
  // Load notes from SharedPreferences
  Future<void> loadNotes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notesJson = prefs.getString('userNotes');
      
      if (notesJson != null) {
        final Map<String, dynamic> decoded = json.decode(notesJson);
        _notesByDate = decoded.map((key, value) {
          final notesList = (value as List).map((noteJson) => Note.fromJson(noteJson)).toList();
          return MapEntry(key, notesList);
        });
      }
    } catch (e) {
      print('Error loading notes: $e');
      _notesByDate = {};
    }
    notifyListeners();
  }
  
  // Save notes to SharedPreferences
  Future<void> _saveNotes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notesMap = _notesByDate.map((key, value) {
        return MapEntry(key, value.map((note) => note.toJson()).toList());
      });
      final notesJson = json.encode(notesMap);
      await prefs.setString('userNotes', notesJson);
    } catch (e) {
      print('Error saving notes: $e');
    }
  }
  
  // Add a new note
  void addNote(Note note) {
    final dateKey = note.dateKey;
    if (!_notesByDate.containsKey(dateKey)) {
      _notesByDate[dateKey] = [];
    }
    _notesByDate[dateKey]!.add(note);
    _saveNotes();
    notifyListeners();
  }
  
  // Update an existing note
  void updateNote(Note updatedNote) {
    final dateKey = updatedNote.dateKey;
    if (_notesByDate.containsKey(dateKey)) {
      final index = _notesByDate[dateKey]!.indexWhere((note) => note.id == updatedNote.id);
      if (index != -1) {
        _notesByDate[dateKey]![index] = updatedNote;
        _saveNotes();
        notifyListeners();
      }
    }
  }
  
  // Delete a note
  void deleteNote(String noteId) {
    _notesByDate.forEach((dateKey, notes) {
      notes.removeWhere((note) => note.id == noteId);
    });
    // Remove empty date entries
    _notesByDate.removeWhere((key, value) => value.isEmpty);
    _saveNotes();
    notifyListeners();
  }
  
  // Get notes for a specific date
  List<Note> getNotesForDate(DateTime date) {
    final dateKey = DateFormat('yyyy-MM-dd').format(date);
    return _notesByDate[dateKey] ?? [];
  }
  
  // Check if a verse has notes
  bool hasNoteForVerse(DateTime date, VerseReference verseRef) {
    final notes = getNotesForDate(date);
    for (final note in notes) {
      for (final verse in note.selectedVerses) {
        if (verse.verseId == verseRef.verseId) {
          return true;
        }
      }
    }
    return false;
  }
  
  // Get all notes for a specific verse
  List<Note> getNotesForVerse(DateTime date, VerseReference verseRef) {
    final notes = getNotesForDate(date);
    return notes.where((note) {
      return note.selectedVerses.any((verse) => verse.verseId == verseRef.verseId);
    }).toList();
  }
  
  // Get total notes count for a date
  int getNotesCountForDate(DateTime date) {
    final dateKey = DateFormat('yyyy-MM-dd').format(date);
    return _notesByDate[dateKey]?.length ?? 0;
  }
}
