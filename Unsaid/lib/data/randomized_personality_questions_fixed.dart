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
      PersonalityQuestionOption(text: "Strongly Agree", type: "D"), // Disorganized - extreme push/pull
      PersonalityQuestionOption(text: "Agree", type: "A"), // Anxious - wants connection but feels overwhelmed
      PersonalityQuestionOption(text: "Disagree", type: "C"), // Avoidant - doesn't crave deep connection
      PersonalityQuestionOption(text: "Strongly Disagree", type: "B"), // Secure - comfortable with connection
    ],
  ),
  PersonalityQuestion(
    question: "I often worry my partner or friends will lose interest in me.",
    options: [
      PersonalityQuestionOption(text: "Strongly Agree", type: "A"), // Anxious - constant worry
      PersonalityQuestionOption(text: "Agree", type: "D"), // Disorganized - fears abandonment unpredictably
      PersonalityQuestionOption(text: "Disagree", type: "B"), // Secure - trusts relationships
      PersonalityQuestionOption(text: "Strongly Disagree", type: "C"), // Avoidant - doesn't worry about others
    ],
  ),
  PersonalityQuestion(
    question: "I feel uncomfortable depending on others or having them depend on me.",
    options: [
      PersonalityQuestionOption(text: "Strongly Agree", type: "C"), // Avoidant - extreme independence
      PersonalityQuestionOption(text: "Agree", type: "C"), // Avoidant - prefers independence
      PersonalityQuestionOption(text: "Disagree", type: "B"), // Secure - comfortable with interdependence
      PersonalityQuestionOption(text: "Strongly Disagree", type: "A"), // Anxious - wants to depend/be depended on
    ],
  ),
  PersonalityQuestion(
    question: "When upset, I prefer to work through problems on my own.",
    options: [
      PersonalityQuestionOption(text: "Strongly Agree", type: "C"), // Avoidant - extreme self-reliance
      PersonalityQuestionOption(text: "Agree", type: "D"), // Disorganized - withdraws when overwhelmed
      PersonalityQuestionOption(text: "Disagree", type: "B"), // Secure - open to support
      PersonalityQuestionOption(text: "Strongly Disagree", type: "A"), // Anxious - needs others when upset
    ],
  ),
  PersonalityQuestion(
    question: "I find it easy to trust new people in my life.",
    options: [
      PersonalityQuestionOption(text: "Strongly Agree", type: "B"), // Secure - healthy trust
      PersonalityQuestionOption(text: "Agree", type: "A"), // Anxious - trusts but with some anxiety
      PersonalityQuestionOption(text: "Disagree", type: "D"), // Disorganized - conflicted about trust
      PersonalityQuestionOption(text: "Strongly Disagree", type: "C"), // Avoidant - distrusts easily
    ],
  ),
  PersonalityQuestion(
    question: "I worry about being abandoned or rejected.",
    options: [
      PersonalityQuestionOption(text: "Strongly Agree", type: "A"), // Anxious - core fear
      PersonalityQuestionOption(text: "Agree", type: "D"), // Disorganized - fears abandonment chaotically
      PersonalityQuestionOption(text: "Disagree", type: "B"), // Secure - doesn't worry about abandonment
      PersonalityQuestionOption(text: "Strongly Disagree", type: "C"), // Avoidant - doesn't worry because expects it
    ],
  ),
  PersonalityQuestion(
    question: "I prefer to keep my feelings to myself.",
    options: [
      PersonalityQuestionOption(text: "Strongly Agree", type: "C"), // Avoidant - emotional suppression
      PersonalityQuestionOption(text: "Agree", type: "D"), // Disorganized - conflicted about sharing
      PersonalityQuestionOption(text: "Disagree", type: "B"), // Secure - shares feelings appropriately
      PersonalityQuestionOption(text: "Strongly Disagree", type: "A"), // Anxious - over-shares feelings
    ],
  ),
  PersonalityQuestion(
    question: "I feel secure in my relationships.",
    options: [
      PersonalityQuestionOption(text: "Strongly Agree", type: "B"), // Secure - core trait
      PersonalityQuestionOption(text: "Agree", type: "C"), // Avoidant - may feel secure through distance
      PersonalityQuestionOption(text: "Disagree", type: "A"), // Anxious - insecure in relationships
      PersonalityQuestionOption(text: "Strongly Disagree", type: "D"), // Disorganized - chaotic relationship feelings
    ],
  ),
  PersonalityQuestion(
    question: "I need constant reassurance from my partner.",
    options: [
      PersonalityQuestionOption(text: "Strongly Agree", type: "A"), // Anxious - constant need
      PersonalityQuestionOption(text: "Agree", type: "A"), // Anxious - frequent need
      PersonalityQuestionOption(text: "Disagree", type: "B"), // Secure - confident without constant reassurance
      PersonalityQuestionOption(text: "Strongly Disagree", type: "C"), // Avoidant - doesn't seek reassurance
    ],
  ),
  PersonalityQuestion(
    question: "I am comfortable expressing my needs and feelings.",
    options: [
      PersonalityQuestionOption(text: "Strongly Agree", type: "B"), // Secure - healthy expression
      PersonalityQuestionOption(text: "Agree", type: "B"), // Secure - generally comfortable
      PersonalityQuestionOption(text: "Disagree", type: "C"), // Avoidant - difficulty expressing
      PersonalityQuestionOption(text: "Strongly Disagree", type: "D"), // Disorganized - confused about needs/feelings
    ],
  ),
  PersonalityQuestion(
    question: "I often feel confused about my own emotions.",
    options: [
      PersonalityQuestionOption(text: "Strongly Agree", type: "D"), // Disorganized - emotional confusion
      PersonalityQuestionOption(text: "Agree", type: "D"), // Disorganized - some confusion
      PersonalityQuestionOption(text: "Disagree", type: "B"), // Secure - emotionally aware
      PersonalityQuestionOption(text: "Strongly Disagree", type: "C"), // Avoidant - suppresses emotions (thinks they're clear)
    ],
  ),
  PersonalityQuestion(
    question: "I value my independence and alone time.",
    options: [
      PersonalityQuestionOption(text: "Strongly Agree", type: "C"), // Avoidant - extreme independence
      PersonalityQuestionOption(text: "Agree", type: "B"), // Secure - healthy balance
      PersonalityQuestionOption(text: "Disagree", type: "A"), // Anxious - prefers togetherness
      PersonalityQuestionOption(text: "Strongly Disagree", type: "A"), // Anxious - fears being alone
    ],
  ),
  PersonalityQuestion(
    question: "I am comfortable with intimacy and closeness.",
    options: [
      PersonalityQuestionOption(text: "Strongly Agree", type: "B"), // Secure - comfortable with intimacy
      PersonalityQuestionOption(text: "Agree", type: "A"), // Anxious - wants intimacy but may be anxious about it
      PersonalityQuestionOption(text: "Disagree", type: "C"), // Avoidant - uncomfortable with closeness
      PersonalityQuestionOption(text: "Strongly Disagree", type: "D"), // Disorganized - fears intimacy but craves it
    ],
  ),
  PersonalityQuestion(
    question: "I tend to overthink my relationships.",
    options: [
      PersonalityQuestionOption(text: "Strongly Agree", type: "A"), // Anxious - constant overthinking
      PersonalityQuestionOption(text: "Agree", type: "A"), // Anxious - frequent overthinking
      PersonalityQuestionOption(text: "Disagree", type: "B"), // Secure - thinks appropriately about relationships
      PersonalityQuestionOption(text: "Strongly Disagree", type: "C"), // Avoidant - avoids thinking about relationships
    ],
  ),
  PersonalityQuestion(
    question: "I find it hard to rely on others.",
    options: [
      PersonalityQuestionOption(text: "Strongly Agree", type: "C"), // Avoidant - extreme self-reliance
      PersonalityQuestionOption(text: "Agree", type: "C"), // Avoidant - difficulty relying
      PersonalityQuestionOption(text: "Disagree", type: "B"), // Secure - can rely appropriately
      PersonalityQuestionOption(text: "Strongly Disagree", type: "A"), // Anxious - may over-rely
    ],
  ),
  PersonalityQuestion(
    question: "I sometimes want closeness and distance at the same time.",
    options: [
      PersonalityQuestionOption(text: "Strongly Agree", type: "D"), // Disorganized - push/pull dynamic
      PersonalityQuestionOption(text: "Agree", type: "D"), // Disorganized - some ambivalence
      PersonalityQuestionOption(text: "Disagree", type: "B"), // Secure - consistent desires
      PersonalityQuestionOption(text: "Strongly Disagree", type: "C"), // Avoidant - consistently wants distance
    ],
  ),
  PersonalityQuestion(
    question: "I can effectively communicate my boundaries.",
    options: [
      PersonalityQuestionOption(text: "Strongly Agree", type: "B"), // Secure - healthy boundaries
      PersonalityQuestionOption(text: "Agree", type: "B"), // Secure - generally good boundaries
      PersonalityQuestionOption(text: "Disagree", type: "A"), // Anxious - struggles with boundaries
      PersonalityQuestionOption(text: "Strongly Disagree", type: "D"), // Disorganized - confused about boundaries
    ],
  ),
  PersonalityQuestion(
    question: "I worry that my partner doesn't really love me.",
    options: [
      PersonalityQuestionOption(text: "Strongly Agree", type: "A"), // Anxious - core insecurity
      PersonalityQuestionOption(text: "Agree", type: "A"), // Anxious - some insecurity
      PersonalityQuestionOption(text: "Disagree", type: "B"), // Secure - trusts partner's love
      PersonalityQuestionOption(text: "Strongly Disagree", type: "C"), // Avoidant - doesn't worry because expects less
    ],
  ),
  PersonalityQuestion(
    question: "I feel comfortable being vulnerable with my partner.",
    options: [
      PersonalityQuestionOption(text: "Strongly Agree", type: "B"), // Secure - comfortable with vulnerability
      PersonalityQuestionOption(text: "Agree", type: "B"), // Secure - generally comfortable
      PersonalityQuestionOption(text: "Disagree", type: "C"), // Avoidant - avoids vulnerability
      PersonalityQuestionOption(text: "Strongly Disagree", type: "D"), // Disorganized - fears vulnerability but may crave it
    ],
  ),
  PersonalityQuestion(
    question: "When my partner is distant, I:",
    options: [
      PersonalityQuestionOption(text: "Seek reassurance immediately", type: "A"), // Anxious
      PersonalityQuestionOption(text: "Ask what's wrong calmly", type: "B"), // Secure
      PersonalityQuestionOption(text: "Give them space", type: "C"), // Avoidant
      PersonalityQuestionOption(text: "Feel anxious but pretend I'm fine", type: "D"), // Disorganized
    ],
  ),
  PersonalityQuestion(
    question: "When I think about long-term commitment, I feel:",
    options: [
      PersonalityQuestionOption(text: "Excited but scared of losing them", type: "A"), // Anxious
      PersonalityQuestionOption(text: "Stable and comfortable", type: "B"), // Secure
      PersonalityQuestionOption(text: "Worried about loss of independence", type: "C"), // Avoidant
      PersonalityQuestionOption(text: "Unsure and overwhelmed", type: "D"), // Disorganized
    ],
  ),
];

