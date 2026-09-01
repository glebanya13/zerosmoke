class TestProgress {
  TestProgress({
    required this.answeredCount,
    required this.totalCount,
    required this.completed,
  });

  final int answeredCount;
  final int totalCount;
  final bool completed;

  factory TestProgress.fromJson(Map<String, dynamic> json) {
    return TestProgress(
      answeredCount: json['answeredCount'] as int,
      totalCount: json['totalCount'] as int,
      completed: json['completed'] as bool,
    );
  }
}

class ContentTest {
  ContentTest({
    required this.id,
    required this.title,
    required this.description,
    required this.questionCount,
    required this.progress,
    this.audience,
    this.sectionId,
    this.sectionTitle,
    this.sectionPosition,
  });

  final String id;
  final String title;
  final String? description;
  final int questionCount;
  final TestProgress progress;
  final String? audience;
  final String? sectionId;
  final String? sectionTitle;
  final int? sectionPosition;

  String get topicId => sectionId ?? id;
  String get topicTitle =>
      (sectionTitle != null && sectionTitle!.trim().isNotEmpty) ? sectionTitle! : title;

  factory ContentTest.fromJson(Map<String, dynamic> json) {
    final section = json['section'] as Map<String, dynamic>?;
    return ContentTest(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      questionCount: json['questionCount'] as int,
      progress: TestProgress.fromJson(json['progress'] as Map<String, dynamic>),
      audience: json['audience'] as String?,
      sectionId: section?['id'] as String?,
      sectionTitle: section?['title'] as String?,
      sectionPosition: section?['position'] as int?,
    );
  }
}

String audienceGroupLabel(String? audience) {
  switch (audience) {
    case 'AGE_6':
      return '6–15 лет';
    case 'AGE_16':
      return '16–17 лет';
    case 'AGE_18':
      return '18+ лет';
    default:
      return 'Другой возраст';
  }
}

class TestTopicGroup {
  TestTopicGroup({required this.id, required this.title, required this.tests});

  final String id;
  final String title;
  final List<ContentTest> tests;

  bool get completed => tests.isNotEmpty && tests.every((t) => t.progress.completed);

  ContentTest get nextTest {
    return tests.firstWhere((t) => !t.progress.completed, orElse: () => tests.first);
  }
}

class TestAudienceGroup {
  TestAudienceGroup({
    required this.audience,
    required this.label,
    required this.topics,
  });

  final String audience;
  final String label;
  final List<TestTopicGroup> topics;
}

String audienceForAge(int age) {
  if (age < 16) return 'AGE_6';
  if (age < 18) return 'AGE_16';
  return 'AGE_18';
}

List<TestTopicGroup> groupTestsByTopic(List<ContentTest> tests) {
  final order = <String>[];
  final byTopic = <String, List<ContentTest>>{};
  final positionByTopic = <String, int>{};
  for (final test in tests) {
    final id = test.topicId;
    if (!byTopic.containsKey(id)) {
      order.add(id);
      byTopic[id] = [];
      positionByTopic[id] = test.sectionPosition ?? 999999;
    }
    byTopic[id]!.add(test);
  }
  order.sort((a, b) {
    final posCompare = (positionByTopic[a] ?? 999999).compareTo(positionByTopic[b] ?? 999999);
    if (posCompare != 0) return posCompare;
    return byTopic[a]!.first.topicTitle.compareTo(byTopic[b]!.first.topicTitle);
  });
  return [
    for (final id in order)
      TestTopicGroup(id: id, title: byTopic[id]!.first.topicTitle, tests: byTopic[id]!),
  ];
}

List<TestAudienceGroup> groupTestsByAudienceAndTopic(List<ContentTest> tests) {
  const audienceOrder = ['AGE_6', 'AGE_16', 'AGE_18'];
  final byAudience = <String, List<ContentTest>>{};
  for (final test in tests) {
    final key = test.audience ?? 'UNKNOWN';
    (byAudience[key] ??= []).add(test);
  }
  final keys = [
    ...audienceOrder.where(byAudience.containsKey),
    ...byAudience.keys.where((key) => !audienceOrder.contains(key)),
  ];
  return [
    for (final key in keys)
      TestAudienceGroup(
        audience: key,
        label: audienceGroupLabel(key),
        topics: groupTestsByTopic(byAudience[key]!),
      ),
  ];
}

class TestQuestionModel {
  TestQuestionModel({
    required this.id,
    required this.text,
    required this.material,
    required this.options,
    this.correctOption,
  });

  final String id;
  final String text;
  final String? material;
  final List<String> options;
  /// Not returned by GET /content/tests/:id (anti-cheat); revealed via answer API.
  final int? correctOption;

