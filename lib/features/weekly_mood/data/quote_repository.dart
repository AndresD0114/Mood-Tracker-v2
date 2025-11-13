import 'dart:convert';
import 'package:http/http.dart' as http;

/// Maneja la obtención de frases motivacionales desde ZenQuotes API.
class QuoteRepository {
  final String _endpoint = 'https://zenquotes.io/api/today';

  /// Devuelve una frase motivacional (texto + autor).
  Future<Map<String, String>> fetchDailyQuote() async {
    try {
      final response = await http.get(Uri.parse(_endpoint));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'quote': data[0]['q'],
          'author': data[0]['a'],
        };
      } else {
        throw Exception('Error al obtener la frase: ${response.statusCode}');
      }
    } catch (e) {
      return {
        'quote': 'No se pudo cargar la frase hoy 😔',
        'author': '',
      };
    }
  }
}
