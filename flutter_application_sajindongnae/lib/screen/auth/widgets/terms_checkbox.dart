import 'package:flutter/material.dart';

class TermsCheckboxWidget extends StatelessWidget {
  final bool isAllAgreed; // 전체 이용 동의
  final bool isAgreeTerms; // 이용 약관 동의 (필수)
  final bool isAgreePrivacy; // 개인정보 수집 및 이용 동의 (필수)
  final bool isAgreeMarketing; // 개인정보 마케팅 활용 동의 (선택)
  final bool isAgreeSmsEmail; // SMS 및 이메일 수신 동의 (선택)

  final VoidCallback onAllAgreeTap;
  final VoidCallback onTermsTap;
  final VoidCallback onPrivacyTap;
  final VoidCallback onMarketingTap;
  final VoidCallback onSmsEmailTap;

  const TermsCheckboxWidget({
    super.key,
    required this.isAllAgreed,
    required this.isAgreeTerms,
    required this.isAgreePrivacy,
    required this.isAgreeMarketing,
    required this.isAgreeSmsEmail,
    required this.onAllAgreeTap,
    required this.onTermsTap,
    required this.onPrivacyTap,
    required this.onMarketingTap,
    required this.onSmsEmailTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 전체 동의
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onAllAgreeTap,
          child: Row(
            children: [
              styledCheckbox(value: isAllAgreed, onTap: onAllAgreeTap),
              const SizedBox(width: 8),
              Text(
                "약관 전체 동의",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: isAllAgreed ? FontWeight.bold : FontWeight.w400,
                  color: isAllAgreed ? Colors.black : const Color(0xFFE0E0E0),
                ),
              ),
            ],
          ),
        ),

        // 구분선
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Divider(color: Color(0xFFE0E0E0), thickness: 1),
        ),

        // 필수 약관 1
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTermsTap,
          child: Row(
            children: [
              styledCheckbox(value: isAgreeTerms, onTap: onTermsTap),
              const SizedBox(width: 8),
              Text(
                "이용약관 동의 (필수)",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: isAgreeTerms ? FontWeight.bold : FontWeight.w400,
                  color: isAgreeTerms ? Colors.black : const Color(0xFFE0E0E0),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // 필수 약관 2
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onPrivacyTap,
          child: Row(
            children: [
              styledCheckbox(value: isAgreePrivacy, onTap: onPrivacyTap),
              const SizedBox(width: 8),
              Text(
                "개인정보 수집 • 이용 동의 (필수)",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: isAgreePrivacy
                      ? FontWeight.bold
                      : FontWeight.w400,
                  color: isAgreePrivacy
                      ? Colors.black
                      : const Color(0xFFE0E0E0),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 선택 약관 1
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onMarketingTap,
          child: Row(
            children: [
              styledCheckbox(value: isAgreeMarketing, onTap: onMarketingTap),
              const SizedBox(width: 8),
              Text(
                "개인정보 마케팅 활용 동의 (선택)",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: isAgreeMarketing
                      ? FontWeight.bold
                      : FontWeight.w400,
                  color: isAgreeMarketing
                      ? Colors.black
                      : const Color(0xFFE0E0E0),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 선택 약관 2
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onSmsEmailTap,
          child: Row(
            children: [
              styledCheckbox(value: isAgreeSmsEmail, onTap: onSmsEmailTap),
              const SizedBox(width: 8),
              Text(
                "SMS 및 이메일 수신 동의 (선택)",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: isAgreeSmsEmail
                      ? FontWeight.bold
                      : FontWeight.w400,
                  color: isAgreeSmsEmail
                      ? Colors.black
                      : const Color(0xFFE0E0E0),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

Widget styledCheckbox({required bool value, required VoidCallback onTap}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.transparent,
        border: Border.all(
          color: value ? Color(0xFFDBEFC4) : const Color(0xFFE0E0E0),
          width: 2,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.check,
          size: 16,
          color: value ? const Color(0xFFDBEFC4) : const Color(0xFFE0E0E0),
        ),
      ),
    ),
  );
}
