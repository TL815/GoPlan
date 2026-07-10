class AiTravelAgentException implements Exception {
  const AiTravelAgentException(this.message);

  final String message;

  @override
  String toString() => message;
}

class TravelAgentResult {
  const TravelAgentResult({
    required this.destination,
    required this.durationDays,
    required this.summary,
    required this.days,
  });

  final String destination;
  final int durationDays;
  final String summary;
  final List<TravelAgentDay> days;

  String toChatText() {
    final buffer = StringBuffer()
      ..writeln('$destination · $durationDays 天路线已生成')
      ..writeln(summary);
    for (final day in days) {
      buffer
        ..writeln()
        ..writeln('D${day.day} ${day.title}')
        ..writeln('路线：${day.route}')
        ..writeln('交通：${day.transport}');
      if (day.places.isNotEmpty) {
        buffer.writeln('地点：${day.places.join('、')}');
      }
      if (day.food.isNotEmpty) {
        buffer.writeln('餐饮：${day.food.join('、')}');
      }
      if (day.notes.isNotEmpty) buffer.writeln('建议：${day.notes}');
    }
    return buffer.toString().trim();
  }
}

class TravelAgentDay {
  const TravelAgentDay({
    required this.day,
    required this.title,
    required this.route,
    required this.transport,
    required this.places,
    required this.food,
    required this.notes,
  });

  final int day;
  final String title;
  final String route;
  final String transport;
  final List<String> places;
  final List<String> food;
  final String notes;
}

class AiTravelAgentReply {
  const AiTravelAgentReply({
    required this.replyText,
    this.plan,
    this.requestStartDate = false,
  });

  final String replyText;
  final TravelAgentResult? plan;
  final bool requestStartDate;
}

abstract class AiTravelAgent {
  Future<AiTravelAgentReply> planTrip(
    String prompt, {
    List<AiTravelAgentTurn> history = const [],
  });
}

class AiTravelAgentTurn {
  const AiTravelAgentTurn({required this.role, required this.content});

  final AiTravelAgentRole role;
  final String content;
}

enum AiTravelAgentRole { user, assistant }
