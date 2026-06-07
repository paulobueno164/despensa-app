import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import 'api_key.dart';

/// Chave opcional passada em build/run (tem prioridade sobre a embutida):
///   flutter run --dart-define=ANTHROPIC_API_KEY=sk-ant-...
const _dartDefineKey = String.fromEnvironment('ANTHROPIC_API_KEY');

/// Resolve a chave: --dart-define primeiro, senão a embutida (ofuscada).
String get _apiKey => _dartDefineKey.isNotEmpty ? _dartDefineKey : embeddedApiKey;

const _model = 'claude-sonnet-4-6';
const _endpoint = 'https://api.anthropic.com/v1/messages';

final aiServiceProvider = Provider<AiService>((ref) => AiService());

class AiException implements Exception {
  AiException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Produto reconhecido na nota fiscal.
class ScannedProduct {
  ScannedProduct({required this.name, required this.quantity, required this.unit});
  final String name;
  double quantity;
  String unit;

  factory ScannedProduct.fromJson(Map<String, dynamic> j) => ScannedProduct(
        name: (j['name'] ?? '').toString(),
        quantity: (j['quantity'] is num)
            ? (j['quantity'] as num).toDouble()
            : double.tryParse('${j['quantity']}') ?? 1,
        unit: (j['unit'] ?? 'un').toString(),
      );
}

/// Sugestão de receita.
class RecipeSuggestion {
  RecipeSuggestion({
    required this.title,
    required this.description,
    required this.uses,
    required this.missing,
  });
  final String title;
  final String description;
  final List<String> uses;
  final List<String> missing;

  factory RecipeSuggestion.fromJson(Map<String, dynamic> j) => RecipeSuggestion(
        title: (j['title'] ?? '').toString(),
        description: (j['description'] ?? '').toString(),
        uses: (j['uses'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        missing:
            (j['missing'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      );
}

class AiService {
  bool get isConfigured => _apiKey.isNotEmpty;

  /// Lê a foto de um cupom e retorna os produtos com quantidade.
  Future<List<ScannedProduct>> scanReceipt(
    Uint8List imageBytes, {
    String mediaType = 'image/jpeg',
  }) async {
    final base64Image = base64Encode(imageBytes);
    final response = await _post({
      'model': _model,
      'max_tokens': 2000,
      'messages': [
        {
          'role': 'user',
          'content': [
            {
              'type': 'image',
              'source': {
                'type': 'base64',
                'media_type': mediaType,
                'data': base64Image,
              },
            },
            {
              'type': 'text',
              'text': 'Esta é a foto de um cupom fiscal de mercado brasileiro. '
                  'Extraia os produtos comprados. Responda APENAS com um array JSON, '
                  'sem texto extra, no formato: '
                  '[{"name":"Arroz branco","quantity":1,"unit":"kg"}]. '
                  'Use unidades simples (un, kg, g, L, ml, pacotes, caixas). '
                  'Normalize nomes de produtos para português claro.',
            },
          ],
        },
      ],
    });
    final text = _extractText(response);
    final data = _parseJsonArray(text);
    return data.map((e) => ScannedProduct.fromJson(e)).toList();
  }

  /// Sugere receitas com base nos itens disponíveis na despensa.
  Future<List<RecipeSuggestion>> suggestRecipes(List<String> pantryItems) async {
    final response = await _post({
      'model': _model,
      'max_tokens': 1500,
      'messages': [
        {
          'role': 'user',
          'content': 'Tenho estes itens na despensa: ${pantryItems.join(', ')}. '
              'Sugira 4 receitas simples que eu consiga fazer priorizando o que já tenho. '
              'Responda APENAS com um array JSON, sem texto extra, no formato: '
              '[{"title":"Nome da receita","description":"breve descrição em 1 frase",'
              '"uses":["ingredientes que já tenho"],"missing":["o que falta comprar"]}].',
        },
      ],
    });
    final text = _extractText(response);
    final data = _parseJsonArray(text);
    return data.map((e) => RecipeSuggestion.fromJson(e)).toList();
  }

  Future<Map<String, dynamic>> _post(Map<String, dynamic> body) async {
    if (!isConfigured) {
      throw AiException(
          'Chave da API não configurada. Rode com --dart-define=ANTHROPIC_API_KEY=...');
    }
    final http.Response res;
    try {
      res = await http.post(
        Uri.parse(_endpoint),
        headers: {
          'content-type': 'application/json',
          'x-api-key': _apiKey,
          'anthropic-version': '2023-06-01',
        },
        body: jsonEncode(body),
      );
    } catch (e) {
      throw AiException('Falha de conexão. Verifique a internet.');
    }
    if (res.statusCode != 200) {
      throw AiException('Erro da IA (${res.statusCode}).');
    }
    return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
  }

  String _extractText(Map<String, dynamic> response) {
    final content = response['content'] as List?;
    if (content == null || content.isEmpty) return '';
    final first = content.first as Map<String, dynamic>;
    return (first['text'] ?? '').toString();
  }

  List<Map<String, dynamic>> _parseJsonArray(String text) {
    final start = text.indexOf('[');
    final end = text.lastIndexOf(']');
    if (start == -1 || end == -1 || end < start) {
      throw AiException('Não consegui interpretar a resposta da IA.');
    }
    final jsonStr = text.substring(start, end + 1);
    final decoded = jsonDecode(jsonStr) as List;
    return decoded.cast<Map<String, dynamic>>();
  }
}
