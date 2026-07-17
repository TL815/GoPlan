import 'package:flutter/material.dart';

class AssistantLoadingIndicator extends StatelessWidget {
  const AssistantLoadingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                center: Alignment(-.35, -.35),
                radius: .9,
                colors: [
                  Color(0xFFE7FFF0),
                  Color(0xFF6DE58E),
                  Color(0xFF17B95A),
                ],
                stops: [0, .48, 1],
              ),
              boxShadow: [
                BoxShadow(
                  color: Color(0x3317B95A),
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(13),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x12000000),
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: const Text(
              'AI 正在思考...',
              style: TextStyle(fontSize: 14, color: Color(0xFF8A8F91)),
            ),
          ),
        ],
      ),
    );
  }
}
