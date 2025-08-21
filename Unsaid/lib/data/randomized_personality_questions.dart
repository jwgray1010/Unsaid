import 'dart:math';
import 'personality_questions.dart';

/// Wrapper class for randomized personality test functionality
class RandomizedPersonalityTest {
  static final Random _random = Random();

  /// Get randomized questions for the personality test
  static List<PersonalityQuestion> getRandomizedQuestions() {
    // Get the base questions from PersonalityTest
    final allQuestions = PersonalityTest.getAllQuestions();
    
    // Create a copy and shuffle it
    final shuffledQuestions = List<PersonalityQuestion>.from(allQuestions);
    shuffledQuestions.shuffle(_random);
    
    return shuffledQuestions;
  }

  /// Get questions with shuffled answer options
  static List<PersonalityQuestion> getQuestionsWithShuffledAnswers() {
    final questions = getRandomizedQuestions();
    
    return questions.map((question) {
      final shuffledOptions = List<PersonalityQuestionOption>.from(question.options);
      shuffledOptions.shuffle(_random);
      
      return PersonalityQuestion(
        question: question.question,
        options: shuffledOptions,
        isGoalQuestion: question.isGoalQuestion,
        isReversed: question.isReversed,
      );
    }).toList();
  }

  /// Get a subset of questions for quick assessment
  static List<PersonalityQuestion> getQuickAssessmentQuestions({int count = 15}) {
    final allQuestions = getRandomizedQuestions();
    final quickQuestions = allQuestions.take(count).toList();
    return quickQuestions;
  }

  /// Calculate scores from answers using the original PersonalityTest logic
  static Map<String, double> calculateScores(
    List<String> answers, 
    List<PersonalityQuestion> questions
  ) {
    return PersonalityTest.calculateDimensionalScores(answers, questions);
  }
}
