import 'dart:convert';

import 'llm_adapter.dart';

class MockLlmAdapter implements LlmAdapter {
  const MockLlmAdapter();

  @override
  Future<String> complete(AgentPromptRequest request) async {
    return jsonEncode({
      'replyText':
          'I created a relaxed 3-day Hangzhou plan with scenery and food.',
      'planDraft': {
        'title': 'Relaxed Hangzhou 3-Day Trip',
        'destination': 'Hangzhou',
        'durationDays': 3,
        'summary':
            'A slow-paced route around West Lake, classic neighborhoods, tea culture, and local food.',
        'days': [
          {
            'day': 1,
            'title': 'West Lake first look',
            'route': 'West Lake -> Broken Bridge -> Hubin',
            'transport': 'Walk and short taxi rides',
            'places': [
              {'name': 'West Lake', 'category': 'scenic', 'city': 'Hangzhou'},
              {
                'name': 'Broken Bridge',
                'category': 'scenic',
                'city': 'Hangzhou',
              },
            ],
            'food': ['Dongpo pork', 'Longjing shrimp'],
            'tips': 'Keep the first day light if arriving by train or flight.',
          },
          {
            'day': 2,
            'title': 'Tea fields and old streets',
            'route': 'Longjing Village -> Manjuelong -> Hefang Street',
            'transport': 'Taxi between areas, then walk',
            'places': [
              {
                'name': 'Longjing Village',
                'category': 'scenic',
                'city': 'Hangzhou',
              },
              {
                'name': 'Hefang Street',
                'category': 'shopping',
                'city': 'Hangzhou',
              },
            ],
            'food': ['Pian Er Chuan noodles', 'Osmanthus cake'],
            'tips': 'Tea fields are best in the morning.',
          },
          {
            'day': 3,
            'title': 'Temple and canal',
            'route': 'Lingyin Temple -> Xiaohe Street -> Grand Canal',
            'transport': 'Taxi and walk',
            'places': [
              {
                'name': 'Lingyin Temple',
                'category': 'scenic',
                'city': 'Hangzhou',
              },
              {'name': 'Grand Canal', 'category': 'scenic', 'city': 'Hangzhou'},
            ],
            'food': ['Hangzhou wontons', 'Green tea desserts'],
            'tips': 'Book Lingyin Temple tickets ahead during holidays.',
          },
        ],
      },
    });
  }
}
