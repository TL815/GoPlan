const planSchemaPrompt = '''
Return JSON with this shape:
{
  "replyText": "short natural language reply",
  "planDraft": {
    "title": "plan title",
    "destination": "destination",
    "durationDays": 3,
    "summary": "brief summary",
    "days": [
      {
        "day": 1,
        "title": "day title",
        "route": "ordered route",
        "transport": "transport advice",
        "places": [
          {
            "name": "place name",
            "category": "scenic|food|hotel|shopping|transport|other",
            "city": "city",
            "latitude": null,
            "longitude": null,
            "note": "optional note"
          }
        ],
        "food": ["food recommendation"],
        "tips": "day tips"
      }
    ]
  }
}
''';
