import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io'; // 파일 업로드를 위해 필요
import 'package:firebase_auth/firebase_auth.dart';

class FireBaseFunction{
  static Future<void> signInAnonymously() async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance.signInAnonymously();
      print("Signed in with temporary account.");
    } catch (e) {
      print("Failed to sign in anonymously: $e");
    }
  }

  static Future<void> uploadFile(File file) async {
    try {
      FirebaseStorage storage = FirebaseStorage.instance;

      // 파일 경로 지정
      String filePath = 'uploads/${DateTime.now().millisecondsSinceEpoch}.png';

      // Firebase Storage에 파일 업로드
      await storage.ref(filePath).putFile(file);
      print('File uploaded successfully.');
    } catch (e) {
      print('Failed to upload file: $e');
    }
  }

  static Future<String> downloadFile() async {
    try {
      // Firebase Storage에서 파일 URL 가져오기
      String downloadURL = await FirebaseStorage.instance
          .ref('db.json') // 업로드된 파일 경로
          .getDownloadURL();

      print('Download URL: $downloadURL');
      return downloadURL;
      // 다운로드 URL을 사용하여 파일을 읽거나 보여줄 수 있습니다.
      // 예: Image.network(downloadURL);
    } catch (e) {
      print('Error downloading file: $e');
      return 'Error downloading file: $e';
    }
  }
}