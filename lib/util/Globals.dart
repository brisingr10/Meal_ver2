import 'package:intl/intl.dart';

class Globals {
  static const String APP_SERVER_URL = "";

  static const List<String> requiredPermissions = [
    "android.permission.INTERNET",
    "android.permission.ACCESS_NETWORK_STATE"
  ];

  // 오늘 날짜를 "yyyy-MM-dd" 형식으로 변환
  static String todayString(){
    DateFormat formatter = DateFormat('yyyy-MM-dd');
    String current = formatter.format(DateTime.now());
    print("today: $current");
    return current;
  }

  // "yyyy-MM-dd" 형식의 문자열을 DateTime으로 변환
  static DateTime convertStringToDate(String dateString) {
    DateFormat formatter = DateFormat('yyyy-MM-dd');
    return formatter.parse(dateString);
  }

  // LocalDate를 "MM/dd, E요일" 형식으로 변환하여 반환
  static String headerDateString(DateTime date) {
    DateFormat formatter = DateFormat('MM/dd, EEEE', 'ko'); // 한국어 요일
    String dateString = formatter.format(date);
    print("dateString: $dateString");
    return dateString;
  }
}