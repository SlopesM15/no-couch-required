import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  static String get openAiApiKey => dotenv.env['OPENAI_API_KEY'] ?? '';
  static String get vapiApiKey => dotenv.env['VAPI_API_KEY'] ?? '';
  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';
}
