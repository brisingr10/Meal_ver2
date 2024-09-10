import 'dart:convert';  // JSON 처리
import 'package:http/http.dart' as http;
import 'Plan.dart';  // Plan 모델

class MealApi {
  static const String baseUrl = "http://localhost:3000/readingPlan";  // 서버 URL

  // mealPlan 데이터를 가져오는 함수
  Future<List<Plan>> getMealPlan() async {
    final response = await http.get(Uri.parse("$baseUrl/mealPlan"));

    if (response.statusCode == 200) {
      List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData.map((json) => Plan.fromJson(json)).toList();
    } else {
      throw Exception("Failed to load meal plans");
    }
  }
}