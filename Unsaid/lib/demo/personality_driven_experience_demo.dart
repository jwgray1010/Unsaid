import '../services/personality_driven_analyzer.dart';

/// Demo script showing how personality-driven analyzer creates unique experiences
class PersonalityDrivenExperienceDemo {
  static final PersonalityDrivenAnalyzer _analyzer =
      PersonalityDrivenAnalyzer();

  static Future<void> runDemo() async {
    print('🎯 PERSONALITY-DRIVEN ANALYZER DEMO');
    print('=====================================');

    // Demo 1: Individual Anxious Attachment experience
    print('\n📊 DEMO 1: Individual Anxious Attachment Experience');
    print('------------------------------------------------');
    await _demoIndividualExperience('A', 'passive');

    // Demo 2: Individual Secure Attachment experience
    print('\n📊 DEMO 2: Individual Secure Attachment Experience');
    print('--------------------------------------------------');
    await _demoIndividualExperience('B', 'assertive');

    // Demo 3: Individual Dismissive Avoidant experience
    print('\n📊 DEMO 3: Individual Dismissive Avoidant Experience');
    print('-----------------------------------------------');
    await _demoIndividualExperience('C', 'passive');

    // Demo 4: Couple experience - Anxious + Secure
    print('\n💑 DEMO 4: Couple Experience - Anxious + Secure');
    print('---------------------------------------------');
    await _demoCoupleExperience('A', 'passive', 'B', 'assertive');

    // Demo 5: Couple experience - Anxious + Avoidant (challenging)
    print('\n💑 DEMO 5: Couple Experience - Anxious + Avoidant');
    print('----------------------------------------------');
    await _demoCoupleExperience('A', 'passive', 'C', 'passive');

    // Demo 6: Couple experience - Secure + Secure (ideal)
    print('\n💑 DEMO 6: Couple Experience - Secure + Secure');
    print('--------------------------------------------');
    await _demoCoupleExperience('B', 'assertive', 'B', 'assertive');

    print('\n✅ PERSONALITY-DRIVEN ANALYZER DEMO COMPLETE!');
  }

  static Future<void> _demoIndividualExperience(
    String personalityType,
    String communicationStyle,
  ) async {
    final experience = await _analyzer.generatePersonalizedExperience(
      personalityType: personalityType,
      communicationStyle: communicationStyle,
    );

    _printPersonalityProfile(experience);
    _printAnalyzerSettings(experience);
    _printCoachingApproach(experience);
    _printUICustomization(experience);
  }

  static Future<void> _demoCoupleExperience(
    String userPersonality,
    String userCommunication,
    String partnerPersonality,
    String partnerCommunication,
  ) async {
    final experience = await _analyzer.generatePersonalizedExperience(
      personalityType: userPersonality,
      communicationStyle: userCommunication,
      partnerPersonalityType: partnerPersonality,
      partnerCommunicationStyle: partnerCommunication,
    );

    _printCoupleCompatibility(experience);
    _printCoupleSpecificFeatures(experience);
  }

  static void _printPersonalityProfile(Map<String, dynamic> experience) {
    final profile = experience['personality_profile'];
    print('🧠 PERSONALITY PROFILE:');
    print('  Type: ${profile['label']}');
    print('  Description: ${profile['description']}');
    print('  Strengths: ${profile['strengths'].join(', ')}');
    print('  Challenges: ${profile['challenges'].join(', ')}');
    print('  Growth Areas: ${profile['growth_areas'].join(', ')}');
    print('  Analyzer Focus: ${profile['analyzer_focus']}');
  }

  static void _printAnalyzerSettings(Map<String, dynamic> experience) {
    final settings = experience['analyzer_settings'];
    print('\n⚙️  PERSONALIZED ANALYZER SETTINGS:');
    print('  Sensitivity Level: ${settings['sensitivity_level']}');
    print('  Feedback Style: ${settings['feedback_style']}');
    print('  Suggestion Frequency: ${settings['suggestion_frequency']}');
    print('  Warning Threshold: ${settings['warning_threshold']}');

    // Show personality-specific features
    if (settings['reassurance_mode'] == true) {
      print('  ✨ Special: Reassurance Mode Active');
    }
    if (settings['connection_encouragement'] == true) {
      print('  ✨ Special: Connection Encouragement Active');
    }
    if (settings['consistency_coaching'] == true) {
      print('  ✨ Special: Consistency Coaching Active');
    }
    if (settings['assertiveness_coaching'] == true) {
      print('  ✨ Special: Assertiveness Coaching Active');
    }
  }

  static void _printCoachingApproach(Map<String, dynamic> experience) {
    final coaching = experience['coaching_approach'];
    print('\n🎯 PERSONALIZED COACHING APPROACH:');
    print('  Primary Focus: ${coaching['primary_focus']}');
    print('  Coaching Style: ${coaching['coaching_style']}');
    print(
      '  Intervention Triggers: ${coaching['intervention_triggers'].join(', ')}',
    );
    print('  Growth Exercises: ${coaching['growth_exercises'].join(', ')}');
  }