  factory TestQuestionModel.fromJson(Map<String, dynamic> json) {
    return TestQuestionModel(
      id: json['id'] as String,
      text: json['text'] as String,
      material: json['material'] as String?,
      options: (json['options'] as List).map((e) => e.toString()).toList(),
      correctOption: json['correctOption'] as int?,
    );
  }
}

class ContentTestDetail {
  ContentTestDetail({required this.id, required this.title, required this.questions});

  final String id;
  final String title;
  final List<TestQuestionModel> questions;

  factory ContentTestDetail.fromJson(Map<String, dynamic> json) {
    return ContentTestDetail(
      id: json['id'] as String,
      title: json['title'] as String,
      questions: (json['questions'] as List)
          .map((e) => TestQuestionModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class TestAttempt {
  TestAttempt({
    required this.id,
    required this.correctCount,
    required this.answeredCount,
    required this.totalCount,
    required this.completed,
    this.coinsEarned,
    this.coinsTotal,
  });

  final String id;
  final int correctCount;
  final int answeredCount;
  final int totalCount;
  final bool completed;
  final int? coinsEarned;
  final int? coinsTotal;

  factory TestAttempt.fromJson(Map<String, dynamic> json) {
    return TestAttempt(
      id: json['id'] as String,
      correctCount: json['correctCount'] as int,
      answeredCount: json['answeredCount'] as int,
      totalCount: json['totalCount'] as int,
      completed: json['completedAt'] != null,
      coinsEarned: json['coinsEarned'] as int?,
      coinsTotal: json['coinsTotal'] as int?,
    );
  }
}

class AnswerResult {
  AnswerResult({
    required this.attempt,
    required this.isCorrect,
    required this.correctOption,
  });

  final TestAttempt attempt;
  final bool isCorrect;
  final int correctOption;

  factory AnswerResult.fromJson(Map<String, dynamic> json) {
    return AnswerResult(
      attempt: TestAttempt.fromJson(json['attempt'] as Map<String, dynamic>),
      isCorrect: json['isCorrect'] as bool,
      correctOption: json['correctOption'] as int,
    );
  }
}

class TestAssignment {
  TestAssignment({
    required this.id,
    required this.testId,
    required this.testTitle,
    required this.testDescription,
    required this.questionCount,
    required this.status,
    this.message,
    this.assignedByName,
    this.assignedToName,
  });

  final String id;
  final String testId;
  final String testTitle;
  final String? testDescription;
  final int questionCount;
  final String? message;
  final String status;
  final String? assignedByName;
  final String? assignedToName;

  bool get isIncomplete => status == 'PENDING' || status == 'SEEN';

  factory TestAssignment.fromJson(Map<String, dynamic> json) {
    final test = json['test'] as Map<String, dynamic>;
    final assignedBy = json['assignedBy'] as Map<String, dynamic>?;
    final assignedTo = json['assignedTo'] as Map<String, dynamic>?;
    return TestAssignment(
      id: json['id'] as String,
      testId: json['testId'] as String? ?? test['id'] as String,
      testTitle: test['title'] as String,
      testDescription: test['description'] as String?,
      questionCount: test['questionCount'] as int,
      message: json['message'] as String?,
      status: json['status'] as String,
      assignedByName: assignedBy?['name'] as String?,
      assignedToName: assignedTo?['name'] as String?,
    );
  }
}

class ContentSectionModel {
  ContentSectionModel({required this.id, required this.title, required this.questionCount});

  final String id;
  final String title;
  final int questionCount;

  factory ContentSectionModel.fromJson(Map<String, dynamic> json) {
    return ContentSectionModel(
      id: json['id'] as String,
      title: json['title'] as String,
      questionCount: (json['_count'] as Map<String, dynamic>)['questions'] as int,
    );
  }
}

class GuideSection {
  GuideSection({required this.position, required this.title, required this.text});

  final int position;
  final String title;
  final String text;

  factory GuideSection.fromJson(Map<String, dynamic> json) {
    return GuideSection(
      position: json['position'] as int,
      title: json['title'] as String,
      text: json['text'] as String,
    );
  }
}

class GuideModel {
  GuideModel({required this.title, required this.intro, required this.sections});

  final String title;
  final String intro;
  final List<GuideSection> sections;

  factory GuideModel.fromJson(Map<String, dynamic> json) {
    final content = json['content'] as Map<String, dynamic>;
    return GuideModel(
      title: json['title'] as String,
      intro: content['intro'] as String? ?? '',
      sections: (content['sections'] as List)
          .map((e) => GuideSection.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
