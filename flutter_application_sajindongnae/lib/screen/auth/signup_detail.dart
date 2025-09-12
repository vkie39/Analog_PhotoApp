import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter_application_sajindongnae/screen/auth/widgets/id_input.dart';
import 'package:flutter_application_sajindongnae/screen/auth/widgets/pw_input.dart';
import 'package:flutter_application_sajindongnae/screen/auth/widgets/phone_auth.dart';
import 'package:flutter_application_sajindongnae/screen/auth/widgets/email_input.dart';
import 'package:flutter_application_sajindongnae/screen/auth/widgets/terms_checkbox.dart';

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

  // ── Phone Auth 상태 ─────────────────────────────────────────────
  String? _verificationId;
  int? _resendToken;
  bool _isCodeSent = false;
  bool _isPhoneVerified = false;

  // 한국 휴대폰번호를 E.164(+82)로 변환
  String toE164KR(String input) {
    final digits = input.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return '';
    if (digits.startsWith('0')) return '+82${digits.substring(1)}';
    if (digits.startsWith('82')) return '+$digits';
    return '+82$digits';
  }

  Future<void> _registerWithFirebase() async {
    setState(() => isLoading = true);
    try {
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      // (선택) 휴대폰을 계정에 링크하고 싶다면, 아래 주석 해제
      // if (_verificationId != null && _isPhoneVerified) {
      //   final phoneCred = PhoneAuthProvider.credential(
      //     verificationId: _verificationId!,
      //     smsCode: authCodeController.text.trim(),
      //   );
      //   await credential.user?.linkWithCredential(phoneCred);
      // }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(credential.user!.uid)
          .set({
        'uid': credential.user!.uid,
        'email': emailController.text.trim(),
        'nickname': nicknameController.text.trim(),
        'createdAt': DateTime.now(),
        'phone': phoneController.text.trim(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('회원가입이 완료되었습니다.')));
        Navigator.pop(context);
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? '회원가입 실패')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  bool isAllAgreed = false; // 전체 이용 동의
  bool isAgreeTerms = false; // 이용 약관 동의 (필수)
  bool isAgreePrivacy = false; // 개인정보 수집 및 이용 동의
  bool isAgreeMarketing = false; // 개인정보 마케팅 활용 동의 (선택)
  bool isAgreeSmsEmail = false; // SMS 및 이메일 수신 동의 (선택)

  String? idErrorText;
  bool isIdValid = false;

  String? passwordErrorText;
  String? passwordConfirmErrorText;

  String? phoneErrorText; // 전화번호 입력 오류
  String? authCodeErrorText; // 인증번호 입력 오류

  String? emailErrorText;

  bool isLoading = false;

  // ✅ 휴대폰 인증 완료(_isPhoneVerified) 조건을 포함
  bool get isSignupEnabled {
    return idErrorText == null &&
        idController.text.isNotEmpty &&
        passwordController.text.isNotEmpty &&
        passwordConfirmController.text.isNotEmpty &&
        emailController.text.isNotEmpty &&
        phoneController.text.isNotEmpty &&
        _isPhoneVerified && // ← 추가됨
        isAgreeTerms &&
        isAgreePrivacy;
  }

  // 전화번호 형식
  void _validatePhoneNumber(String value) {
    String digitsOnly = value.replaceAll(RegExp(r'\D'), '');
    digitsOnly = digitsOnly.trim();

    if (digitsOnly.isEmpty) {
      phoneErrorText = '휴대폰 번호를 입력해주세요.';
    } else if (!RegExp(r'^(010|011)\d{8}$').hasMatch(digitsOnly)) {
      phoneErrorText = '올바른 번호 형식을 입력해주세요.';
    } else {
      phoneErrorText = null;
    }
  }

  // 인증번호 요청 (Firebase SMS 전송)
  void _onRequestAuthCode() async {
    FocusScope.of(context).unfocus(); // 포커스 제거
    _validatePhoneNumber(phoneController.text); // 전화번호 검증
    setState(() {}); // 에러 표시 갱신

    if (phoneErrorText != null) return;

    final phone = toE164KR(phoneController.text);
    if (phone.isEmpty) {
      setState(() => phoneErrorText = '휴대폰 번호를 다시 확인해 주세요.');
      return;
    }

    setState(() {
      authCodeErrorText = null;
      _isCodeSent = false;
      _isPhoneVerified = false;
    });

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phone,
      timeout: const Duration(seconds: 60),
      forceResendingToken: _resendToken,
      verificationCompleted: (PhoneAuthCredential credential) async {
        try {
          await FirebaseAuth.instance.signInWithCredential(credential);
          await FirebaseAuth.instance.signOut();
          if (mounted) {
            setState(() => _isPhoneVerified = true);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('휴대폰이 자동으로 인증되었습니다.')),
            );
          }
        } catch (_) {}
      },
      verificationFailed: (FirebaseAuthException e) {
        if (mounted) {
          setState(() {
            authCodeErrorText = e.message ?? '인증번호 요청 실패';
          });
        }
      },
      codeSent: (String verificationId, int? resendToken) {
        if (mounted) {
          setState(() {
            _verificationId = verificationId;
            _resendToken = resendToken;
            _isCodeSent = true;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('인증번호를 전송했습니다.')),
          );
        }
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        _verificationId = verificationId;
      },
    );
  }

  // 인증번호 확인
  Future<void> _onConfirmAuthCode() async {
    if (!_isCodeSent || _verificationId == null) {
      setState(() => authCodeErrorText = '먼저 인증번호를 요청해 주세요.');
      return;
    }
    final code = authCodeController.text.trim();
    if (code.length != 6) {
      setState(() => authCodeErrorText = '6자리 인증번호를 입력해 주세요.');
      return;
    }

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: code,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
      await FirebaseAuth.instance.signOut();

      if (mounted) {
        setState(() {
          _isPhoneVerified = true;
          authCodeErrorText = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('휴대폰 인증이 완료되었습니다.')),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() => authCodeErrorText = e.message ?? '인증번호가 올바르지 않습니다.');
    }
  }

  // 이메일 형식
  bool isValidEmail(String email) {
    final emailRegex =
    RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$");
    return emailRegex.hasMatch(email);
  }

  void _validateEmail(String value) {
    String? error;
    if (value.isEmpty) {
      error = '이메일을 입력해주세요.';
    } else if (!isValidEmail(value)) {
      error = '올바른 이메일 형식을 입력해주세요.';
    } else {
      error = null;
    }
    setState(() {
      emailErrorText = error;
    });
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
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
            padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 20.0),
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
                    // print("아이디 중복 확인: ${idController.text}");
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

                // 전화번호 입력 + 인증요청 버튼은 내부 위젯에서 onRequestAuthCode로 연결되어 있다고 가정
                PhoneAuthWidget(
                  phoneController: phoneController,
                  phoneErrorText: phoneErrorText,
                  onRequestAuthCode: _onRequestAuthCode,
                ),

                const SizedBox(height: 16),

                // 인증번호 입력 + 인증확인 버튼 가로 배치
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
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
                                hintText: _isPhoneVerified
                                    ? '인증 완료'
                                    : '인증번호 입력',
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
                              enabled: !_isPhoneVerified,
                            ),
                          ),
                          if (authCodeErrorText != null) ...[
                            const SizedBox(height: 6),
                            Text(
                              authCodeErrorText!,
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isCodeSent && !_isPhoneVerified
                            ? _onConfirmAuthCode
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFDBEFC4),
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
                        child: Text(
                          _isPhoneVerified ? "완료" : "인증 확인",
                          style: const TextStyle(
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
                EmailInputWidget(
                  emailController: emailController,
                  emailErrorText: emailErrorText,
                  onChanged: _validateEmail,
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
                  onPressed: isSignupEnabled && !isLoading
                      ? () async {
                    _validateId(idController.text);
                    if (idErrorText != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(idErrorText!)),
                      );
                      return;
                    }
                    if (!isAgreeTerms || !isAgreePrivacy) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('필수 약관에 동의해 주세요.'),
                        ),
                      );
                      return;
                    }
                    await _registerWithFirebase();
                  }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isSignupEnabled
                        ? const Color(0xFFDBEFC4)
                        : const Color(0xFFE0E0E0),
                    foregroundColor:
                    isSignupEnabled ? Colors.black : const Color(0xFF525252),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    elevation: 0,
                  ),
                  child: isLoading
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : const Text(
                    "가입하기",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
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