  static void _printUICustomization(Map<String, dynamic> experience) {
    final ui = experience['ui_customization'];
    print('\n🎨 UI CUSTOMIZATION:');
    print('  Theme: ${ui['theme_name']}');
    print('  Layout Style: ${ui['layout_style']}');
    print('  Feedback Display: ${ui['feedback_display']}');
    print('  Animation Style: ${ui['animation_style']}');
    print('  Notification Style: ${ui['notification_style']}');
  }

  static void _printCoupleCompatibility(Map<String, dynamic> experience) {
    if (!experience.containsKey('couple_experience')) return;

    final coupleExp = experience['couple_experience'];
    final compatibility = coupleExp['compatibility'];

    print('💕 COUPLE COMPATIBILITY ANALYSIS:');
    print(
      '  Compatibility Score: ${((compatibility['compatibility_score'] as double) * 100).toInt()}%',
    );
    print('  Compatibility Level: ${compatibility['compatibility_level']}');
    print('  Relationship Strengths: ${compatibility['strengths'].join(', ')}');
    print(
      '  Relationship Challenges: ${compatibility['challenges'].join(', ')}',
    );
    print('  Recommendations: ${compatibility['recommendations'].join(', ')}');
  }

  static void _printCoupleSpecificFeatures(Map<String, dynamic> experience) {
    if (!experience.containsKey('couple_experience')) return;

    final coupleExp = experience['couple_experience'];

    print('\n🔧 COUPLE-SPECIFIC FEATURES:');

    // Joint growth areas
    if (coupleExp.containsKey('joint_growth_areas')) {
      print(
        '  Joint Growth Areas: ${coupleExp['joint_growth_areas'].join(', ')}',
      );
    }

    // Couple exercises
    if (coupleExp.containsKey('couple_exercises')) {
      print(
        '  Personalized Couple Exercises: ${coupleExp['couple_exercises'].join(', ')}',
      );
    }

    // Communication bridges
    if (coupleExp.containsKey('bridge_strategies')) {
      print('  Communication Bridge Strategies: Available');
    }

    // Challenges and solutions
    if (coupleExp.containsKey('challenges_and_solutions')) {
      final challenges = coupleExp['challenges_and_solutions'];
      print(
        '  Common Challenges: ${challenges['common_challenges'].join(', ')}',
      );
      print(
        '  Communication Challenges: ${challenges['communication_challenges'].join(', ')}',
      );
    }
  }

  static void showPersonalityTypeExplanation() {
    print('\n📖 PERSONALITY TYPES EXPLANATION:');
    print('================================');
    print(
      'A - Anxious Attachment: Craves connection, worries about relationships',
    );
    print('B - Secure Attachment: Balanced, handles conflict well');
    print('C - Dismissive Avoidant: Values independence, processes internally');
    print('D - Disorganized/Fearful Avoidant: Complex, situational communication style');
    print('');
    print('COMMUNICATION STYLES:');
    print('assertive: Direct, respectful communication');
    print('passive: Avoids conflict, may not express needs');
    print('aggressive: Forceful, may disregard others');
    print('passive-aggressive: Indirect, expresses anger subtly');
  }

  static void showUniqueExperienceFeatures() {
    print('\n🌟 UNIQUE EXPERIENCE FEATURES:');
    print('=============================');
    print('');
    print('📊 INDIVIDUAL EXPERIENCES:');
    print(
      '• Anxious Attachment: Reassurance mode, gentle feedback, anxiety management',
    );
    print(
      '• Secure Attachment: Optimization focus, balanced feedback, leadership coaching',
    );
    print(
      '• Dismissive Avoidant: Connection encouragement, respectful prompts, vulnerability coaching',
    );
    print(
      '• Disorganized: Consistency coaching, clear structure, pattern recognition',
    );
    print('');
    print('💑 COUPLE EXPERIENCES:');
    print(
      '• Compatibility Analysis: Detailed scoring based on personality combinations',
    );
    print(
      '• Couple-Specific Challenges: Targeted solutions for personality pairings',
    );
    print('• Joint Growth Areas: Shared development opportunities');
    print(
      '• Communication Bridges: Strategies to connect different communication styles',
    );
    print(
      '• Personalized Exercises: Tailored activities for each couple dynamic',
    );
    print('');
    print('🎨 UI CUSTOMIZATION:');
    print('• Personalized color schemes and themes');
    print('• Adapted layouts for different personality preferences');
    print('• Customized feedback display styles');
    print('• Personality-matched animation and notification styles');
  }
}

// Example of how to use the demo
void main() async {
  PersonalityDrivenExperienceDemo.showPersonalityTypeExplanation();
  PersonalityDrivenExperienceDemo.showUniqueExperienceFeatures();
  await PersonalityDrivenExperienceDemo.runDemo();
}
