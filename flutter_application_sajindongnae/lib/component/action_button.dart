import 'package:flutter/material.dart';

class ActionButton extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;

  const ActionButton({
    Key? key,
    required this.onPressed,
    required this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.small(
      shape: const CircleBorder(),
      heroTag: null, // 여러 버튼 충돌 방지
      backgroundColor: const Color(0xFFDDECC7),
      elevation: 3,
      onPressed: onPressed,
      child: Icon(icon, color: Color.fromARGB(255, 48, 49, 48),),
    );
  }
}
