import 'package:flutter/material.dart';

// 회원 탈퇴 화면
class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  String? selectedReason;
  final reasons = [
    '새 계정을 만들고 싶어요',
    '너무 많이 이용해요',
    '앱 사용이 어렵고 복잡해요',
    '사고싶은 사진이 없어요',
    '원하는 사진 거래가 끝났어요',
    '개인정보 보호를 위해 삭제하려고 함',
    '비매너 사용자를 만났어요',
    '기타',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '회원 탈퇴',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '회원님과 정말 이별인가요? 너무 아쉬워요..',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            const Text(
              '계정을 삭제하면 게시글, 판매글, 의뢰글, 채팅 등 모든 활동 정보가 삭제됩니다. '
              '계정 삭제 후 7일간 다시 가입할 수 없어요.',
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
            const SizedBox(height: 20),
            const Text(
              '회원님이 계정을 삭제하려는 이유가 궁금해요.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),

            DropdownButtonFormField<String>(
              value: selectedReason,
              hint: const Text('선택하세요'),
              items: reasons.map((r) {
                return DropdownMenuItem(
                  value: r,
                  child: Text(r),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedReason = value;
                });
              },
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: const BorderSide(color: Colors.grey),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: const BorderSide(color: Colors.black),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              style: const TextStyle(
                color:Colors.black,
                fontSize:14,
              ),
              dropdownColor: Colors.white,
              iconEnabledColor: Colors.black,
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: selectedReason == null
                    ? null
                    : () {
                        _showDeleteConfirmDialog(context);
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: selectedReason == null
                      ? Colors.grey
                      : const Color(0xFFDBEFC4),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  '제 출',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 탈퇴 최종 확인 팝업
  void _showDeleteConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          height: 150,
          decoration: BoxDecoration(
            color: Colors.white, // 배경색 변경
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: Text(
                    '회원님 안녕히 가세요!\n'
                    '다음에 기회가 된다면 또 만나요!',
                    style: const TextStyle(
                      fontSize: 16, 
                      fontWeight: FontWeight.bold
                      ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const Divider(height: 1),
              SizedBox(
                height: 50,
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('취소',
                        style: TextStyle(color: Colors.black),),
                      ),
                    ),
                    const VerticalDivider(width: 1),
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          print('회원 탈퇴 처리');
                        },
                        child: const Text(
                          '탈퇴',
                          style: TextStyle(color: Colors.black),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
