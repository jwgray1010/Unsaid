import 'dart:math';

class PersonalityQuestionOption {
  final String text;
  final String type;

  const PersonalityQuestionOption({required this.text, required this.type});
}

class PersonalityQuestion {
  final String question;
  final List<PersonalityQuestionOption> options;

  const PersonalityQuestion({required this.question, required this.options});

  void toJson() {}
}

class RandomizedPersonalityTest {
  static final Random _random = Random();

  // Get randomized questions with shuffled answer options
  static List<PersonalityQuestion> getRandomizedQuestions() {
    // Create a copy of the original questions
    List<PersonalityQuestion> shuffledQuestions = personalityQuestions.map((
      question,
    ) {
      // Shuffle the options for each question
      List<PersonalityQuestionOption> shuffledOptions = List.from(
        question.options,
      );
      shuffledOptions.shuffle(_random);

      return PersonalityQuestion(
        question: question.question,
        options: shuffledOptions,
      );
    }).toList();

    // Shuffle the order of questions themselves
    shuffledQuestions.shuffle(_random);

    return shuffledQuestions;
  }

  // Get randomized questions but maintain original question order (only shuffle answers)
  static List<PersonalityQuestion> getQuestionsWithShuffledAnswers() {
    return personalityQuestions.map((question) {
      List<PersonalityQuestionOption> shuffledOptions = List.from(
        question.options,
      );
      shuffledOptions.shuffle(_random);

      return PersonalityQuestion(
        question: question.question,
        options: shuffledOptions,
      );
    }).toList();
  }

  // Seed the random generator for consistent randomization per user session
  static void setSeed(int seed) {
    // This could be based on user ID or session ID to ensure consistency
    // across the test session but randomness between different users
  }
}

