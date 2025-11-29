import 'package:flutter/material.dart';
import 'package:health_care/presentation/home/home.dart';
import 'package:health_care/presentation/login/register.dart';
import 'package:health_care/feature/user/user_client.dart';
import 'package:health_care/presentation/style/colors.dart';
import 'package:health_care/presentation/login/sleeping_pattern.dart';
import 'package:dio/dio.dart';
import 'package:health_care/presentation/food/camera.dart';
import 'dart:convert';


class LoginPage extends StatelessWidget {
  final TextEditingController _userIDController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final String baseUrl;

  LoginPage({super.key, required this.baseUrl});

  void _showSnackBar(BuildContext context, String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _login(BuildContext context) async {
  final userID = _userIDController.text.trim();
  final password = _passwordController.text.trim();
  
  if (userID.isEmpty || password.isEmpty) {
    _showSnackBar(context, 'ID와 비밀번호를 입력해주세요.', isError: true);
    return;
  }

  try {
    final dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),
    ));
    
    print('Login 요청 전송: $baseUrl/login');
    print('요청 데이터: user_id=$userID, password=***');
    
    final response = await UserRepo(dio, baseUrl: baseUrl).login({
      'user_id': userID,
      'password': password,
    });
    
    print('응답 상태 코드: ${response.response.statusCode}');
    print('응답 데이터: ${response.data}');
    print('응답 데이터 타입: ${response.data.runtimeType}');

    // ============================
    //    200 OK 처리
    // ============================
    if (response.response.statusCode == 200) {

  dynamic raw = response.data;

  // --------------------------------------
  // 1) 응답이 String(JSON) → Map으로 변환
  // --------------------------------------
  if (raw is String) {
    try {
      raw = jsonDecode(raw);
    } catch (e) {
      _showSnackBar(context, 'JSON 파싱 실패: $e', isError: true);
      return;
    }
  }

  // --------------------------------------
  // 2) Map인지 확인
  // --------------------------------------
  if (raw is! Map<String, dynamic>) {
    _showSnackBar(context, '잘못된 응답 형식입니다.', isError: true);
    return;
  }

  final map = raw;

  // data 유효성 검사
  if (map['data'] is! Map<String, dynamic>) {
    _showSnackBar(context, '응답 데이터(data)가 올바르지 않습니다.', isError: true);
    return;
  }

  final data = map['data'] as Map<String, dynamic>;
  final accessToken = data['accessToken'];
  final refreshToken = data['refreshToken'];
  final grantType = data['grantType'];

  if (accessToken == null) {
    _showSnackBar(context, '로그인 실패: accessToken 없음', isError: true);
    return;
  }

  _showSnackBar(context, '로그인 성공!', isError: false);

  // sleeping_pattern 처리
  if (data.containsKey('sleeping_pattern')) {
    final sleeping = data['sleeping_pattern'];

    if (sleeping == true) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomePage(baseUrl: baseUrl, jwt: accessToken),
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => SleepingPatternPage(baseUrl: baseUrl, jwt: accessToken),
        ),
      );
    }
  }

   Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => SleepingPatternPage(baseUrl: baseUrl, jwt: accessToken),
        ),
      );
      
    return;
    
  // -----------------------
  // camera test (유지)
  // -----------------------
  /*
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: (context) => CameraPage(baseUrl: baseUrl, jwt: accessToken),
    ),
  );
  */
    } else {
      _showSnackBar(context, '로그인 실패: 알 수 없는 오류가 발생했습니다.', isError: true);
    }

  } on DioException catch (e) {
    print('DioException 발생: ${e.type}');
    print('에러 메시지: ${e.message}');
    print('응답 상태: ${e.response?.statusCode}');
    print('응답 데이터: ${e.response?.data}');
  } catch (e, stackTrace) {
    print('예상치 못한 오류: $e');
    print('스택 트레이스: $stackTrace');
    _showSnackBar(context, '예상치 못한 오류: $e', isError: true);
  }
}


  void _register(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RegisterPage(baseUrl: baseUrl),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar 삭제 또는 변경 (이미지에는 AppBar가 보이지 않거나 타이틀만 있음)
      appBar: AppBar(
        title: const Text(
          "로그인",
          style: TextStyle(
            color: blackColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: whiteColor,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ID 입력 필드
            TextField(
              controller: _userIDController,
              decoration: const InputDecoration(
                labelText: '아이디',
                border: OutlineInputBorder(), 
                contentPadding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
              ),
            ),
            const SizedBox(height: 16),
            // 비밀번호 입력 필드
            TextField(
              controller: _passwordController,
              obscureText: true, // 비밀번호 가리기
              decoration: const InputDecoration(
                labelText: '비밀번호',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
              ),
            ),
            const SizedBox(height: 24), // 간격 조정
            
            // 1. 로그인 버튼 (배경: 검은색, 텍스트: 흰색)
            ElevatedButton(
              onPressed: () => _login(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: blackColor, // 배경색 검은색
                foregroundColor: whiteColor, // 텍스트 색상 흰색
                minimumSize: const Size(double.infinity, 50), // 버튼 높이 설정 및 폭 최대화
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(4)), // 모서리 둥글기 제거 또는 조정
                ),
                elevation: 0, // 그림자 제거
              ),
              child: const Text(
                '로그인',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),
            
            // 2. 회원가입 버튼 (배경: 흰색, 테두리: 검은색, 텍스트: 검은색)
            ElevatedButton(
              onPressed: () => _register(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: whiteColor, // 배경색 흰색
                foregroundColor: blackColor, // 텍스트 색상 검은색
                minimumSize: const Size(double.infinity, 50), // 버튼 높이 설정 및 폭 최대화
                shape: RoundedRectangleBorder(
                  borderRadius: const BorderRadius.all(Radius.circular(4)),
                  side: BorderSide(color: blackColor, width: 1), // 검은색 테두리 추가
                ),
                elevation: 0, // 그림자 제거
              ),
              child: const Text(
                '회원가입',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}