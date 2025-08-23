// attachment_assessment.dart
// Unsaid - Attachment Screener + Goal Routing (two-track, psychometric-first)
//
// No external deps. Pure Dart, UI-agnostic.
// ------------------------------------------------------------

import 'dart:math';

enum Dimension { anxiety, avoidance, none }

class PersonalityQuestion {
  final String id;
  final String question;
  final bool reversed; // for psychometric scoring
  final Dimension dimension; // anxiety | avoidance | none
  final bool isGoal; // separates routing from scoring
  final bool isAttentionCheck; // for attention validation
  final bool isSocialDesirability;
  final List<PersonalityQuestionOption> options;
  final double weight; // default 1.0; useful for pilots

  const PersonalityQuestion({
    required this.id,
    required this.question,
    this.reversed = false,
    this.dimension = Dimension.none,
    this.isGoal = false,
    this.isAttentionCheck = false,
    this.isSocialDesirability = false,
    this.options = const [],
    this.weight = 1.0,
  });
}

class PersonalityQuestionOption {
  final String text;

  /// Likert 1..5 (Strongly Disagree..Strongly Agree) for psychometric items.
  /// For goal items, still store 1..5 for UX consistency (not used in scoring).
  final int value;

  /// For goal items only: route tags for product/profiles.
  final String? routeTag; // e.g., "dating_sensitive", "boundary_forward"
  const PersonalityQuestionOption({
    required this.text,
    required this.value,
    this.routeTag,
  });
}

/// ------------------------------
/// Track A: Attachment Screener
/// ------------------------------

/// 12-item, ECR-style compact set (6 anxiety, 6 avoidance), 50% reversed.
/// Likert: 1=Strongly Disagree ... 5=Strongly Agree
final List<PersonalityQuestion> attachmentItems = [
  // ---- Anxiety (A) ----
  const PersonalityQuestion(
    id: "A1",
    question: "I worry that romantic partners may not love me completely.",
    dimension: Dimension.anxiety,
    options: likert5,
  ),
  const PersonalityQuestion(
    id: "A2",
    question: "I often need reassurance from my partner.",
    dimension: Dimension.anxiety,
    options: likert5,
  ),
  const PersonalityQuestion(
    id: "A3",
    question: "I worry about being abandoned.",
    dimension: Dimension.anxiety,
    options: likert5,
  ),
  const PersonalityQuestion(
    id: "A4",
    question: "I rarely worry about relationship stability.",
    dimension: Dimension.anxiety,
    reversed: true,
    options: likert5,
  ),
  const PersonalityQuestion(
    id: "A5",
    question: "I feel confident my partner cares for me.",
    dimension: Dimension.anxiety,
    reversed: true,
    options: likert5,
  ),
  const PersonalityQuestion(
    id: "A6",
    question: "I'm afraid my partner will lose interest in me.",
    dimension: Dimension.anxiety,
    options: likert5,
  ),

  // ---- Avoidance (V) ----
  const PersonalityQuestion(
    id: "V1",
    question: "I prefer not to show deep feelings.",
    dimension: Dimension.avoidance,
    options: likert5,
  ),
  const PersonalityQuestion(
    id: "V2",
    question: "I find it hard to depend on others.",
    dimension: Dimension.avoidance,
    options: likert5,
  ),
  const PersonalityQuestion(
    id: "V3",
    question: "I'm uncomfortable being emotionally close.",
    dimension: Dimension.avoidance,
    options: likert5,
  ),
  const PersonalityQuestion(
    id: "V4",
    question: "I find it easy to be emotionally close.",
    dimension: Dimension.avoidance,
    reversed: true,
    options: likert5,
  ),
  const PersonalityQuestion(
    id: "V5",
    question: "I'm comfortable depending on my partner.",
    dimension: Dimension.avoidance,
    reversed: true,
    options: likert5,
  ),
  const PersonalityQuestion(
    id: "V6",
    question: "I'm okay with others depending on me.",
    dimension: Dimension.avoidance,
    reversed: true,
    options: likert5,
  ),

  // ---- Lightweight checks (excluded from A/A scoring, used for quality flags) ----
  const PersonalityQuestion(
    id: "CHK_ATTEN",
    question: "Attention check: please select 'Agree' for this item.",
    isAttentionCheck: true,
    options: [
      PersonalityQuestionOption(text: "Strongly Disagree", value: 1),
      PersonalityQuestionOption(text: "Disagree", value: 2),
      PersonalityQuestionOption(text: "Neutral", value: 3),
      PersonalityQuestionOption(text: "Agree", value: 4),
      PersonalityQuestionOption(text: "Strongly Agree", value: 5),
    ],
  ),
  const PersonalityQuestion(
    id: "SD1",
    question: "I always communicate calmly, even when extremely upset.",
    isSocialDesirability: true,
    options: likert5,
  ),
  const PersonalityQuestion(
    id: "SD2",
    question: "I never react defensively in arguments.",
    isSocialDesirability: true,
    options: likert5,
  ),

  // ---- Paradox pattern probe (not scored, used for 'disorganized-leaning' rule) ----
  const PersonalityQuestion(
    id: "PX1",
    question: "I want to be very close to my partner but also fear intimacy.",
    options: likert5,
  ),
];

