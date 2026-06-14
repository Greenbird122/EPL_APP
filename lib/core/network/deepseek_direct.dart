import 'dart:convert';
import 'package:http/http.dart' as http;

/// Direct DeepSeek API client — fallback when backend DeepSeek is unavailable.
/// The API key is read from flutter --dart-define or defaults to an empty string.
class DeepSeekDirect {
  static const _apiKey = String.fromEnvironment('DEEPSEEK_API_KEY');

  static const _url = 'https://api.deepseek.com/chat/completions';

  static const _systemPrompt = '''
You are a maternal health triage assistant for rural Kenya.
A patient has described their symptoms. Analyze the information and respond ONLY with a valid JSON object — no markdown, no explanation.

JSON schema:
{
  "risk_level": "low" | "moderate" | "high",
  "confidence": 0.0-1.0 (your certainty in this assessment),
  "needs_referral": true | false,
  "recommendation": "<plain-language advice in 2-3 sentences>",
  "urgency": "routine" | "urgent" | "emergency"
}

Rules:
- high risk → needs_referral = true, urgency = emergency or urgent, confidence >= 0.85
- moderate risk → needs_referral may be true, urgency = urgent or routine, confidence 0.70-0.89
- low risk → needs_referral = false, urgency = routine, confidence 0.60-0.85
- Write the recommendation in simple English a patient can understand.
- Set confidence based on how clearly the symptoms match the risk indicators.
- If symptoms are vague or incomplete, lower confidence.
''';

  static bool get isConfigured => _apiKey.isNotEmpty;

  static Future<Map<String, dynamic>> analyze({
    required String pregnancyStatus,
    required String gestationWeeks,
    required String mainSymptom,
    required String symptomDuration,
    required String freeText,
  }) async {
    final payload = {
      'model': 'deepseek-chat',
      'messages': [
        {'role': 'system', 'content': _systemPrompt},
        {
          'role': 'user',
          'content': 'Pregnancy status: $pregnancyStatus\n'
              'Gestation weeks: $gestationWeeks\n'
              'Main symptom: $mainSymptom\n'
              'Symptom duration: $symptomDuration\n'
              'Patient description: $freeText',
        },
      ],
      'temperature': 0.2,
      'max_tokens': 300,
      'response_format': {'type': 'json_object'},
    };

    final response = await http
        .post(
          Uri.parse(_url),
          headers: {
            'Authorization': 'Bearer $_apiKey',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(payload),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception('DeepSeek returned ${response.statusCode}');
    }

    final data = jsonDecode(response.body);
    final content = data['choices'][0]['message']['content'];
    return jsonDecode(content);
  }

  /// AI chat reply — free-form conversation about symptoms.
  static Future<String> chatReply({
    required List<Map<String, String>> messages,
  }) async {
    final apiMessages = <Map<String, dynamic>>[
      {
        'role': 'system',
        'content': 'You are a caring maternal health assistant for Kenyan mothers. '
            'Speak simply and clearly. Use Swahili if the patient writes in Swahili. '
            'Ask follow-up questions about symptoms, severity, and duration. '
            'Never diagnose — always recommend seeing a health worker for serious concerns. '
            'Keep responses under 3 sentences.',
      },
      ...messages,
    ];

    final response = await http
        .post(
          Uri.parse(_url),
          headers: {
            'Authorization': 'Bearer $_apiKey',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'model': 'deepseek-chat',
            'messages': apiMessages,
            'temperature': 0.7,
            'max_tokens': 250,
          }),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception('DeepSeek chat returned ${response.statusCode}');
    }

    final data = jsonDecode(response.body);
    return data['choices'][0]['message']['content'];
  }
}
