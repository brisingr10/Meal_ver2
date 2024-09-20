import 'package:shared_preferences/shared_preferences.dart';

class PreferenceUtil{
  static final PreferenceUtil _instance = PreferenceUtil._internal();

  factory PreferenceUtil(){
    return _instance;
  }

  PreferenceUtil._internal();

  Future<SharedPreferences> get _prefs async{
    return await SharedPreferences.getInstance();
  }

  Future<String?> getstring(String key, String defValue) async{
    final prefs = await _prefs;
    return prefs.getString(key) ?? defValue;
  }

  Future<void> setString(String key, String value) async {
    final prefs = await _prefs;
    await prefs.setString(key, value);
  }
}