/// Standard Likert options 1..5
const List<PersonalityQuestionOption> likert5 = [
  PersonalityQuestionOption(text: "Strongly Disagree", value: 1),
  PersonalityQuestionOption(text: "Disagree", value: 2),
  PersonalityQuestionOption(text: "Neutral", value: 3),
  PersonalityQuestionOption(text: "Agree", value: 4),
  PersonalityQuestionOption(text: "Strongly Agree", value: 5),
];

/// ------------------------------
/// Track B: Goal Routing (product profile)
/// ------------------------------

final List<PersonalityQuestion> goalItems = [
  const PersonalityQuestion(
    id: "G1",
    question:
        "What's your main goal in using tone and attachment analysis right now?",
    isGoal: true,
    options: [
      PersonalityQuestionOption(
          text: "New connection or dating",
          value: 4,
          routeTag: "dating_sensitive"),
      PersonalityQuestionOption(
          text: "Repairing or deepening an existing relationship",
          value: 4,
          routeTag: "empathetic_mirror"),
      PersonalityQuestionOption(
          text: "Staying consistent and becoming more secure",
          value: 4,
          routeTag: "secure_training"),
      PersonalityQuestionOption(
          text: "Managing co-parenting communication",
          value: 4,
          routeTag: "coparenting_support"),
      PersonalityQuestionOption(
          text: "Getting through tough conversations better",
          value: 4,
          routeTag: "boundary_forward"),
    ],
  ),
  const PersonalityQuestion(
    id: "G2",
    question:
        "Do you find yourself feeling emotionally distant or disconnected in your current relationship?",
    isGoal: true,
    options: [
      PersonalityQuestionOption(
          text: "Yes, often", value: 5, routeTag: "dating_sensitive"),
      PersonalityQuestionOption(
          text: "Sometimes", value: 4, routeTag: "empathetic_mirror"),
      PersonalityQuestionOption(
          text: "Rarely", value: 2, routeTag: "secure_training"),
      PersonalityQuestionOption(
          text: "No, not at all", value: 1, routeTag: "empathetic_mirror"),
    ],
  ),
  const PersonalityQuestion(
    id: "G3",
    question:
        "Do you tend to avoid conflict or shut down during difficult conversations?",
    isGoal: true,
    options: [
      PersonalityQuestionOption(
          text: "Yes, I always avoid conflict",
          value: 5,
          routeTag: "deescalator"),
      PersonalityQuestionOption(
          text: "I often shut down", value: 4, routeTag: "coparenting_support"),
      PersonalityQuestionOption(
          text: "Sometimes I avoid it",
          value: 3,
          routeTag: "empathetic_mirror"),
      PersonalityQuestionOption(
          text: "No, I engage with difficult conversations",
          value: 1,
          routeTag: "boundary_forward"),
    ],
  ),
  const PersonalityQuestion(
    id: "G4",
    question:
        "Are you often the one trying to repair or bring things back together after conflict?",
    isGoal: true,
    options: [
      PersonalityQuestionOption(
          text: "Yes, always me", value: 5, routeTag: "empathetic_mirror"),
      PersonalityQuestionOption(
          text: "Usually me", value: 4, routeTag: "empathetic_mirror"),
      PersonalityQuestionOption(
          text: "Sometimes", value: 3, routeTag: "empathetic_mirror"),
      PersonalityQuestionOption(
          text: "No, we both work on it",
          value: 2,
          routeTag: "secure_training"),
    ],
  ),
  const PersonalityQuestion(
    id: "G5",
    question:
        "Are you currently trying to build a connection with someone new?",
    isGoal: true,
    options: [
      PersonalityQuestionOption(
          text: "Yes, actively dating", value: 5, routeTag: "dating_sensitive"),
      PersonalityQuestionOption(
          text: "Yes, new relationship",
          value: 4,
          routeTag: "dating_sensitive"),
      PersonalityQuestionOption(
          text: "No, focusing on existing relationships",
          value: 2,
          routeTag: "empathetic_mirror"),
      PersonalityQuestionOption(
          text: "No, single and not dating",
          value: 1,
          routeTag: "secure_training"),
    ],
  ),
  const PersonalityQuestion(
    id: "G6",
    question:
        "Do you want to focus on how to express your emotions more clearly and vulnerably?",
    isGoal: true,
    options: [
      PersonalityQuestionOption(
          text: "Yes, definitely", value: 5, routeTag: "empathetic_mirror"),
      PersonalityQuestionOption(
          text: "Yes, somewhat", value: 4, routeTag: "empathetic_mirror"),
      PersonalityQuestionOption(
          text: "Maybe", value: 3, routeTag: "empathetic_mirror"),
      PersonalityQuestionOption(
          text: "No, I'm comfortable with my expression",
          value: 1,
          routeTag: "secure_training"),
    ],
  ),
  const PersonalityQuestion(
    id: "G7",
    question:
        "Are you navigating a challenging topic right now (like boundaries, needs, or big changes)?",
    isGoal: true,
    options: [
      PersonalityQuestionOption(
          text: "Yes, very challenging topics",
          value: 5,
          routeTag: "boundary_forward"),
      PersonalityQuestionOption(
          text: "Yes, some difficult conversations",
          value: 4,
          routeTag: "deescalator"),
      PersonalityQuestionOption(
          text: "Maybe some smaller issues",
          value: 3,
          routeTag: "empathetic_mirror"),
      PersonalityQuestionOption(
          text: "No, things are stable", value: 1, routeTag: "secure_training"),
    ],
  ),
  const PersonalityQuestion(
    id: "G8",
    question:
        "Is your co-parenting communication more about logistics or emotional conflict?",
    isGoal: true,
    options: [
      PersonalityQuestionOption(
          text: "Mostly logistics", value: 3, routeTag: "coparenting_support"),
      PersonalityQuestionOption(
          text: "Mix of both", value: 3, routeTag: "coparenting_support"),
      PersonalityQuestionOption(
          text: "Mostly emotional conflict",
          value: 4,
          routeTag: "empathetic_mirror"),
      PersonalityQuestionOption(
          text: "Not applicable - no co-parenting",
          value: 1,
          routeTag: "empathetic_mirror"),
    ],
  ),
  const PersonalityQuestion(
    id: "G9",
    question:
        "Would you prefer gentle daily check-ins to help regulate tone, even in casual texts?",
    isGoal: true,
    options: [
      PersonalityQuestionOption(
          text: "Yes, that sounds helpful", value: 5, routeTag: "balanced"),
      PersonalityQuestionOption(
          text: "Maybe occasionally", value: 3, routeTag: "secure_training"),
      PersonalityQuestionOption(
          text: "Not really needed", value: 2, routeTag: "empathetic_mirror"),
      PersonalityQuestionOption(
          text: "No, I prefer minimal intervention",
          value: 1,
          routeTag: "deescalator"),
    ],
  ),
  const PersonalityQuestion(
    id: "G10",
    question:
        "Would you describe your tone goal as: more clarity, more warmth, or more calm?",
    isGoal: true,
    options: [
      PersonalityQuestionOption(
          text: "More clarity", value: 5, routeTag: "boundary_forward"),
      PersonalityQuestionOption(
          text: "More warmth", value: 5, routeTag: "dating_sensitive"),
      PersonalityQuestionOption(
          text: "More calm", value: 5, routeTag: "secure_training"),
      PersonalityQuestionOption(
          text: "All of the above", value: 4, routeTag: "empathetic_mirror"),
    ],
  ),
];

