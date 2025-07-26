import 'package:flutter_dotenv/flutter_dotenv.dart';

String get apiKey {
  final key = dotenv.env['WEATHER_API_KEY'];
  if (key == null || key.isEmpty) {
    throw Exception('WEATHER_API_KEY not found in environment variables');
  }
  return key;
}
