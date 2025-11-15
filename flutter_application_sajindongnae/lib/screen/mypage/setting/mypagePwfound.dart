import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_sajindongnae/screen/auth/widgets/phone_auth.dart';
import 'package:flutter_application_sajindongnae/screen/auth/pw_reset.dart';
import 'package:flutter_application_sajindongnae/screen/mypage/setting/settings.dart';


class mpPwfoundScreen extends StatefulWidget {
  const mpPwfoundScreen({super.key});

  @override
  State<mpPwfoundScreen> createState() => _PwfoundScreenState();
}

class _PwfoundScreenState extends State<mpPwfoundScreen> {
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
      setState(() {}); // 인증번호 6자리 입력 여부 업데이트
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
    // 실제로는 백엔드 API 호출 예정
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

    await Future.delayed(const Duration(seconds: 1)); // 실제 API 대체
    if (authCodeController.text == "123456") {
      isAuthConfirmed = true;
      authCodeErrorText = null;
    } else {
      isAuthConfirmed = false;
      authCodeErrorText = '인증번호가 올바르지 않습니다.';
    }

    setState(() => isLoading = false);
  }

  // 팝업 알림창
  Future<void> _showCustomDialog(BuildContext context, String message) async {
  return showDialog(
    context: context,
    barrierDismissible: true, // 바깥 클릭 시 닫힘 여부
    builder: (BuildContext context) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8), // 팝업 모서리
        ),
        child: Container(
          width: 280, // 팝업 크기
          decoration: BoxDecoration(
            color: Colors.white, // 팝업 배경
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 닫기 버튼 (오른쪽 상단)
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 12, right: 12),
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Icon(Icons.close, color: Colors.black54),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 메시지
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.black,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 36),

              // 확인 버튼
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 132, 172, 87),
                    foregroundColor: Colors.white,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(8),
                        bottomRight: Radius.circular(8),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(vertical:12),
                    elevation: 0,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    "확 인",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}



  @override
  Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: Colors.white,
    appBar: AppBar(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      elevation: 0,
      centerTitle: true,
      title: const Text(
        '비밀번호 변경',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.of(context).pop(),
      ),
    ),
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
                  color: Colors.black,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
                decoration: InputDecoration(
                  hintText: "아이디 입력",
                  hintStyle: const TextStyle(
                    color: Color.fromARGB(255, 128, 128, 128),
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
                          ? const Color.fromARGB(255, 192, 192, 192)
                          : Colors.red,
                      width: 1,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: BorderSide(
                      color: idErrorText == null ? Colors.black : Colors.red,
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
                          height: 16,
                          width: double.infinity,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              authCodeErrorText ?? '',
                              style: const TextStyle(
                                  color: Colors.red, fontSize: 12),
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4)),
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
                              style: TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              // 다음 버튼
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: isNextEnabled
                      ? () async {
                          String phone = phoneController.text.trim();
                          String id = idController.text.trim();

                          // 임시 테스트 조건 (나중에 API 호출로 대체)
                          if (phone != "010-1234-5678") {
                            await _showCustomDialog(
                                context, "회원 정보를 찾을 수 없습니다.");
                          } else if (id != "testUser123") {
                            await _showCustomDialog(
                                context, "회원 아이디가 존재하지 않습니다.");
                          } else {
                            // 정상 → 비밀번호 재설정 화면으로 이동
                            Navigator.push(context, MaterialPageRoute(
                               builder: (_) => const PwResetScreen(),
                             ));
                          }
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
