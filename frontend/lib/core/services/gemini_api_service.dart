import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:frontend/core/db/app_database.dart';
import 'dart:math' as math;

/// Servicio premium para conectar con la API avanzada de Gemini Cloud (modelos de razonamiento)
/// y generar cuestionarios teológicos profundos de forma dinámica.
class GeminiApiService {
  GeminiApiService._privateConstructor();
  static final GeminiApiService instance = GeminiApiService._privateConstructor();

  // API Key pública de cortesía/desarrollo o fallback por variables de entorno
  static const String _fallbackApiKey = String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');
  
  final Dio _dio = Dio();

  /// Genera un set de 3 rondas teológicas avanzadas utilizando la API en la nube de Gemini.
  /// Si la API falla, se conecta offline o el usuario no tiene internet, recurre a un generador
  /// contextual lingüístico avanzado local para una experiencia offline-first impecable.
  Future<List<Map<String, dynamic>>> fetchAdvancedQuizData(String reference, String verseText) async {
    final apiKey = _fallbackApiKey;
    if (apiKey.isEmpty) {
      // Si no hay API key configurada, forzar fallback local/offline instantáneo sin latencia de red
      throw Exception('API Key no configurada.');
    }

    final url = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey';
    
    final prompt = '''
Analiza teológica y contextualmente el versículo bíblico: "$reference: $verseText".
Tómate tu tiempo para razonar profundamente sobre su contexto, autoría, implicaciones espirituales y enseñanzas prácticas.

Genera un JSON estructurado con exactamente 3 tipos de preguntas para evaluar al usuario.
Sigue este formato JSON exacto sin texto adicional, explicaciones ni bloques Markdown:
{
  "rounds": [
    {
      "type": "conceptual",
      "question": "Una pregunta profunda de análisis teológico o práctico (no de memorización directa).",
      "correct": "La respuesta correcta analítica.",
      "distractors": [
        "Distractor teológicamente erróneo pero sutil A.",
        "Distractor teológicamente erróneo pero sutil B.",
        "Distractor teológicamente erróneo pero sutil C."
      ]
    },
    {
      "type": "trueFalse",
      "statement": "Una afirmación teológica compleja sobre el versículo (puede ser verdadera o falsa).",
      "isTrue": true
    },
    {
      "type": "antithesis",
      "question": "¿Qué idea o actitud contradice el mensaje práctico de este pasaje?",
      "correct": "La actitud contradictoria principal.",
      "distractors": [
        "Una actitud virtuosa coherente con el versículo A.",
        "Una actitud virtuosa coherente con el versículo B.",
        "Una actitud virtuosa coherente con el versículo C."
      ]
    }
  ]
}
''';

    try {
      final response = await _dio.post(
        url,
        data: {
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ],
          'generationConfig': {
            'responseMimeType': 'application/json',
          }
        },
        options: Options(
          headers: {'Content-Type': 'application/json'},
          sendTimeout: const Duration(seconds: 8),
          receiveTimeout: const Duration(seconds: 8),
        ),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = response.data;
        final String text = data['candidates'][0]['content']['parts'][0]['text'];
        final cleanText = text.trim();
        final parsed = jsonDecode(cleanText);
        if (parsed['rounds'] is List) {
          return List<Map<String, dynamic>>.from(parsed['rounds']);
        }
      }
      throw Exception('Formato de respuesta incorrecto.');
    } catch (e) {
      debugPrint('Error en Gemini Cloud API: $e. Activando motor de razonamiento local...');
      rethrow; // Forzar el fallback en el frontend
    }
  }
}
