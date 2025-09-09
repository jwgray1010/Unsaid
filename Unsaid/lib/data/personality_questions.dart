import 'dart:math';

class PersonalityQuestionOption {
  final String text;
  final String? type; // For goal profiling questions
  final int? anxietyScore; // 1-5 scale for anxiety dimension
  final int? avoidanceScore; // 1-5 scale for avoidance dimension

  const PersonalityQuestionOption({
    required this.text,
    this.type,
    this.anxietyScore,
    this.avoidanceScore,
  });
}

class PersonalityQuestion {
  final String question;
  final List<PersonalityQuestionOption> options;
  final bool isGoalQuestion; // true for profiling, false for attachment
  final bool isReversed; // true if higher scores indicate more security

  const PersonalityQuestion({
    required this.question,
    required this.options,
    this.isGoalQuestion = false,
    this.isReversed = false,
  });
}

// Enum for attachment styles
enum AttachmentStyle {
  secure('B', 'Secure'),
  anxious('A', 'Anxious'),
  avoidant('C', 'Avoidant'), 
  disorganized('D', 'Disorganized');

  const AttachmentStyle(this.shortName, this.longName);
  final String shortName;
  final String longName;
}

class PersonalityTest {
  static final Random _random = Random();

  // Calculate dimensional scores from answers
  static Map<String, double> calculateDimensionalScores(
    List<String> answers,
    List<PersonalityQuestion> questions,
  ) {
    double anxietySum = 0;
    double avoidanceSum = 0;
    int anxietyCount = 0;
    int avoidanceCount = 0;

    for (int i = 0; i < answers.length && i < questions.length; i++) {
      final question = questions[i];
      
      // Skip goal profiling questions
      if (question.isGoalQuestion) continue;
      
      final answer = answers[i];
      final option = question.options.firstWhere(
        (opt) => opt.text == answer,
        orElse: () => question.options.first,
      );

      if (option.anxietyScore != null) {
        double score = option.anxietyScore!.toDouble();
        if (question.isReversed) score = 6 - score; // Reverse score
        anxietySum += score;
        anxietyCount++;
      }

      if (option.avoidanceScore != null) {
        double score = option.avoidanceScore!.toDouble();
        if (question.isReversed) score = 6 - score; // Reverse score
        avoidanceSum += score;
        avoidanceCount++;
      }
    }

    return {
      'anxiety': anxietyCount > 0 ? anxietySum / anxietyCount : 3.0,
      'avoidance': avoidanceCount > 0 ? avoidanceSum / avoidanceCount : 3.0,
      'disorganized': 0.0, // Will be calculated based on anxiety + avoidance
    };
  }

  // Get questions with shuffled answers (keep question order for consistency)
  static List<PersonalityQuestion> getQuestionsWithShuffledAnswers() {
    return improvedPersonalityQuestions.map((question) {
      if (question.isGoalQuestion) {
        // Don't shuffle goal questions - order matters for user experience
        return question;
      }
      
      List<PersonalityQuestionOption> shuffledOptions = List.from(question.options);
      shuffledOptions.shuffle(_random);

      return PersonalityQuestion(
        question: question.question,
        options: shuffledOptions,
        isGoalQuestion: question.isGoalQuestion,
        isReversed: question.isReversed,
      );
    }).toList();
  }
}

// Infer attachment style from dimensional scores
AttachmentStyle inferAttachmentStyle(Map<String, double> dimensions) {
  final anxiety = dimensions['anxiety'] ?? 3.0;
  final avoidance = dimensions['avoidance'] ?? 3.0;
  
  // Cutoffs based on research (3.5 on a 1-5 scale)
  final highAnxiety = anxiety >= 3.5;
  final highAvoidance = avoidance >= 3.5;
  
  if (highAnxiety && highAvoidance) {
    return AttachmentStyle.disorganized;
  } else if (highAnxiety && !highAvoidance) {
    return AttachmentStyle.anxious;
  } else if (!highAnxiety && highAvoidance) {
    return AttachmentStyle.avoidant;
  } else {
    return AttachmentStyle.secure;
  }
}

