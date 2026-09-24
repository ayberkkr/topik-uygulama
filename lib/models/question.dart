class Question {
  final int id;
  final String type;
  final String question;
  final List<String> options;
  final int answer;
  final String explanation;

  Question({
    required this.id,
    required this.type,
    required this.question,
    required this.options,
    required this.answer,
    required this.explanation,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'] as int,
      type: json['type'] as String,
      question: json['question'] as String,
      options: List<String>.from(json['options'] as List),
      answer: json['answer'] as int,
      explanation: json['explanation'] as String,
    );
  }
}
