import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_application_sajindongnae/screen/auth/login.dart';
import 'signup_detail.dart';


// StatefulWidget을 상속받아 회원가입 시작 화면 정의 시작
// 버튼 등에 변화가 생겨서 수정함
class SignupStartScreen extends StatefulWidget {
  const SignupStartScreen({super.key});

  @override
  State<SignupStartScreen> createState() => _SignupStartScreenState();
}

class _SignupStartScreenState extends State<SignupStartScreen> {
  @override
  Widget build(BuildContext context) {
    // 이메일 입력을 받기 위한 컨트롤러

    return Scaffold(
      // 시스템 UI(노치 등)를 피하기 위해 SafeArea 사용함
      // SafeArea는 화면의 안전한 영역(노치, 상태바, 홈 버튼 등을 피하기) 안에서만 UI를 그려주도록 제한해주는 위젯
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          // 화면 중앙에 배치
          child: SingleChildScrollView(
            // 키보드 대응 및 오버플로 방지
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 32.0,
                vertical: 40.0,
              ), // 좌우 설정 및 상하 설정
              child: Container(
                // color: Colors.blue.withOpacity(0.2), // 컨테이너 확인용
                child: Column(
                  mainAxisSize: MainAxisSize.min, // 자식 크기만큼만 세로 공간 차지
                  crossAxisAlignment: CrossAxisAlignment.stretch, // 전체 너비 사용
                  children: [
                    const SizedBox(height: 20), // 상단 여백
                    const Text(
                      "처음 방문하셨나요?",
                      textAlign: TextAlign.center, // 센터 정렬
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                    ),

                  const SizedBox(height: 4), // 간격 설정

                  const Text(
                    "회원가입을 위해 이메일을 입력해주세요",
                    textAlign: TextAlign.center, // 센터 정렬
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
                  ),

                  const SizedBox(height: 25), // 간격 설정

                  // 이메일로 시작하기 버튼
                  OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          // signup_detail 스크린으로 변경
                          builder: (context) => const SignupDetailScreen(),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      backgroundColor: const Color(0xFFDBEFC4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      side: BorderSide.none,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // 마땅한 이미지 선택을 아직 X
                          // Image.asset(
                          //   'assets/images/.png', // png 파일 업로드
                          //   width: 20,
                          //   height: 20,
                          // ),
                          // const SizedBox(width: 12),
                          const Text(
                            "이메일로 시작하기",
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 25), // 간격 설정
                  // 소셜 로그인 구분선
                  const Row(
                    children: [
                      Expanded(child: Divider()), // 좌측 선
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text(
                          "  or  ",
                          style: TextStyle(
                            color: Color.fromARGB(255, 112, 112, 112),
                            fontWeight: FontWeight.w400,
                            fontSize: 15,
                          ),
                        ), // 가운데 텍스트
                      ),
                      Expanded(child: Divider()), // 우측 선
                    ],
                  ),

                  const SizedBox(height: 25),

                  // 구글 로그인
                  OutlinedButton(
                    onPressed: () {
                      // 구글 로그인 API 호출 처리
                    },
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      side: BorderSide(
                        color: Color.fromARGB(255, 192, 192, 192),
                      ),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min, // 콘텐츠 크기에 맞춰 정렬
                        children: [
                          // 이미지 변경하고 주석 풀 예정..
                          // Image.asset(
                          //   'assets/images/google.png',
                          //   width: 20,
                          //   height: 20,
                          // ),
                          // const SizedBox(width: 7), // 이미지와 텍스트 사이 간격
                          const Text(
                            "Google로 시작하기",
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 7),

                  // 마이크로소프트 로그인
                  OutlinedButton(
                    onPressed: () {
                      // 마이크로소프트 로그인 API 호출 처리
                    },
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      side: BorderSide(
                        color: Color.fromARGB(255, 192, 192, 192),
                      ),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Image.asset(
                          //   'assets/images/kakao.png',
                          //   width: 20,
                          //   height: 20,
                          // ),
                          // const SizedBox(width: 12),
                          const Text(
                            "Mycrosoft로 시작하기",
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // const SizedBox(height: 8),

                  // OutlinedButton(
                  //   onPressed: () {
                  //     // 네이버 로그인 API 호출 처리
                  //   },
                  //   style: OutlinedButton.styleFrom(
                  //     backgroundColor: Color(0xFF2BC622),
                  //     shape: RoundedRectangleBorder(
                  //       borderRadius: BorderRadius.circular(4),
                  //     ),
                  //     side: BorderSide.none,
                  //     elevation: 0,
                  //     padding: const EdgeInsets.symmetric(vertical: 8),
                  //   ),
                  //   child: Center(
                  //     child: Row(
                  //       mainAxisSize: MainAxisSize.min,
                  //       children: [
                  //         // 이미지 변경하고 주석 풀 예정..
                  //         // Image.asset(
                  //         //   'assets/images/naver.jpg',
                  //         //   width: 30,
                  //         //   height: 30,
                  //         // ),
                  //         // const SizedBox(width: 12),
                  //         const Text(
                  //           "네이버로 시작하기",
                  //           style: TextStyle(
                  //             color: Colors.white,
                  //             fontWeight: FontWeight.w600,
                  //           ),
                  //         ),
                  //       ],
                  //     ),
                  //   ),
                  // ),

                  const SizedBox(height: 20), // 간격 설정
                  // 계정이 이미 있는 사용자 등.. 로그인 화면으로 이동
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color.fromARGB(
                          255,
                          128,
                          128,
                          128,
                        ), // "이미 회원이신가요?" 스타일
                        fontWeight: FontWeight.w300,
                      ),
                      children: [
                        const TextSpan(text: "이미 회원이신가요? "),
                        TextSpan(
                          text: " 로그인하기",
                          style: const TextStyle(
                            color: Colors.black, // 로그인하기는 강조
                            fontWeight: FontWeight.w500,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              // 로그인 이동 로직 설정
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const LoginScreen(),
                                ),
                              );
                            },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 90), // 간격 설정
                  // 비회원 로그인 또는 건너뛰기 버튼 (작업 진행 X) -> 메인 화면
                  GestureDetector(
                    onTap: () {
                      // 비회원으로 진입
                    },
                    behavior: HitTestBehavior.translucent, // 텍스트 외에는 터치 무시
                    child: const Text(
                      "건너뛰기",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: Color.fromARGB(255, 185, 185, 185),
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
