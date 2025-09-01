import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class IdInputWidget extends StatelessWidget {
  final TextEditingController idController;
  final String? idErrorText;
  final Function(String) onChanged;
  final VoidCallback onCheckDuplicate; // 중복 확인 버튼 클릭 콜백

  // 외부 파일 (signup_detail.dart 등)에서 필요한 값들을 위젯에 전달받기 위한 생성자
  const IdInputWidget({
    Key? key,
    required this.idController, // 위젯 밖에서 넘겨받는 텍스트 컨트롤러
    this.idErrorText, // 에러 메시지는 null 가능
    required this.onChanged, // 텍스트 바뀔 때 콜백 함수
    required this.onCheckDuplicate, // 중복 확인 버튼 눌렀을 때 콜백
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 48,
                child: TextField(
                  controller: idController,
                  onChanged: onChanged,
                  inputFormatters: [
                    _IdInputFormatter(),
                  ],
                  decoration: InputDecoration(
                    hintText: '아이디 입력',
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
                        color: idErrorText != null ? Colors.red : Color(0xFFC0C0C0),
                        width: 1.5,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: BorderSide(
                        color: idErrorText != null ? Colors.red : Colors.black,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(width: 10),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: onCheckDuplicate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFDBEFC4),
                  foregroundColor: Colors.black,
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  "중복 확인",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
        // 에러 메시지 출력
        if (idErrorText != null) ...[
            const SizedBox(height: 6),
            Text(
              idErrorText!,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
        ],
      ],
    );
  }
}

/// 아이디 입력 제한 포맷터 클래스
class _IdInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue;
  }
}
