import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photo_town/widgets/id_input.dart';
import 'package:photo_town/widgets/pw_input.dart';
import 'package:photo_town/widgets/terms_checkbox.dart';

class SignupDetailScreen extends StatefulWidget {
  const SignupDetailScreen({super.key});

  @override
  State<SignupDetailScreen> createState() => _SignupDetailScreenState();
}

class _SignupDetailScreenState extends State<SignupDetailScreen> {
  final TextEditingController idController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController passwordConfirmController =
      TextEditingController();
  final TextEditingController nicknameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController authCodeController = TextEditingController();

  bool isAllAgreed = false; // 전체 이용 동의
  bool isAgreeTerms = false; // 이용 약관 동의 (필수)
  bool isAgreePrivacy = false; // 개인정보 수집 및 이용 동의
  bool isAgreeMarketing = false; // 개인정보 마케팅 활용 동의 (선택)
  bool isAgreeSmsEmail = false; // SMS 및 이메일 수신 동의 (선택)

  String? idErrorText;
  bool isIdValid = false;

  String? passwordErrorText;
  String? passwordConfirmErrorText;

  bool get isSignupEnabled {
    // 조건
    // 1. 아이디가 유효해야 하고 (idErrorText == null)
    // 2. 아이디가 비어있지 않고
    // 3. 비밀번호, 비밀번호 확인, 이메일, 휴대폰 번호 등 모두 입력되어 있고
    // 4. 필수 약관 동의가 모두 체크되어야 함

    return idErrorText == null &&
        idController.text.isNotEmpty &&
        passwordController.text.isNotEmpty &&
        passwordConfirmController.text.isNotEmpty &&
        emailController.text.isNotEmpty &&
        phoneController.text.isNotEmpty &&
        isAgreeTerms &&
        isAgreePrivacy;
  }

  @override
  void dispose() {
    idController.dispose();
    passwordController.dispose();
    passwordConfirmController.dispose();
    nicknameController.dispose();
    phoneController.dispose();
    authCodeController.dispose();
    super.dispose();
  }

  // 전체 이용 동의
  void _toggleAllAgree(bool? checked) {
    if (checked == null) return;
    setState(() {
      isAllAgreed = checked;
      isAgreeTerms = checked;
      isAgreePrivacy = checked;
      isAgreeMarketing = checked;
      isAgreeSmsEmail = checked;
    });
  }

  void _toggleAgreeTerms(bool? checked) {
    if (checked == null) return;
    setState(() {
      isAgreeTerms = checked;
      _updateAllAgree();
    });
  }

  void _toggleAgreePrivacy(bool? checked) {
    if (checked == null) return;
    setState(() {
      isAgreePrivacy = checked;
      _updateAllAgree();
    });
  }

  // 마케팅 활용 동의 토글 함수
  void _toggleAgreeMarketing() {
    setState(() {
      isAgreeMarketing = !isAgreeMarketing;
      _updateAllAgree();
    });
  }

  // SMS/이메일 동의 토글 함수
  void _toggleAgreeSmsEmail() {
    setState(() {
      isAgreeSmsEmail = !isAgreeSmsEmail;
      _updateAllAgree();
    });
  }

  void _updateAllAgree() {
    isAllAgreed =
        isAgreeTerms && isAgreePrivacy && isAgreeMarketing && isAgreeSmsEmail;
  }

  void _validateId(String value) {
    String? error;
    final RegExp startsWithNumber = RegExp(r'^[0-9]');
    final RegExp allowed = RegExp(r'^[a-zA-Z][a-zA-Z0-9]*$');

    if (value.isEmpty) {
      error = "아이디를 입력해주세요.";
    } else if (startsWithNumber.hasMatch(value)) {
      error = "아이디는 영문자로 시작해야 합니다.";
    } else if (!allowed.hasMatch(value)) {
      error = "영문과 숫자만 사용할 수 있습니다.";
    } else if (value.length < 6) {
      error = "아이디는 최소 6자 이상이어야 합니다.";
    } else if (value.length > 20) {
      error = "아이디는 최대 20자까지 가능합니다.";
    } else {
      error = null;
    }

    setState(() {
      idErrorText = error;
      isIdValid = error == null;
    });
  }

  void _validatePassword(String value) {
    String? error;
    final RegExp startsWithNumber = RegExp(r'^[0-9]');
    final RegExp allowedChars = RegExp(r'^[a-zA-Z0-9!*#]+$'); // ! * #

    if (value.isEmpty) {
      error = '비밀번호를 입력해주세요.';
    } else if (startsWithNumber.hasMatch(value)) {
      error = '비밀번호는 숫자로 시작할 수 없습니다.';
    } else if (!allowedChars.hasMatch(value)) {
      error = '특수 문자는 ! * # 만 허용됩니다.';
    } else if (value.length < 8) {
      error = '비밀번호는 최소 8자 이상이어야 합니다.';
    } else if (value.length > 20) {
      error = '비밀번호는 최대 20자까지만 가능합니다.';
    } else {
      error = null;
    }

    setState(() {
      passwordErrorText = error;
    });
  }