const List<PersonalityQuestion> improvedPersonalityQuestions = [
  // ========================================
  // GOAL PROFILING QUESTIONS (1-10)
  // These determine weight multiplier profiles
  // ========================================

  PersonalityQuestion(
    question: "What's your main goal in using tone and attachment analysis right now?",
    isGoalQuestion: true,
    options: [
      PersonalityQuestionOption(text: "New connection or dating", type: "dating_sensitive"),
      PersonalityQuestionOption(text: "Repairing or deepening an existing relationship", type: "empathetic_mirror"),
      PersonalityQuestionOption(text: "Staying consistent and becoming more secure", type: "secure_training"),
      PersonalityQuestionOption(text: "Managing co-parenting communication", type: "coparenting_support"),
      PersonalityQuestionOption(text: "Getting through tough conversations better", type: "boundary_forward"),
    ],
  ),

  PersonalityQuestion(
    question: "Do you find yourself feeling emotionally distant or disconnected in your current relationship?",
    isGoalQuestion: true,
    options: [
      PersonalityQuestionOption(text: "Yes, often", type: "dating_sensitive"),
      PersonalityQuestionOption(text: "Sometimes", type: "empathetic_mirror"),
      PersonalityQuestionOption(text: "Rarely", type: "secure_training"),
      PersonalityQuestionOption(text: "No, not at all", type: "empathetic_mirror"),
    ],
  ),

  PersonalityQuestion(
    question: "Do you tend to avoid conflict or shut down during difficult conversations?",
    isGoalQuestion: true,
    options: [
      PersonalityQuestionOption(text: "Yes, I always avoid conflict", type: "deescalator"),
      PersonalityQuestionOption(text: "I often shut down", type: "coparenting_support"),
      PersonalityQuestionOption(text: "Sometimes I avoid it", type: "empathetic_mirror"),
      PersonalityQuestionOption(text: "No, I engage with difficult conversations", type: "boundary_forward"),
    ],
  ),

  PersonalityQuestion(
    question: "Are you often the one trying to repair or bring things back together after conflict?",
    isGoalQuestion: true,
    options: [
      PersonalityQuestionOption(text: "Yes, always me", type: "empathetic_mirror"),
      PersonalityQuestionOption(text: "Usually me", type: "empathetic_mirror"),
      PersonalityQuestionOption(text: "Sometimes", type: "empathetic_mirror"),
      PersonalityQuestionOption(text: "No, we both work on it", type: "secure_training"),
    ],
  ),

  PersonalityQuestion(
    question: "Are you currently trying to build a connection with someone new?",
    isGoalQuestion: true,
    options: [
      PersonalityQuestionOption(text: "Yes, actively dating", type: "dating_sensitive"),
      PersonalityQuestionOption(text: "Yes, new relationship", type: "dating_sensitive"),
      PersonalityQuestionOption(text: "No, focusing on existing relationships", type: "empathetic_mirror"),
      PersonalityQuestionOption(text: "No, single and not dating", type: "secure_training"),
    ],
  ),

  PersonalityQuestion(
    question: "Do you want to focus on how to express your emotions more clearly and vulnerably?",
    isGoalQuestion: true,
    options: [
      PersonalityQuestionOption(text: "Yes, definitely", type: "empathetic_mirror"),
      PersonalityQuestionOption(text: "Yes, somewhat", type: "empathetic_mirror"),
      PersonalityQuestionOption(text: "Maybe", type: "empathetic_mirror"),
      PersonalityQuestionOption(text: "No, I'm comfortable with my expression", type: "secure_training"),
    ],
  ),

  PersonalityQuestion(
    question: "Are you navigating a challenging topic right now (like boundaries, needs, or big changes)?",
    isGoalQuestion: true,
    options: [
      PersonalityQuestionOption(text: "Yes, very challenging topics", type: "boundary_forward"),
      PersonalityQuestionOption(text: "Yes, some difficult conversations", type: "deescalator"),
      PersonalityQuestionOption(text: "Maybe some smaller issues", type: "empathetic_mirror"),
      PersonalityQuestionOption(text: "No, things are stable", type: "secure_training"),
    ],
  ),

  PersonalityQuestion(
    question: "Is your co-parenting communication more about logistics or emotional conflict?",
    isGoalQuestion: true,
    options: [
      PersonalityQuestionOption(text: "Mostly logistics", type: "coparenting_support"),
      PersonalityQuestionOption(text: "Mix of both", type: "coparenting_support"),
      PersonalityQuestionOption(text: "Mostly emotional conflict", type: "empathetic_mirror"),
      PersonalityQuestionOption(text: "Not applicable - no co-parenting", type: "empathetic_mirror"),
    ],
  ),

  PersonalityQuestion(
    question: "Would you prefer gentle daily check-ins to help regulate tone, even in casual texts?",
    isGoalQuestion: true,
    options: [
      PersonalityQuestionOption(text: "Yes, that sounds helpful", type: "balanced"),
      PersonalityQuestionOption(text: "Maybe occasionally", type: "secure_training"),
      PersonalityQuestionOption(text: "Not really needed", type: "empathetic_mirror"),
      PersonalityQuestionOption(text: "No, I prefer minimal intervention", type: "deescalator"),
    ],
  ),

  PersonalityQuestion(
    question: "Would you describe your tone goal as: more clarity, more warmth, or more calm?",
    isGoalQuestion: true,
    options: [
      PersonalityQuestionOption(text: "More clarity", type: "boundary_forward"),
      PersonalityQuestionOption(text: "More warmth", type: "dating_sensitive"),
      PersonalityQuestionOption(text: "More calm", type: "secure_training"),
      PersonalityQuestionOption(text: "All of the above", type: "empathetic_mirror"),
    ],
  ),

  // ========================================
  // ATTACHMENT STYLE QUESTIONS (11+)
  // Scored on anxiety and avoidance dimensions
  // ========================================

  // ANXIETY DIMENSION QUESTIONS
  PersonalityQuestion(
    question: "I worry about being abandoned or rejected in close relationships.",
    options: [
      PersonalityQuestionOption(text: "Strongly Disagree", anxietyScore: 1, avoidanceScore: 1),
      PersonalityQuestionOption(text: "Disagree", anxietyScore: 2, avoidanceScore: 2),
      PersonalityQuestionOption(text: "Neutral", anxietyScore: 3, avoidanceScore: 3),
      PersonalityQuestionOption(text: "Agree", anxietyScore: 4, avoidanceScore: 3),
      PersonalityQuestionOption(text: "Strongly Agree", anxietyScore: 5, avoidanceScore: 3),
    ],
  ),

  PersonalityQuestion(
    question: "I often worry that my partner doesn't really care about me.",
    options: [
      PersonalityQuestionOption(text: "Strongly Disagree", anxietyScore: 1, avoidanceScore: 3),
      PersonalityQuestionOption(text: "Disagree", anxietyScore: 2, avoidanceScore: 3),
      PersonalityQuestionOption(text: "Neutral", anxietyScore: 3, avoidanceScore: 3),
      PersonalityQuestionOption(text: "Agree", anxietyScore: 4, avoidanceScore: 3),
      PersonalityQuestionOption(text: "Strongly Agree", anxietyScore: 5, avoidanceScore: 3),
    ],
  ),

  PersonalityQuestion(
    question: "I need a lot of reassurance from my partner.",
    options: [
      PersonalityQuestionOption(text: "Strongly Disagree", anxietyScore: 1, avoidanceScore: 4),
      PersonalityQuestionOption(text: "Disagree", anxietyScore: 2, avoidanceScore: 3),
      PersonalityQuestionOption(text: "Neutral", anxietyScore: 3, avoidanceScore: 3),
      PersonalityQuestionOption(text: "Agree", anxietyScore: 4, avoidanceScore: 2),
      PersonalityQuestionOption(text: "Strongly Agree", anxietyScore: 5, avoidanceScore: 1),
    ],
  ),

  PersonalityQuestion(
    question: "I feel secure in my relationships.", // REVERSED
    isReversed: true,
    options: [
      PersonalityQuestionOption(text: "Strongly Disagree", anxietyScore: 5, avoidanceScore: 4),
      PersonalityQuestionOption(text: "Disagree", anxietyScore: 4, avoidanceScore: 4),
      PersonalityQuestionOption(text: "Neutral", anxietyScore: 3, avoidanceScore: 3),
      PersonalityQuestionOption(text: "Agree", anxietyScore: 2, avoidanceScore: 2),
      PersonalityQuestionOption(text: "Strongly Agree", anxietyScore: 1, avoidanceScore: 1),
    ],
  ),

  PersonalityQuestion(
    question: "I find it easy to depend on romantic partners.", // REVERSED
    isReversed: true,
    options: [
      PersonalityQuestionOption(text: "Strongly Disagree", anxietyScore: 4, avoidanceScore: 5),
      PersonalityQuestionOption(text: "Disagree", anxietyScore: 3, avoidanceScore: 4),
      PersonalityQuestionOption(text: "Neutral", anxietyScore: 3, avoidanceScore: 3),
      PersonalityQuestionOption(text: "Agree", anxietyScore: 2, avoidanceScore: 2),
      PersonalityQuestionOption(text: "Strongly Agree", anxietyScore: 1, avoidanceScore: 1),
    ],
  ),

  // AVOIDANCE DIMENSION QUESTIONS
  PersonalityQuestion(
    question: "I prefer not to show how I feel deep down.",
    options: [
      PersonalityQuestionOption(text: "Strongly Disagree", anxietyScore: 2, avoidanceScore: 1),
      PersonalityQuestionOption(text: "Disagree", anxietyScore: 2, avoidanceScore: 2),
      PersonalityQuestionOption(text: "Neutral", anxietyScore: 3, avoidanceScore: 3),
      PersonalityQuestionOption(text: "Agree", anxietyScore: 3, avoidanceScore: 4),
      PersonalityQuestionOption(text: "Strongly Agree", anxietyScore: 3, avoidanceScore: 5),
    ],
  ),

  PersonalityQuestion(
    question: "I find it difficult to depend on my partners.",
    options: [
      PersonalityQuestionOption(text: "Strongly Disagree", anxietyScore: 2, avoidanceScore: 1),
      PersonalityQuestionOption(text: "Disagree", anxietyScore: 2, avoidanceScore: 2),
      PersonalityQuestionOption(text: "Neutral", anxietyScore: 3, avoidanceScore: 3),
      PersonalityQuestionOption(text: "Agree", anxietyScore: 3, avoidanceScore: 4),
      PersonalityQuestionOption(text: "Strongly Agree", anxietyScore: 3, avoidanceScore: 5),
    ],
  ),

  PersonalityQuestion(
    question: "I don't feel comfortable opening up.",
    options: [
      PersonalityQuestionOption(text: "Strongly Disagree", anxietyScore: 2, avoidanceScore: 1),
      PersonalityQuestionOption(text: "Disagree", anxietyScore: 2, avoidanceScore: 2),
      PersonalityQuestionOption(text: "Neutral", anxietyScore: 3, avoidanceScore: 3),
      PersonalityQuestionOption(text: "Agree", anxietyScore: 3, avoidanceScore: 4),
      PersonalityQuestionOption(text: "Strongly Agree", anxietyScore: 3, avoidanceScore: 5),
    ],
  ),

  PersonalityQuestion(
    question: "I prefer not to have others depend on me.", 
    options: [
      PersonalityQuestionOption(text: "Strongly Disagree", anxietyScore: 2, avoidanceScore: 1),
      PersonalityQuestionOption(text: "Disagree", anxietyScore: 2, avoidanceScore: 2),
      PersonalityQuestionOption(text: "Neutral", anxietyScore: 3, avoidanceScore: 3),
      PersonalityQuestionOption(text: "Agree", anxietyScore: 3, avoidanceScore: 4),
      PersonalityQuestionOption(text: "Strongly Agree", anxietyScore: 3, avoidanceScore: 5),
    ],
  ),

  PersonalityQuestion(
    question: "I find it easy to express my feelings.", // REVERSED
    isReversed: true,
    options: [
      PersonalityQuestionOption(text: "Strongly Disagree", anxietyScore: 3, avoidanceScore: 5),
      PersonalityQuestionOption(text: "Disagree", anxietyScore: 3, avoidanceScore: 4),
      PersonalityQuestionOption(text: "Neutral", anxietyScore: 3, avoidanceScore: 3),
      PersonalityQuestionOption(text: "Agree", anxietyScore: 2, avoidanceScore: 2),
      PersonalityQuestionOption(text: "Strongly Agree", anxietyScore: 1, avoidanceScore: 1),
    ],
  ),

  // DISORGANIZED-SPECIFIC QUESTIONS
  PersonalityQuestion(
    question: "I want to be very close to my partner but also fear intimacy.",
    options: [
      PersonalityQuestionOption(text: "Strongly Disagree", anxietyScore: 1, avoidanceScore: 2),
      PersonalityQuestionOption(text: "Disagree", anxietyScore: 2, avoidanceScore: 2),
      PersonalityQuestionOption(text: "Neutral", anxietyScore: 3, avoidanceScore: 3),
      PersonalityQuestionOption(text: "Agree", anxietyScore: 4, avoidanceScore: 4),
      PersonalityQuestionOption(text: "Strongly Agree", anxietyScore: 5, avoidanceScore: 5),
    ],
  ),

  PersonalityQuestion(
    question: "My feelings about romantic relationships seem contradictory.",
    options: [
      PersonalityQuestionOption(text: "Strongly Disagree", anxietyScore: 1, avoidanceScore: 1),
      PersonalityQuestionOption(text: "Disagree", anxietyScore: 2, avoidanceScore: 2),
      PersonalityQuestionOption(text: "Neutral", anxietyScore: 3, avoidanceScore: 3),
      PersonalityQuestionOption(text: "Agree", anxietyScore: 4, avoidanceScore: 4),
      PersonalityQuestionOption(text: "Strongly Agree", anxietyScore: 5, avoidanceScore: 5),
    ],
  ),

  PersonalityQuestion(
    question: "I sometimes send mixed signals about how close I want to be.",
    options: [
      PersonalityQuestionOption(text: "Strongly Disagree", anxietyScore: 1, avoidanceScore: 1),
      PersonalityQuestionOption(text: "Disagree", anxietyScore: 2, avoidanceScore: 2),
      PersonalityQuestionOption(text: "Neutral", anxietyScore: 3, avoidanceScore: 3),
      PersonalityQuestionOption(text: "Agree", anxietyScore: 4, avoidanceScore: 4),
      PersonalityQuestionOption(text: "Strongly Agree", anxietyScore: 5, avoidanceScore: 5),
    ],
  ),

  // ADDITIONAL DATING CONTEXT QUESTIONS
  PersonalityQuestion(
    question: "When someone I'm dating takes a while to text back, I assume something is wrong.",
    options: [
      PersonalityQuestionOption(text: "Strongly Disagree", anxietyScore: 1, avoidanceScore: 3),
      PersonalityQuestionOption(text: "Disagree", anxietyScore: 2, avoidanceScore: 3),
      PersonalityQuestionOption(text: "Neutral", anxietyScore: 3, avoidanceScore: 3),
      PersonalityQuestionOption(text: "Agree", anxietyScore: 4, avoidanceScore: 3),
      PersonalityQuestionOption(text: "Strongly Agree", anxietyScore: 5, avoidanceScore: 3),
    ],
  ),

  PersonalityQuestion(
    question: "I'm comfortable expressing interest when I'm attracted to someone.", // REVERSED
    isReversed: true,
    options: [
      PersonalityQuestionOption(text: "Strongly Disagree", anxietyScore: 4, avoidanceScore: 5),
      PersonalityQuestionOption(text: "Disagree", anxietyScore: 3, avoidanceScore: 4),
      PersonalityQuestionOption(text: "Neutral", anxietyScore: 3, avoidanceScore: 3),
      PersonalityQuestionOption(text: "Agree", anxietyScore: 2, avoidanceScore: 2),
      PersonalityQuestionOption(text: "Strongly Agree", anxietyScore: 1, avoidanceScore: 1),
    ],
  ),

  PersonalityQuestion(
    question: "When dating gets more serious, I start to worry they'll lose interest.",
    options: [
      PersonalityQuestionOption(text: "Strongly Disagree", anxietyScore: 1, avoidanceScore: 3),
      PersonalityQuestionOption(text: "Disagree", anxietyScore: 2, avoidanceScore: 3),
      PersonalityQuestionOption(text: "Neutral", anxietyScore: 3, avoidanceScore: 3),
      PersonalityQuestionOption(text: "Agree", anxietyScore: 4, avoidanceScore: 3),
      PersonalityQuestionOption(text: "Strongly Agree", anxietyScore: 5, avoidanceScore: 3),
    ],
  ),

  PersonalityQuestion(
    question: "I find it easy to be emotionally close to romantic partners.", // REVERSED
    isReversed: true,
    options: [
      PersonalityQuestionOption(text: "Strongly Disagree", anxietyScore: 3, avoidanceScore: 5),
      PersonalityQuestionOption(text: "Disagree", anxietyScore: 3, avoidanceScore: 4),
      PersonalityQuestionOption(text: "Neutral", anxietyScore: 3, avoidanceScore: 3),
      PersonalityQuestionOption(text: "Agree", anxietyScore: 2, avoidanceScore: 2),
      PersonalityQuestionOption(text: "Strongly Agree", anxietyScore: 1, avoidanceScore: 1),
    ],
  ),

  PersonalityQuestion(
    question: "I worry about being alone more than losing my independence.",
    options: [
      PersonalityQuestionOption(text: "Strongly Disagree", anxietyScore: 1, avoidanceScore: 5),
      PersonalityQuestionOption(text: "Disagree", anxietyScore: 2, avoidanceScore: 4),
      PersonalityQuestionOption(text: "Neutral", anxietyScore: 3, avoidanceScore: 3),
      PersonalityQuestionOption(text: "Agree", anxietyScore: 4, avoidanceScore: 2),
      PersonalityQuestionOption(text: "Strongly Agree", anxietyScore: 5, avoidanceScore: 1),
    ],
  ),

  PersonalityQuestion(
    question: "It's easy for me to trust new romantic partners.", // REVERSED
    isReversed: true,
    options: [
      PersonalityQuestionOption(text: "Strongly Disagree", anxietyScore: 5, avoidanceScore: 4),
      PersonalityQuestionOption(text: "Disagree", anxietyScore: 4, avoidanceScore: 3),
      PersonalityQuestionOption(text: "Neutral", anxietyScore: 3, avoidanceScore: 3),
      PersonalityQuestionOption(text: "Agree", anxietyScore: 2, avoidanceScore: 2),
      PersonalityQuestionOption(text: "Strongly Agree", anxietyScore: 1, avoidanceScore: 1),
    ],
  ),

  PersonalityQuestion(
    question: "I get frustrated when romantic partners want to be very close.",
    options: [
      PersonalityQuestionOption(text: "Strongly Disagree", anxietyScore: 2, avoidanceScore: 1),
      PersonalityQuestionOption(text: "Disagree", anxietyScore: 2, avoidanceScore: 2),
      PersonalityQuestionOption(text: "Neutral", anxietyScore: 3, avoidanceScore: 3),
      PersonalityQuestionOption(text: "Agree", anxietyScore: 3, avoidanceScore: 4),
      PersonalityQuestionOption(text: "Strongly Agree", anxietyScore: 3, avoidanceScore: 5),
    ],
  ),
];
