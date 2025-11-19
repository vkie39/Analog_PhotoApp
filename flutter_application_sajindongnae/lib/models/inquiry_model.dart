import 'package:cloud_firestore/cloud_firestore.dart';

class InquiryModel {
  final String inquiryId;      // 문서 ID
  final String title;          // 문의 제목
  final String content;        // 문의 내용
  final String uid;            // 질문자 UID
  final String nickname;       // 질문자 닉네임
  final DateTime createdAt;    // 질문 시간
  final String? answer;        // 관리자 답변
  final DateTime? answeredAt;  // 답변 시간
  final bool isAnswered;       // 답변 여부
  final String category;       // 문의 카테고리

  InquiryModel({
    required this.inquiryId,
    required this.title,
    required this.content,
    required this.uid,
    required this.nickname,
    required this.createdAt,
    this.answer,
    this.answeredAt,
    this.isAnswered = false,
    this.category = '',
  });

  // 🔹 Firestore → Model
  factory InquiryModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return InquiryModel(
      inquiryId: doc.id,
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      uid: data['uid'] ?? '',
      nickname: data['nickname'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      answer: data['answer'],
      answeredAt: data['answeredAt'] != null
          ? (data['answeredAt'] as Timestamp).toDate()
          : null,
      isAnswered: data['isAnswered'] ?? false,
      category: data['category'] ?? '',
    );
  }

  // 🔹 Model → Firestore
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'content': content,
      'uid': uid,
      'nickname': nickname,
      'createdAt': createdAt,
      'answer': answer,
      'answeredAt': answeredAt,
      'isAnswered': isAnswered,
      'category': category,
    };
  }
}