/// ------------------------------
/// Scoring models & outputs
/// ------------------------------

class AttachmentScores {
  final int anxiety; // 0..100
  final int avoidance; // 0..100
  final double reliabilityAlpha; // Cronbach's alpha across 12 scored items
  final bool attentionPassed;
  final double socialDesirability; // 0..1 (higher means more idealized)
  final bool disorganizedLean;
  final String
      quadrant; // "secure", "anxious", "avoidant", "disorganized_lean", "mixed"
  final String confidenceLabel; // "High", "Moderate", "Cautious"

  const AttachmentScores({
    required this.anxiety,
    required this.avoidance,
    required this.reliabilityAlpha,
    required this.attentionPassed,
    required this.socialDesirability,
    required this.disorganizedLean,
    required this.quadrant,
    required this.confidenceLabel,
  });

  @override
  String toString() =>
      "A:$anxiety V:$avoidance α:${reliabilityAlpha.toStringAsFixed(2)} "
      "attn:${attentionPassed ? 'ok' : 'fail'} "
      "SD:${socialDesirability.toStringAsFixed(2)} "
      "disorg:${disorganizedLean ? 'yes' : 'no'} "
      "quad:$quadrant conf:$confidenceLabel";
}

class GoalRoutingResult {
  final Set<String> routeTags; // unique tag set from selections
  final String primaryProfile; // derived from routeTags (simple heuristic)

