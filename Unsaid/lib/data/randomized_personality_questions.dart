import 'dart:math';
import 'personality_questions.dart' as legacy;
import 'attachment_assessment.dart' as modern;

/// Wrapper class for randomized personality test functionality
class RandomizedPersonalityTest {
  static final Random _random = Random();

  /// Get randomized questions for the personality test (using legacy system)
  static List<legacy.PersonalityQuestion> getRandomizedQuestions() {
    // Get the base questions from the improvedPersonalityQuestions constant
    final allQuestions = List<legacy.PersonalityQuestion>.from(
        legacy.improvedPersonalityQuestions);

    // Create a copy and shuffle it
    final shuffledQuestions =
        List<legacy.PersonalityQuestion>.from(allQuestions);
    shuffledQuestions.shuffle(_random);

    return shuffledQuestions;
  }

  /// Get modern assessment questions (from attachment_assessment.dart)
  static List<modern.PersonalityQuestion> getModernAssessmentQuestions() {
    // Combine attachment and goal questions from the modern assessment
    final allQuestions = <modern.PersonalityQuestion>[];

    // Add attachment questions
    allQuestions.addAll(modern.attachmentItems);

    // Add goal routing questions
    allQuestions.addAll(modern.goalItems);

    // Shuffle the combined list
    allQuestions.shuffle(_random);

    return allQuestions;
  }

  /// Get questions with shuffled answer options (legacy system)
  static List<legacy.PersonalityQuestion> getQuestionsWithShuffledAnswers() {
    final questions = getRandomizedQuestions();

    return questions.map((question) {
      final shuffledOptions =
          List<legacy.PersonalityQuestionOption>.from(question.options);
      shuffledOptions.shuffle(_random);

      return legacy.PersonalityQuestion(
        question: question.question,
        options: shuffledOptions,
        isGoalQuestion: question.isGoalQuestion,
        isReversed: question.isReversed,
      );
    }).toList();
  }

  /// Get a subset of questions for quick assessment (legacy system)
  static List<legacy.PersonalityQuestion> getQuickAssessmentQuestions(
      {int count = 15}) {
    final allQuestions = getRandomizedQuestions();
    final quickQuestions = allQuestions.take(count).toList();
    return quickQuestions;
  }

  /// Calculate scores from answers using the original PersonalityTest logic
  static Map<String, double> calculateScores(
      List<String> answers, List<legacy.PersonalityQuestion> questions) {
    return legacy.PersonalityTest.calculateDimensionalScores(
        answers, questions);
  }
}