// AttachmentStyle enum
enum AttachmentStyle {
  anxious,
  secure,
  avoidant,
  disorganized,
}

// Helper extension to get readable names
extension AttachmentStyleNames on AttachmentStyle {
  String get displayName {
    switch (this) {
      case AttachmentStyle.anxious:
        return 'Anxious Attachment';
      case AttachmentStyle.secure:
        return 'Secure Attachment';
      case AttachmentStyle.avoidant:
        return 'Dismissive Avoidant';
      case AttachmentStyle.disorganized:
        return 'Disorganized/Fearful Avoidant';
    }
  }

  String get shortName {
    switch (this) {
      case AttachmentStyle.anxious:
        return 'Anxious';
      case AttachmentStyle.secure:
        return 'Secure';
      case AttachmentStyle.avoidant:
        return 'Avoidant';
      case AttachmentStyle.disorganized:
        return 'Disorganized';
    }
  }
}

// Scoring function
Map<AttachmentStyle, int> calculateAttachmentScores(
    List<PersonalityQuestionOption> selectedOptions) {
  Map<AttachmentStyle, int> counts = {
    AttachmentStyle.anxious: 0,
    AttachmentStyle.secure: 0,
    AttachmentStyle.avoidant: 0,
    AttachmentStyle.disorganized: 0,
  };

  for (var option in selectedOptions) {
    switch (option.type) {
      case "A":
        counts[AttachmentStyle.anxious] =
            counts[AttachmentStyle.anxious]! + 1;
        break;
      case "B":
        counts[AttachmentStyle.secure] = counts[AttachmentStyle.secure]! + 1;
        break;
      case "C":
        counts[AttachmentStyle.avoidant] =
            counts[AttachmentStyle.avoidant]! + 1;
        break;
      case "D":
        counts[AttachmentStyle.disorganized] =
            counts[AttachmentStyle.disorganized]! + 1;
        break;
    }
  }
  return counts;
}
