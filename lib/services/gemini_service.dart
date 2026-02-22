import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GeminiService {
  static const _apiKeyPref = 'gemini_api_key';

  GenerativeModel? _model;

  Future<String?> getApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_apiKeyPref);
  }

  Future<void> setApiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_apiKeyPref, key);
    _model = null;
  }

  Future<bool> hasApiKey() async {
    final key = await getApiKey();
    return key != null && key.isNotEmpty;
  }

  Future<GenerativeModel> _getModel() async {
    if (_model != null) return _model!;
    final key = await getApiKey();
    if (key == null || key.isEmpty) {
      throw Exception('Gemini API 키가 설정되지 않았습니다.\n설정 탭에서 API 키를 입력해 주세요.');
    }
    _model = GenerativeModel(
      model: 'gemini-2.0-flash',
      apiKey: key,
      systemInstruction: Content.system(
        '당신은 한국 로또 6/45 번호 분석 전문가입니다. '
        '통계 데이터를 기반으로 번호를 추천합니다. '
        '한국어로 응답하세요.',
      ),
    );
    return _model!;
  }

  Future<String> getRecommendation(String analysisPrompt) async {
    final model = await _getModel();
    final response = await model.generateContent([
      Content.text(analysisPrompt),
    ]);
    return response.text ?? '응답을 받지 못했습니다.';
  }
}