  const GoalRoutingResult(
      {required this.routeTags, required this.primaryProfile});
}

class AttachmentAssessment {
  /// Main entry: provide responses and receive full outputs.
  ///
  /// `responses` = map of questionId -> value(1..5).
  /// You can pass a single combined map for both tracks; the scorer will pull what it needs.
  static ({AttachmentScores scores, GoalRoutingResult routing}) run(
    Map<String, int> responses,
  ) {
    final scores = _scoreAttachment(responses);
    final routing = _routeGoals(responses);
    return (scores: scores, routing: routing);
  }

  /// ------------------------------
  /// Attachment scoring
  /// ------------------------------
  static AttachmentScores _scoreAttachment(Map<String, int> responses) {
    // 1) Extract scored items (12 core)
    final core = attachmentItems.where((q) =>
        (q.dimension == Dimension.anxiety ||
            q.dimension == Dimension.avoidance) &&
        !q.isAttentionCheck &&
        !q.isSocialDesirability);

    // Compute reversed-coded values and split by dimension
    final List<double> scoredAll = [];
    final List<double> scoredAnx = [];
    final List<double> scoredAvd = [];

    double anxSum = 0, anxW = 0, avdSum = 0, avdW = 0;

    for (final q in core) {
      final raw = (responses[q.id] ?? 3).toDouble().clamp(1, 5);
      final val = q.reversed ? (6 - raw) : raw;
      final w = q.weight;

      // z-score approximate: mean=3, sd≈1.118 for uniform Likert; we'll standardize later via alpha calc.
      // For final 0–100 scaling we'll convert with a normal-ish mapping.
      if (q.dimension == Dimension.anxiety) {
        anxSum += val * w;
        anxW += w;
        scoredAnx.add(val.toDouble());
      } else if (q.dimension == Dimension.avoidance) {
        avdSum += val * w;
        avdW += w;
        scoredAvd.add(val.toDouble());
      }
      scoredAll.add(val.toDouble());
    }

    // 2) Map to 0–100 (centered on 50). Use linear mapping against 1..5:
    // 1 -> 0, 3 -> 50, 5 -> 100
    double map100(double m) => ((m - 1.0) / 4.0 * 100.0).clamp(0, 100);
    final anxMean = (anxSum / max(anxW, 1e-6));
    final avdMean = (avdSum / max(avdW, 1e-6));
    int anxiety = map100(anxMean).round();
    int avoidance = map100(avdMean).round();

    // 3) Reliability (Cronbach's alpha) across the 12 core items
    final alpha = _cronbachAlpha(scoredAll);

    // 4) Attention check
    final attnVal = responses["CHK_ATTEN"];
    final attentionPassed = (attnVal == 4); // "Agree" per instruction

    // 5) Social desirability (mean of SD items -> normalize to 0..1)
    final sdVals =
        ["SD1", "SD2"].map((id) => (responses[id] ?? 3).toDouble()).toList();
    final sdMean =
        sdVals.isEmpty ? 3.0 : sdVals.reduce((a, b) => a + b) / sdVals.length;
    final socialDesirability = ((sdMean - 1.0) / 4.0).clamp(0.0, 1.0);

    // 6) Disorganized-leaning flag: both high + paradox endorsement
    final paradox = (responses["PX1"] ?? 3);
    final disorganizedLean = (anxiety >= 60 && avoidance >= 60 && paradox >= 4);

    // 7) Quadrant mapping with gray zones (45–55)
    final quadrant = _quadrant(anxiety, avoidance, disorganizedLean);

    // 8) Confidence label
    final conf = _confidenceLabel(alpha, anxiety, avoidance);

    return AttachmentScores(
      anxiety: anxiety,
      avoidance: avoidance,
      reliabilityAlpha: alpha,
      attentionPassed: attentionPassed,
      socialDesirability: socialDesirability,
      disorganizedLean: disorganizedLean,
      quadrant: quadrant,
      confidenceLabel: conf,
    );
  }

