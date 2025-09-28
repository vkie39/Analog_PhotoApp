import 'package:flutter/material.dart';

class PwResetScreen extends StatefulWidget {
  const PwResetScreen({super.key});

  @override
  State<PwResetScreen> createState() => _PwResetScreenState();
}

class _PwResetScreenState extends State<PwResetScreen> {
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController passwordConfirmController = TextEditingController();

  String? passwordErrorText;
  String? passwordConfirmErrorText;

  bool get isNextEnabled =>
      passwordErrorText == null &&
      passwordConfirmErrorText == null &&
      passwordController.text.isNotEmpty &&
      passwordConfirmController.text.isNotEmpty;

  @override
  void dispose() {
    passwordController.dispose();
    passwordConfirmController.dispose();
    super.dispose();
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

// 비밀번호 재설정 완료 팝업
Future<void> _showResetCompleteDialog(BuildContext context) async {
  return showDialog(
    context: context,
    barrierDismissible: false, // 팝업 밖 터치로 닫히지 않음
    builder: (BuildContext context) {
      return Dialog(
        backgroundColor: Colors.transparent, // 외부 영역
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8), // 팝업 모서리
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white, 
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 24),
              const Text(
                '비밀번호 변경이 완료되었습니다.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,       // 원하는 글자 크기
                  fontWeight: FontWeight.normal,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 36),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // 팝업 닫기
                    Navigator.of(context).pushReplacementNamed('/login'); // 로그인 화면 이동
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF84AC57),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8), // 버튼 라운딩 유지
                    ),
                  ),
                  child: const Text(
                    '로그인 화면으로 이동하기',
                    style: TextStyle(
                      fontSize: 16, 
                      fontWeight: FontWeight.bold,
                    ),
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
        title: const Text('비밀번호 재설정',
        style: TextStyle(
          color: Colors.black,
          fontSize: 20,
          fontWeight: FontWeight.bold)
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '새로운 비밀번호를 입력해주세요.',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text(
                '비밀번호는 최소 8자 이상 20자 이하로, 영문으로 시작해야 하며, \n특수문자는 !, *, #만 사용할 수 있습니다.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.black54,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              PwResetInputWidget(
                passwordController: passwordController,
                passwordConfirmController: passwordConfirmController,
                passwordErrorText: passwordErrorText,
                passwordConfirmErrorText: passwordConfirmErrorText,
                onPasswordChanged: (value) {
                  _validatePassword(value);
                  if (passwordConfirmController.text.isNotEmpty) {
                    _validatePasswordConfirm(passwordConfirmController.text);
                  }
                },
                onPasswordConfirmChanged: (value) {
                  _validatePasswordConfirm(value);
                },
              ),
              const SizedBox(height: 32),
              // 비밀번호 변경 버튼
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: isNextEnabled
                      ? () {
                          // 실제 API 호출 후 성공 시 팝업 띄우기
                          _showResetCompleteDialog(context);
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDBEFC4),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
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

// 통합 입력 위젯 (새 비밀번호 + 재입력 + 눈알 버튼)
class PwResetInputWidget extends StatefulWidget {
  final TextEditingController passwordController;
  final TextEditingController passwordConfirmController;
  final String? passwordErrorText;
  final String? passwordConfirmErrorText;
  final Function(String) onPasswordChanged;
  final Function(String) onPasswordConfirmChanged;

  const PwResetInputWidget({
    super.key,
    required this.passwordController,
    required this.passwordConfirmController,
    required this.passwordErrorText,
    required this.passwordConfirmErrorText,
    required this.onPasswordChanged,
    required this.onPasswordConfirmChanged,
  });

  @override
  State<PwResetInputWidget> createState() => _PwResetInputWidgetState();
}

class _PwResetInputWidgetState extends State<PwResetInputWidget> {
  bool _isPasswordVisible = false;
  bool _isConfirmVisible = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 새 비밀번호
        TextField(
          controller: widget.passwordController,
          obscureText: !_isPasswordVisible,
          onChanged: widget.onPasswordChanged,
          decoration: InputDecoration(
            isDense: true,
            hintText: '새 비밀번호 입력',
            suffixIcon: IconButton(
              icon: Icon(
                _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                color: Colors.grey,
              ),
              onPressed: () {
                setState(() {
                  _isPasswordVisible = !_isPasswordVisible;
                });
              },
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(
                color: widget.passwordErrorText != null ? Colors.red : const Color(0xFFC0C0C0),
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(
                color: widget.passwordErrorText != null ? Colors.red : Colors.black,
                width: 1.5,
              ),
            ),
          ),
        ),
        if (widget.passwordErrorText != null) ...[
          const SizedBox(height: 6),
          Text(
            widget.passwordErrorText!,
            style: const TextStyle(color: Colors.red, fontSize: 12),
          ),
        ],
        const SizedBox(height: 16),
        // 비밀번호 재입력
        TextField(
          controller: widget.passwordConfirmController,
          obscureText: !_isConfirmVisible,
          onChanged: widget.onPasswordConfirmChanged,
          decoration: InputDecoration(
            isDense: true,
            hintText: '새 비밀번호 다시 입력',
            suffixIcon: IconButton(
              icon: Icon(
                _isConfirmVisible ? Icons.visibility : Icons.visibility_off,
                color: Colors.grey,
              ),
              onPressed: () {
                setState(() {
                  _isConfirmVisible = !_isConfirmVisible;
                });
              },
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(
                color: widget.passwordConfirmErrorText != null ? Colors.red : const Color(0xFFC0C0C0),
                width: 1.0,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(
                color: widget.passwordConfirmErrorText != null ? Colors.red : Colors.black,
                width: 1.5,
              ),
            ),
          ),
        ),
        if (widget.passwordConfirmErrorText != null) ...[
          const SizedBox(height: 6),
          Text(
            widget.passwordConfirmErrorText!,
            style: const TextStyle(color: Colors.red, fontSize: 12),
          ),
        ],
      ],
    );
  }
}
