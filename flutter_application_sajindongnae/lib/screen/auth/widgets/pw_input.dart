import 'package:flutter/material.dart';

class PwInputWidget extends StatelessWidget {
  final TextEditingController passwordController;
  final TextEditingController passwordConfirmController;
  final String? passwordErrorText;
  final String? passwordConfirmErrorText;
  final Function(String) onPasswordChanged;
  final Function(String) onPasswordConfirmChanged;

  const PwInputWidget({
    Key? key,
    required this.passwordController,
    required this.passwordConfirmController,
    required this.passwordErrorText,
    required this.passwordConfirmErrorText,
    required this.onPasswordChanged,
    required this.onPasswordConfirmChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 비밀번호 입력
        TextField(
          controller: passwordController,
          obscureText: true,
          onChanged: onPasswordChanged,
          decoration: InputDecoration(
            isDense: true,
            hintText: '비밀번호 입력',
            hintStyle: const TextStyle(
              color: Color.fromARGB(255, 128, 128, 128),
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(
                color: passwordErrorText != null
                    ? Colors.red
                    : Color(0xFFC0C0C0),
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(
                color: passwordErrorText != null ? Colors.red : Colors.black,
                width: 1.5,
              ),
            ),
          ),
        ),
        if (passwordErrorText != null) ...[
          const SizedBox(height: 6),
          Text(
            passwordErrorText!,
            style: const TextStyle(color: Colors.red, fontSize: 12),
          ),
        ],

        const SizedBox(height: 16),

        // 비밀번호 재확인 입력
        TextField(
          controller: passwordConfirmController,
          obscureText: true,
          onChanged: onPasswordConfirmChanged,
          decoration: InputDecoration(
            isDense: true,
            hintText: '비밀번호 다시 입력',
            hintStyle: const TextStyle(
              color: Color.fromARGB(255, 128, 128, 128),
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(
                color: passwordConfirmErrorText != null
                    ? Colors.red
                    : Color(0xFFC0C0C0),
                width: 1.0,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(
                color: passwordConfirmErrorText != null
                    ? Colors.red
                    : Colors.black,
                width: 1.5,
              ),
            ),
          ),
        ),
        if (passwordConfirmErrorText != null) ...[
          const SizedBox(height: 6),
          Text(
            passwordConfirmErrorText!,
            style: const TextStyle(color: Colors.red, fontSize: 12),
          ),
        ],
      ],
    );
  }
}