const List<PersonalityQuestion> personalityQuestions = [
  // Connection & Closeness
  PersonalityQuestion(
    question: "I crave deep emotional connection but feel overwhelmed or panicked when someone gets too close.",
    options: [
      PersonalityQuestionOption(text: "Strongly Disagree", type: "B"), // Secure
      PersonalityQuestionOption(text: "Disagree", type: "C"),         // Dismissive Avoidant
      PersonalityQuestionOption(text: "Agree", type: "A"),           // Anxious
      PersonalityQuestionOption(text: "Strongly Agree", type: "D"),  // Disorganized/Fearful Avoidant
    ],
  ),
  PersonalityQuestion(
    question: "I often worry my partner or friends will lose interest in me.",
    options: [
      PersonalityQuestionOption(text: "Strongly Disagree", type: "B"), // Secure
      PersonalityQuestionOption(text: "Disagree", type: "C"),         // Dismissive Avoidant
      PersonalityQuestionOption(text: "Agree", type: "A"),           // Anxious
      PersonalityQuestionOption(text: "Strongly Agree", type: "D"),  // Disorganized/Fearful Avoidant
    ],
  ),
  PersonalityQuestion(
    question: "I feel uncomfortable depending on others or having them depend on me.",
    options: [
      PersonalityQuestionOption(text: "Strongly Disagree", type: "B"), // Secure
      PersonalityQuestionOption(text: "Disagree", type: "A"),         // Anxious
      PersonalityQuestionOption(text: "Agree", type: "C"),           // Dismissive Avoidant
      PersonalityQuestionOption(text: "Strongly Agree", type: "D"),  // Disorganized/Fearful Avoidant
    ],
  ),
  PersonalityQuestion(
    question: "I feel safe and comfortable sharing my thoughts and feelings with people I trust.",
    options: [
      PersonalityQuestionOption(text: "Strongly Disagree", type: "D"), // Disorganized/Fearful Avoidant
      PersonalityQuestionOption(text: "Disagree", type: "C"),         // Dismissive Avoidant
      PersonalityQuestionOption(text: "Agree", type: "A"),           // Anxious
      PersonalityQuestionOption(text: "Strongly Agree", type: "B"),  // Secure
    ],
  ),
  
  // Trust & Consistency
  PersonalityQuestion(
    question: "I struggle to trust people fully, even when they've given me no reason to doubt them.",
    options: [
      PersonalityQuestionOption(text: "Strongly Disagree", type: "B"), // Secure
      PersonalityQuestionOption(text: "Disagree", type: "A"),         // Anxious
      PersonalityQuestionOption(text: "Agree", type: "C"),           // Dismissive Avoidant
      PersonalityQuestionOption(text: "Strongly Agree", type: "D"),  // Disorganized/Fearful Avoidant
    ],
  ),
  PersonalityQuestion(
    question: "I trust that people close to me will be there when I need them.",
    options: [
      PersonalityQuestionOption(text: "Strongly Disagree", type: "D"), // Disorganized/Fearful Avoidant
      PersonalityQuestionOption(text: "Disagree", type: "C"),         // Dismissive Avoidant
      PersonalityQuestionOption(text: "Agree", type: "A"),           // Anxious (some trust but with worry)
      PersonalityQuestionOption(text: "Strongly Agree", type: "B"),  // Secure
    ],
  ),
  PersonalityQuestion(
    question: "I sometimes pull away or shut down communication when someone upsets me.",
    options: [
      PersonalityQuestionOption(text: "Strongly Disagree", type: "B"), // Secure
      PersonalityQuestionOption(text: "Disagree", type: "A"),         // Anxious
      PersonalityQuestionOption(text: "Agree", type: "C"),           // Dismissive Avoidant
      PersonalityQuestionOption(text: "Strongly Agree", type: "D"),  // Disorganized/Fearful Avoidant
    ],
  ),
  PersonalityQuestion(
    question: "I often feel torn between wanting closeness and wanting to be alone.",
    options: [
      PersonalityQuestionOption(text: "Strongly Disagree", type: "B"), // Secure
      PersonalityQuestionOption(text: "Disagree", type: "C"),         // Dismissive Avoidant
      PersonalityQuestionOption(text: "Agree", type: "A"),           // Anxious
      PersonalityQuestionOption(text: "Strongly Agree", type: "D"),  // Disorganized/Fearful Avoidant
    ],
  ),
  
  // Conflict & Repair
  PersonalityQuestion(
    question: "I avoid conflict at all costs, even if it means not expressing my needs.",
    options: [
      PersonalityQuestionOption(text: "Strongly Disagree", type: "B"), // Secure
      PersonalityQuestionOption(text: "Disagree", type: "A"),         // Anxious
      PersonalityQuestionOption(text: "Agree", type: "C"),           // Dismissive Avoidant
      PersonalityQuestionOption(text: "Strongly Agree", type: "D"),  // Disorganized/Fearful Avoidant
    ],
  ),
  PersonalityQuestion(
    question: "I often feel that arguments or disagreements will lead to a breakup or rejection.",
    options: [
      PersonalityQuestionOption(text: "Strongly Disagree", type: "B"), // Secure
      PersonalityQuestionOption(text: "Disagree", type: "C"),         // Dismissive Avoidant
      PersonalityQuestionOption(text: "Agree", type: "A"),           // Anxious
      PersonalityQuestionOption(text: "Strongly Agree", type: "D"),  // Disorganized/Fearful Avoidant
    ],
  ),
  PersonalityQuestion(
    question: "I have a hard time staying emotionally regulated during disagreements.",
    options: [
      PersonalityQuestionOption(text: "Strongly Disagree", type: "B"), // Secure
      PersonalityQuestionOption(text: "Disagree", type: "C"),         // Dismissive Avoidant
      PersonalityQuestionOption(text: "Agree", type: "A"),           // Anxious
      PersonalityQuestionOption(text: "Strongly Agree", type: "D"),  // Disorganized/Fearful Avoidant
    ],
  ),
  PersonalityQuestion(
    question: "I can talk things through calmly, even when we disagree.",
    options: [
      PersonalityQuestionOption(text: "Strongly Disagree", type: "D"), // Disorganized/Fearful Avoidant
      PersonalityQuestionOption(text: "Disagree", type: "A"),         // Anxious
      PersonalityQuestionOption(text: "Agree", type: "C"),           // Dismissive Avoidant
      PersonalityQuestionOption(text: "Strongly Agree", type: "B"),  // Secure
    ],
  ),
  
  // Self-Worth & Reassurance
  PersonalityQuestion(
    question: "I often need frequent reassurance that I am loved or cared for.",
    options: [
      PersonalityQuestionOption(text: "Strongly Disagree", type: "C"), // Dismissive Avoidant
      PersonalityQuestionOption(text: "Disagree", type: "B"),         // Secure
      PersonalityQuestionOption(text: "Agree", type: "A"),           // Anxious
      PersonalityQuestionOption(text: "Strongly Agree", type: "D"),  // Disorganized/Fearful Avoidant
    ],
  ),
  PersonalityQuestion(
    question: "I tend to feel that I'm not good enough for my partner or friends.",
    options: [
      PersonalityQuestionOption(text: "Strongly Disagree", type: "B"), // Secure
      PersonalityQuestionOption(text: "Disagree", type: "C"),         // Dismissive Avoidant
      PersonalityQuestionOption(text: "Agree", type: "A"),           // Anxious
      PersonalityQuestionOption(text: "Strongly Agree", type: "D"),  // Disorganized/Fearful Avoidant
    ],
  ),
  PersonalityQuestion(
    question: "I feel confident that I am worthy of love and respect.",
    options: [
      PersonalityQuestionOption(text: "Strongly Disagree", type: "D"), // Disorganized/Fearful Avoidant
      PersonalityQuestionOption(text: "Disagree", type: "A"),         // Anxious
      PersonalityQuestionOption(text: "Agree", type: "C"),           // Dismissive Avoidant
      PersonalityQuestionOption(text: "Strongly Agree", type: "B"),  // Secure
    ],
  ),
  
  // Boundaries & Space
  PersonalityQuestion(
    question: "I feel smothered if someone wants to be too close to me all the time.",
    options: [
      PersonalityQuestionOption(text: "Strongly Disagree", type: "A"), // Anxious
      PersonalityQuestionOption(text: "Disagree", type: "B"),         // Secure
      PersonalityQuestionOption(text: "Agree", type: "C"),           // Dismissive Avoidant
      PersonalityQuestionOption(text: "Strongly Agree", type: "D"),  // Disorganized/Fearful Avoidant
    ],
  ),
  PersonalityQuestion(
    question: "I sometimes send mixed signals about how much closeness I want.",
    options: [
      PersonalityQuestionOption(text: "Strongly Disagree", type: "B"), // Secure
      PersonalityQuestionOption(text: "Disagree", type: "C"),         // Dismissive Avoidant
      PersonalityQuestionOption(text: "Agree", type: "A"),           // Anxious
      PersonalityQuestionOption(text: "Strongly Agree", type: "D"),  // Disorganized/Fearful Avoidant
    ],
  ),
  PersonalityQuestion(
    question: "I feel comfortable setting boundaries without feeling guilty or afraid.",
    options: [
      PersonalityQuestionOption(text: "Strongly Disagree", type: "A"), // Anxious
      PersonalityQuestionOption(text: "Disagree", type: "D"),         // Disorganized/Fearful Avoidant
      PersonalityQuestionOption(text: "Agree", type: "C"),           // Dismissive Avoidant
      PersonalityQuestionOption(text: "Strongly Agree", type: "B"),  // Secure
    ],
  ),
  
  // Behavioral Patterns
  PersonalityQuestion(
    question: "I tend to withdraw, ghost, or push people away when I feel hurt or overwhelmed.",
    options: [
      PersonalityQuestionOption(text: "Strongly Disagree", type: "B"), // Secure
      PersonalityQuestionOption(text: "Disagree", type: "A"),         // Anxious
      PersonalityQuestionOption(text: "Agree", type: "C"),           // Dismissive Avoidant
      PersonalityQuestionOption(text: "Strongly Agree", type: "D"),  // Disorganized/Fearful Avoidant
    ],
  ),
  PersonalityQuestion(
    question: "I feel calm and stable in my close relationships most of the time.",
    options: [
      PersonalityQuestionOption(text: "Strongly Disagree", type: "D"), // Disorganized/Fearful Avoidant
      PersonalityQuestionOption(text: "Disagree", type: "A"),         // Anxious
      PersonalityQuestionOption(text: "Agree", type: "C"),           // Dismissive Avoidant
      PersonalityQuestionOption(text: "Strongly Agree", type: "B"),  // Secure
    ],
  ),
];