  void _validatePasswordConfirm(String value) {
    String? error;

    if (value.isEmpty) {
      error = '비밀번호를 다시 입력해주세요.';
    } else if (value != passwordController.text) {
      error = '비밀번호가 일치하지 않습니다.';
    } else {
      error = null;
    }

    setState(() {
      passwordConfirmErrorText = error;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 앱바 구별을 위해 색상 변경
      backgroundColor: Colors.white, // 앱 전체 배경색
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0, // 그림자 없애기
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        centerTitle: true,
        title: const Text(
          "회원가입",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 32.0,
              vertical: 20.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),

                // 아이디
                IdInputWidget(
                  idController: idController,
                  idErrorText: idErrorText,
                  onChanged: _validateId,
                  onCheckDuplicate: () {
                    // TODO: 중복 확인 API 호출 또는 유효성 검사
                    print("아이디 중복 확인: ${idController.text}");
                  },
                ),

                const SizedBox(height: 16),

                // 비밀번호 입력
                PwInputWidget(
                  passwordController: passwordController,
                  passwordConfirmController: passwordConfirmController,
                  passwordErrorText: passwordErrorText,
                  passwordConfirmErrorText: passwordConfirmErrorText,
                  onPasswordChanged: _validatePassword,
                  onPasswordConfirmChanged: _validatePasswordConfirm,
                ),

                const SizedBox(height: 16),

                // 휴대폰 번호 입력 + 인증번호 버튼 가로 배치
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 48, // 텍스트필드 높이 고정
                        child: TextField(
                          controller: phoneController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: '휴대폰 번호 입력',
                            hintStyle: const TextStyle(
                              color: Color.fromARGB(255, 128, 128, 128),
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(4),
                              borderSide: const BorderSide(
                                color: Color.fromARGB(255, 192, 192, 192),
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 12,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(4),
                              borderSide: const BorderSide(
                                color: Colors.black,
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      height: 48, // 버튼 높이 고정
                      child: ElevatedButton(
                        onPressed: () {
                          // 인증번호 받기 로직
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFFDBEFC4),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          "인증 번호",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // 인증번호 입력 + 인증확인 버튼 가로 배치
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: TextField(
                          controller: authCodeController,
                          decoration: InputDecoration(
                            hintText: '인증번호 입력',
                            hintStyle: const TextStyle(
                              color: Color.fromARGB(255, 128, 128, 128),
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(4),
                              borderSide: const BorderSide(
                                color: Color.fromARGB(255, 192, 192, 192),
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 12,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(4),
                              borderSide: const BorderSide(
                                color: Colors.black,
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      height: 48, // 버튼 높이 고정
                      child: ElevatedButton(
                        onPressed: () {
                          // 인증 확인 로직
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFFDBEFC4),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          // side: BorderSide.none,
                          elevation: 0,
                        ),

                        child: const Text(
                          "인증 확인",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // 이메일 입력
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: '이메일 입력',
                    hintStyle: const TextStyle(
                      color: Color.fromARGB(255, 128, 128, 128),
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: const BorderSide(
                        color: Color.fromARGB(255, 192, 192, 192),
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 12,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: const BorderSide(
                        color: Colors.black,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // 약관 동의 체크박스
                TermsCheckboxWidget(
                  isAllAgreed: isAllAgreed,
                  isAgreeTerms: isAgreeTerms,
                  isAgreePrivacy: isAgreePrivacy,
                  isAgreeMarketing: isAgreeMarketing,
                  isAgreeSmsEmail: isAgreeSmsEmail,
                  onAllAgreeTap: () => _toggleAllAgree(!isAllAgreed),
                  onTermsTap: () => _toggleAgreeTerms(!isAgreeTerms),
                  onPrivacyTap: () => _toggleAgreePrivacy(!isAgreePrivacy),
                  onMarketingTap: _toggleAgreeMarketing,
                  onSmsEmailTap: _toggleAgreeSmsEmail,
                ),

                const SizedBox(height: 32),

                // 가입하기 버튼
                ElevatedButton(
                  onPressed: () {
                    _validateId(idController.text);

                    if (idErrorText != null) {
                      // 에러 있으면 스낵바 등으로 알려주기
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(idErrorText!)));
                      return; // 가입 중단
                    }

                    if (!isAgreeTerms || !isAgreePrivacy) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('필수 약관에 동의해 주세요.')),
                      );
                      return;
                    }

                    // 가입하기 로직
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isSignupEnabled
                        ? const Color(0xFFDBEFC4) // 입력 완료
                        : const Color(0xFFE0E0E0), // 입력 미완료
                    foregroundColor: isSignupEnabled
                        ? Colors.black
                        : const Color.fromARGB(255, 82, 82, 82),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    "가입하기",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
