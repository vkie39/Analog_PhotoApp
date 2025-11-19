import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // 🔹 추가
import 'package:flutter_application_sajindongnae/models/inquiry_model.dart';

class InquiryFormScreen extends StatefulWidget {
  const InquiryFormScreen({super.key});

  @override
  State<InquiryFormScreen> createState() => _InquiryFormScreenState();
}

class _InquiryFormScreenState extends State<InquiryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  String _selectedCategory = '회원문의';
  bool _isFormValid = false;

  final List<String> _categories = ['회원문의', '결제문의', '서비스문의', '기타문의'];

  @override
  void initState() {
    super.initState();
    _titleController.addListener(_validateForm);
    _contentController.addListener(_validateForm);
  }

  void _validateForm() {
    final isValid =
        _titleController.text.isNotEmpty && _contentController.text.isNotEmpty;

    if (isValid != _isFormValid) {
      setState(() {
        _isFormValid = isValid;
      });
    }
  }
  

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      try {
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser == null) throw '로그인 정보가 없습니다';
        final uid = currentUser.uid;

        // Firestore users 컬렉션에서 닉네임 가져오기
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
        final nickname = userDoc['nickname'] ?? '닉네임 없음';

        // 새 Inquiry 모델 생성
        final newInquiry = InquiryModel(
          inquiryId: '',
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
          uid: uid,
          nickname: nickname,
          createdAt: DateTime.now(),
          category: _selectedCategory,
        );

        // Firestore 저장
        final docRef = await FirebaseFirestore.instance.collection('inquiries').add(newInquiry.toJson());

        // 완료 팝업 (UI 변경)
        if (!mounted) return;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle_outline_rounded, color: Colors.green, size: 45),
                  const SizedBox(height: 8),
                  const Text(
                    '문의 완료!',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    '문의가 성공적으로 제출되었습니다.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15, color: Colors.black87),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _formKey.currentState!.reset();
                        _titleController.clear();
                        _contentController.clear();
                        setState(() {
                          _selectedCategory = '회원문의';
                          _isFormValid = false;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF84AC57),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      ),
                      child: const Text(
                        '확인',
                        style: TextStyle(color: Colors.white, fontSize: 20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('문의 등록 실패: $e')));
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        color: Colors.white,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '카테고리',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  items:
                      _categories
                          .map(
                            (cat) =>
                                DropdownMenuItem(value: cat, child: Text(cat)),
                          )
                          .toList(),
                  onChanged: (value) {
                    if (value != null)
                      setState(() => _selectedCategory = value);
                  },
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.black, width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  dropdownColor: Colors.white,
                ),
                const SizedBox(height: 16),
                const Text(
                  '문의 제목',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    hintText: '제목을 입력하세요',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.black, width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  validator:
                      (value) =>
                          value == null || value.isEmpty ? '제목을 입력해주세요' : null,
                ),
                const SizedBox(height: 16),
                const Text(
                  '문의 내용',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _contentController,
                  maxLines: 6,
                  decoration: InputDecoration(
                    hintText: '내용을 입력하세요',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.black, width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  validator:
                      (value) =>
                          value == null || value.isEmpty ? '내용을 입력해주세요' : null,
                ),
                const SizedBox(height: 20),
                Center(
                  child: ElevatedButton(
                    onPressed: _isFormValid ? _submitForm : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          _isFormValid ? const Color(0xFF84AC57) : Colors.grey,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      '문의 제출',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
