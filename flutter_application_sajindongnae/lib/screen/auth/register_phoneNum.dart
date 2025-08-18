import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class RegisterPhoneNumScreen extends StatefulWidget {
  const RegisterPhoneNumScreen({super.key});

  @override
  State<RegisterPhoneNumScreen> createState() => _RegisterPhoneNumScreenState();
}

class _RegisterPhoneNumScreenState extends State<RegisterPhoneNumScreen> {
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController codeController = TextEditingController();
  String? _verificationId;
  bool isLoading = false;

  Future<void> _sendCode() async {
    setState(() => isLoading = true);
    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phoneController.text.trim(),
      verificationCompleted: (PhoneAuthCredential credential) async {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await user.linkWithCredential(credential);
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .update({'phoneNumber': phoneController.text.trim()});
          if (mounted) Navigator.pop(context);
        }
      },
      verificationFailed: (FirebaseAuthException e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? '인증 실패')),
        );
      },
      codeSent: (String verificationId, int? resendToken) {
        setState(() {
          _verificationId = verificationId;
        });
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        _verificationId = verificationId;
      },
    );
    setState(() => isLoading = false);
  }

  Future<void> _verifyCode() async {
    if (_verificationId == null) return;
    setState(() => isLoading = true);
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: codeController.text.trim(),
      );
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.linkWithCredential(credential);
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'phoneNumber': phoneController.text.trim()});
        if (mounted) Navigator.pop(context);
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? '인증 실패')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('휴대폰 번호 인증')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: '휴대폰 번호'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: isLoading ? null : _sendCode,
              child: const Text('인증번호 전송'),
            ),
            if (_verificationId != null) ...[
              TextField(
                controller: codeController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: '인증번호'),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: isLoading ? null : _verifyCode,
                child: isLoading
                    ? const CircularProgressIndicator()
                    : const Text('확인'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
