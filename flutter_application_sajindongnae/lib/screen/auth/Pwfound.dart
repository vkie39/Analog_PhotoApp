import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_sajindongnae/screen/auth/widgets/phone_auth.dart';
// import 'pw_reset.dart';

class PwfoundScreen extends StatefulWidget {
  const PwfoundScreen({super.key});

  @override
  State<PwfoundScreen> createState() => _PwfoundScreenState();
}

class _PwfoundScreenState extends State<PwfoundScreen> {
  final TextEditingController idController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController authCodeController = TextEditingController();

  String? idErrorText;
  String? phoneErrorText;
  String? authCodeErrorText;

  bool isAuthConfirmed = false;
  bool isLoading = false;

  bool get isAuthCodeEntered => authCodeController.text.length == 6;
  bool get isNextEnabled => isAuthConfirmed && !isLoading;

  @override
  void initState() {
    super.initState();
    authCodeController.addListener(() {
      setState(() {}); // 6자리 입력 여부에 따라 버튼 색상/활성화 업데이트
    });
  }

  @override
  void dispose() {
    idController.dispose();
    phoneController.dispose();
    authCodeController.dispose();
    super.dispose();
  }

  void requestAuthCode() {
    FocusScope.of(context).unfocus();
    _validateId(idController.text);
    _validatePhone(phoneController.text);
    // 실제로는 백엔드 API 호출
  }

  void _validateId(String value) {
    if (value.trim().isEmpty) {
      idErrorText = "아이디를 입력해주세요.";
    } else {
      idErrorText = null;
    }
    setState(() {});
  }

  void _validatePhone(String value) {
    String digitsOnly = value.replaceAll(RegExp(r'\D'), '').trim();
    if (digitsOnly.isEmpty) {
      phoneErrorText = '휴대폰 번호를 입력해주세요.';
    } else if (!RegExp(r'^(010|011)\d{8}$').hasMatch(digitsOnly)) {
      phoneErrorText = '올바른 번호 형식을 입력해주세요.';
    } else {
      phoneErrorText = null;
    }
    setState(() {});
  }

  Future<void> confirmAuthCode() async {
    FocusScope.of(context).unfocus();
    _validateId(idController.text);
    _validatePhone(phoneController.text);

    setState(() => isLoading = true);

    await Future.delayed(const Duration(seconds: 1)); // 백엔드 호출이 없어서 if문으로 대충 실행함
    if (authCodeController.text == "123456") {
      isAuthConfirmed = true;
      authCodeErrorText = null;
    } else {
      isAuthConfirmed = false;
      authCodeErrorText = '인증번호가 올바르지 않습니다.';
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              const Text(
                '비밀번호를 잃어버리셨나요?',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                '아이디와 전화번호를 입력하시고 [다음] 버튼을 클릭하세요.',
                style: TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 24),

              // 아이디 입력
              TextField(
                controller: idController,
                style: const TextStyle(
                  color: Colors.black, // 입력 후 글씨 색
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
                decoration: InputDecoration(
                  hintText: "아이디 입력",
                  hintStyle: const TextStyle(
                    color: Color.fromARGB(255, 128, 128, 128), // 입력 전(힌트) 글씨 색
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                  errorText: idErrorText,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: BorderSide(
                      color: idErrorText == null
                          ? const Color.fromARGB(255, 192, 192, 192) // 정상일 때 연회색
                          : Colors.red, // 에러일 때 빨강
                      width: 1,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: BorderSide(
                      color: idErrorText == null
                          ? Colors.black // 포커스 시 검정
                          : Colors.red, // 에러일 때 빨강
                      width: 1.5,
                    ),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),

              const SizedBox(height: 16),

              // 전화번호 입력
              PhoneAuthWidget(
                phoneController: phoneController,
                phoneErrorText: phoneErrorText,
                onRequestAuthCode: requestAuthCode,
              ),
              const SizedBox(height: 16),

              // 인증번호 입력 + 버튼
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        SizedBox(
                          height: 48,
                          child: TextField(
                            controller: authCodeController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(6),
                            ],
                            decoration: InputDecoration(
                              hintText: '인증번호 입력',
                              hintStyle: const TextStyle(
                                color: Color.fromARGB(255, 128, 128, 128),
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(4),
                                borderSide: BorderSide(
                                  color: authCodeErrorText != null
                                      ? Colors.red
                                      : const Color(0xFFC0C0C0),
                                  width: 1.0,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(4),
                                borderSide: const BorderSide(
                                  color: Colors.black,
                                  width: 1.5,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 12,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        SizedBox(
                          height: 16, // 항상 공간 확보
                          width: double.infinity,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                            authCodeErrorText ?? '', // 없으면 빈 문자열
                            style: const TextStyle(color: Colors.red, fontSize: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    height: 48,
                    width: 88,
                    child: ElevatedButton(
                      onPressed: isAuthCodeEntered && !isLoading
                          ? confirmAuthCode
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isAuthCodeEntered
                            ? const Color(0xFFDBEFC4)
                            : const Color(0xFFE0E0E0),
                        foregroundColor: isAuthCodeEntered
                            ? Colors.black
                            : const Color.fromARGB(255, 82, 82, 82),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        elevation: 0,
                      ),
                      child: isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text(
                              "인증 확인",
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              // 다음 버튼 → 비밀번호 재설정 화면으로 이동
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: isNextEnabled
                      ? () {
                          // Navigator.push(context, MaterialPageRoute(
                          //   builder: (_) => const PwResetScreen(),
                          // ));
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDBEFC4),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4)),
                    elevation: 0,
                  ),
                  child: const Text(
                    "다음",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 전화번호 하이픈 자동 포맷터
class PhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digitsOnly = newValue.text.replaceAll(RegExp(r'\D'), '');
    String formatted = '';
    if (digitsOnly.length <= 3) {
      formatted = digitsOnly;
    } else if (digitsOnly.length <= 7) {
      formatted = '${digitsOnly.substring(0, 3)}-${digitsOnly.substring(3)}';
    } else if (digitsOnly.length <= 11) {
      formatted =
          '${digitsOnly.substring(0, 3)}-${digitsOnly.substring(3, 7)}-${digitsOnly.substring(7)}';
    } else {
      formatted =
          '${digitsOnly.substring(0, 3)}-${digitsOnly.substring(3, 7)}-${digitsOnly.substring(7, 11)}';
    }
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

