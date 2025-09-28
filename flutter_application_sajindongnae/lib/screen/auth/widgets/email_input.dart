import 'package:flutter/material.dart';

class EmailInputWidget extends StatelessWidget {
  final TextEditingController emailController;
  final String? emailErrorText;
  final void Function(String) onChanged;

  const EmailInputWidget({
    super.key,
    required this.emailController,
    required this.emailErrorText,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: '이메일 입력',
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
                color: emailErrorText != null ? Colors.red : const Color(0xFFC0C0C0),
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(
                color: emailErrorText != null ? Colors.red : Colors.black,
                width: 1.5,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 12,
              horizontal: 12,
            ),
          ),
        ),
        if (emailErrorText != null) ...[
          const SizedBox(height: 6),
          Text(
            emailErrorText!,
            style: const TextStyle(color: Colors.red, fontSize: 12),
          ),
        ],
      ],
    );
  }
}
