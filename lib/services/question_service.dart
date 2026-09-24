import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import '../models/question.dart';

class QuestionService {
  static const String _gistUrl =
      'https://gist.githubusercontent.com/ayberkkr/ffaadef1d1dd1b3e27fe524ed1d308a7/raw/9f4da22a559c39771a3708a5c4e5a44277487473/sorular.json';

  Future<List<Question>> fetchQuestions() async {
    try {
      final response = await http
          .get(Uri.parse(_gistUrl))
          .timeout(const Duration(seconds: 6));

      if (response.statusCode == 200) {
        final List<dynamic> jsonData =
            json.decode(utf8.decode(response.bodyBytes));
        return jsonData.map((json) => Question.fromJson(json)).toList();
      }
    } catch (_) {
      // Ağ hatası veya zaman aşımı durumunda yerel yedekten yükle
    }

    try {
      final localData =
          await rootBundle.loadString('assets/sorular_backup.json');
      final List<dynamic> jsonData = json.decode(localData);
      return jsonData.map((json) => Question.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Sorular yüklenirken hata oluştu: $e');
    }
  }

  Future<List<Question>> fetchShuffled({int? limit}) async {
    final questions = await fetchQuestions();
    questions.shuffle();
    if (limit != null && questions.length > limit) {
      return questions.take(limit).toList();
    }
    return questions;
  }
}
