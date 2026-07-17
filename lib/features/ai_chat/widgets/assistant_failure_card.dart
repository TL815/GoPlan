import 'package:flutter/material.dart';
import 'package:goplan/application/assistant/travel_assistant_failure.dart';

class AssistantFailureCard extends StatelessWidget {
  const AssistantFailureCard({
    super.key,
    required this.failure,
    required this.retryEnabled,
    required this.onRetry,
  });

  final TravelAssistantFailure failure;
  final bool retryEnabled;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final canRetry = retryEnabled && failure.retryable;
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * .78,
          ),
          padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: const Color(0xFFECECEC)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x12000000),
                blurRadius: 10,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _safeMessage(failure.type),
                style: const TextStyle(
                  color: Color(0xFF202426),
                  fontSize: 14,
                  height: 1.42,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (failure.retryable) ...[
                const SizedBox(height: 10),
                TextButton(
                  onPressed: canRetry ? onRetry : null,
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF17B95A),
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(52, 34),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('重试'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static String _safeMessage(TravelAssistantFailureType type) {
    return switch (type) {
      TravelAssistantFailureType.configuration => 'AI 服务尚未配置。',
      TravelAssistantFailureType.network => '网络连接失败，请检查网络后重试。',
      TravelAssistantFailureType.timeout => 'AI 响应超时，请稍后重试。',
      TravelAssistantFailureType.unauthorized => 'AI 服务认证失败。',
      TravelAssistantFailureType.rateLimited => '请求过于频繁，请稍后重试。',
      TravelAssistantFailureType.invalidRequest => '当前请求暂时无法处理。',
      TravelAssistantFailureType.invalidResponse => 'AI 响应格式无效。',
      TravelAssistantFailureType.serviceUnavailable => 'AI 服务暂时不可用。',
      TravelAssistantFailureType.cancelled => '请求已取消。',
      TravelAssistantFailureType.unknown => '旅行助手暂时无法响应。',
    };
  }
}