  static double _cronbachAlpha(List<double> items) {
    // We need item variances and total variance across the vector-of-items per person.
    // Here we approximate alpha across items by simulating a "scale" as the sum of items
    // and computing alpha with the item-wise variance set:
    //
    // alpha = k/(k-1) * (1 - sum(Var(item_i)) / Var(totalScore))
    //
    // Since we only have a single respondent vector here, we approximate variance by
    // expected Likert variance stabilization: we'll compute across-item variance
    // using deviations from the item mean. For small k, this is a rough proxy.
    //
    final k = items.length;
    if (k < 3) return 0.0;

    // item variances (with ddof=1 guard)
    double varOf(List<double> xs) {
      if (xs.length < 2) return 0.0;
      final m = xs.reduce((a, b) => a + b) / xs.length;
      double s2 = 0.0;
      for (final x in xs) {
        s2 += pow(x - m, 2).toDouble();
      }
      return s2 / (xs.length - 1);
    }

    // For this single profile, we treat each item as a "variable" and estimate variance across items
    // by assuming typical dispersion per Likert; to keep it deterministic, compute the observed variance
    // of items themselves and scale.
    // Better: approximate item variance by local neighborhood (here we just use a mild constant).
    // To keep alpha within a usable range, we derive totalScore variance via a heuristic:
    final acrossItemVar = varOf(items);
    // Sane floor so alpha doesn't blow up:
    final assumedItemVar = max(0.5, acrossItemVar);
    final sumItemVar = assumedItemVar * k;

    // Approximate variance of the sum:
    final varTotal = max(sumItemVar * 0.8, 1.0); // conservative coupling

    final alpha = (k / (k - 1)) * (1 - (sumItemVar / varTotal));
    // Clamp to [0, 1]
    return alpha.clamp(0.0, 1.0);
  }

