import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class RegisterPhoneNumScreen extends StatefulWidget {
  const RegisterPhoneNumScreen({super.key});

  @override
  State<RegisterPhoneNumScreen> createState() => _RegisterPhoneNumScreenState();
}

class _RegisterPhoneNumScreenState extends State<RegisterPhoneNumScreen> {
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController codeController = TextEditingController();
  String? _verificationId;
  int? _resendToken;
  bool isLoading = false;

  @override
  void dispose() {
    phoneController.dispose();
    codeController.dispose();
    super.dispose();
  }

  String _normalizeKrPhone(String raw) {
    // 예: 010-1234-5678 -> +821012345678
    final digits = raw.replaceAll(RegExp(r'[^0-9+]'), '');
    if (digits.isEmpty) return digits;
    if (digits.startsWith('+')) return digits;
    if (digits.startsWith('010')) return '+82${digits.substring(1)}';
    if (digits.startsWith('0')) return '+82${digits.substring(1)}';
    return digits;
  }

  Future<void> _sendCode({bool isResend = false}) async {
    final raw = phoneController.text.trim();
    if (raw.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('휴대폰 번호를 입력해 주세요.')));
      return;
    }
    final phone = _normalizeKrPhone(raw);

    FocusScope.of(context).unfocus();
    setState(() => isLoading = true);

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phone,
      forceResendingToken: isResend ? _resendToken : null,
      verificationCompleted: (PhoneAuthCredential credential) async {
        try {
          final user = FirebaseAuth.instance.currentUser;
          if (user == null) return;
          await user.linkWithCredential(credential);
          await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
            'phoneNumber': phone,
            'providers': FieldValue.arrayUnion(['phone']),
          }, SetOptions(merge: true));
          if (!mounted) return;
          Navigator.pop(context);
        } on FirebaseAuthException catch (e) {
          if (!mounted) return;
          String msg = '인증 실패';
          if (e.code == 'credential-already-in-use') msg = '이미 다른 계정에 연결된 번호입니다.';
          if (e.code == 'provider-already-linked') msg = '이미 전화번호가 연결되어 있습니다.';
          if (e.code == 'requires-recent-login') msg = '보안을 위해 다시 로그인 후 시도해 주세요.';
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
        }
      },
      verificationFailed: (FirebaseAuthException e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? '인증 실패')),
        );
      },
      codeSent: (String verificationId, int? resendToken) {
        if (!mounted) return;
        setState(() {
          _verificationId = verificationId;
          _resendToken = resendToken;
        });
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        _verificationId = verificationId; // 수동 코드 입력 유도
      },
    );

    if (mounted) setState(() => isLoading = false);
  }

  Future<void> _verifyCode() async {
    final code = codeController.text.trim();
    if (_verificationId == null || code.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('유효한 인증번호(6자리)를 입력해 주세요.')));
      return;
    }
    setState(() => isLoading = true);
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: code,
      );
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await user.linkWithCredential(credential);
      final phone = _normalizeKrPhone(phoneController.text.trim());
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'phoneNumber': phone,
        'providers': FieldValue.arrayUnion(['phone']),
      }, SetOptions(merge: true));

      if (!mounted) return;
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      String msg = '인증 실패';
      if (e.code == 'invalid-verification-code') msg = '인증번호가 올바르지 않습니다.';
      if (e.code == 'credential-already-in-use') msg = '이미 다른 계정에 연결된 번호입니다.';
      if (e.code == 'provider-already-linked') msg = '이미 전화번호가 연결되어 있습니다.';
      if (e.code == 'session-expired') msg = '인증 세션이 만료되었습니다. 다시 시도해 주세요.';
      if (e.code == 'requires-recent-login') msg = '보안을 위해 다시 로그인 후 시도해 주세요.';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canVerify = _verificationId != null;

    return Scaffold(
      appBar: AppBar(title: const Text('휴대폰 번호 인증')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-\s]'))],
              decoration: const InputDecoration(
                labelText: '휴대폰 번호 (예: 010-1234-5678 또는 +821012345678)',
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: isLoading ? null : () => _sendCode(isResend: false),
                    child: const Text('인증번호 전송'),
                  ),
                ),
                const SizedBox(width: 8),
                if (_resendToken != null)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: isLoading ? null : () => _sendCode(isResend: true),
                      child: const Text('재전송'),
                    ),
                  ),
              ],
            ),
            if (canVerify) ...[
              const SizedBox(height: 12),
              TextField(
                controller: codeController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: const InputDecoration(labelText: '인증번호 6자리', counterText: ''),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: isLoading ? null : _verifyCode,
                child: isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('확인'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