  static String _quadrant(int anxiety, int avoidance, bool disorg) {
    if (disorg) return "disorganized_lean";

    final aHigh = anxiety >= 55, aLow = anxiety < 45;
    final vHigh = avoidance >= 55, vLow = avoidance < 45;

    if (aLow && vLow) return "secure";
    if (aHigh && !vHigh) return "anxious";
    if (vHigh && !aHigh) return "avoidant";

    return "mixed"; // gray zones or cross-over without paradox flag
  }

  static String _confidenceLabel(double alpha, int anxiety, int avoidance) {
    // Lower confidence in gray zones or low alpha
    final grayA = (anxiety >= 45 && anxiety <= 55);
    final grayV = (avoidance >= 45 && avoidance <= 55);
    if (alpha >= 0.75 && !(grayA || grayV)) return "High";
    if (alpha >= 0.60) return "Moderate";
    return "Cautious";
  }

  /// ------------------------------
  /// Goal routing
  /// ------------------------------
  static GoalRoutingResult _routeGoals(Map<String, int> responses) {
    final Set<String> tags = {};
    for (final q in goalItems) {
      final val = responses[q.id];
      if (val == null) continue;
      // Find the chosen option (by exact value match OR closest by index if needed)
      // In a real UI, you'd map by index/option id, but we keep it simple here.
      PersonalityQuestionOption? chosen;
      // Prefer exact value match:
      for (final opt in q.options) {
        if (opt.value == val) {
          chosen = opt;
          break;
        }
      }
      chosen ??= q.options.isNotEmpty
          ? q.options[min(val - 1, q.options.length - 1)]
          : null;
      if (chosen?.routeTag != null) tags.add(chosen!.routeTag!);
    }

    final primary = _primaryProfileFrom(tags);
    return GoalRoutingResult(routeTags: tags, primaryProfile: primary);
  }

  static String _primaryProfileFrom(Set<String> tags) {
    if (tags.contains("coparenting_support")) return "coparenting_support";
    if (tags.contains("boundary_forward")) return "boundary_forward";
    if (tags.contains("dating_sensitive")) return "dating_sensitive";
    if (tags.contains("secure_training")) return "secure_training";
    if (tags.contains("deescalator")) return "deescalator";
    if (tags.contains("empathetic_mirror")) return "empathetic_mirror";
    if (tags.contains("balanced")) return "balanced";
    // Default fallback:
    return "secure_training";
  }
}

/// ------------------------------
/// Example of how to use
/// ------------------------------
///
/// final responses = <String,int>{
///   // --- Attachment core (12 items) ---
///   "A1": 4, "A2": 3, "A3": 4, "A4": 2, "A5": 2, "A6": 4,
///   "V1": 3, "V2": 3, "V3": 3, "V4": 4, "V5": 4, "V6": 4,
///   // Checks (optional but recommended)
///   "CHK_ATTEN": 4, "SD1": 4, "SD2": 3, "PX1": 4,
///   // --- Goals ---
///   "G1": 4, "G2": 3, "G3": 1, "G4": 4, "G5": 1,
///   "G6": 4, "G7": 3, "G8": 3, "G9": 5, "G10": 5,
/// };
///
/// final result = AttachmentAssessment.run(responses);
/// print(result.scores);  // full scoring summary
/// print(result.routing.primaryProfile); // e.g., "boundary_forward"
///
/// You can now:
/// - Feed `result.routing.primaryProfile` into multiplier.json selection
/// - Use `result.scores.quadrant` for attachment_overrides.json
/// - Gate suggestion intensity via `result.scores.reliabilityAlpha` and confidenceLabel
