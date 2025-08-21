// assessment_integration.dart
// Unsaid - Integration adapter for AttachmentAssessment with existing JSON configs
//
// Converts attachment_assessment.dart results into:
// - weight_modifiers.json profile selection
// - attachment_overrides.json quadrant mapping
// - guardrails_config.json profile selection
// - confidence-based gating and fallback logic
// ------------------------------------------------------------

import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'attachment_assessment.dart';

class MergedConfig {
  final Map<String, dynamic> weightModifiers;
  final Map<String, dynamic> attachmentOverrides;
  final Map<String, dynamic> guardrailsConfig;
  final String primaryProfile;
  final String attachmentQuadrant;
  final String confidenceLevel;
  final bool recommendationGating;
  final double reliabilityScore;

  const MergedConfig({
    required this.weightModifiers,
    required this.attachmentOverrides,
    required this.guardrailsConfig,
    required this.primaryProfile,
    required this.attachmentQuadrant,
    required this.confidenceLevel,
    required this.recommendationGating,
    required this.reliabilityScore,
  });

  @override
  String toString() =>
      "MergedConfig(profile:$primaryProfile, quad:$attachmentQuadrant, "
      "conf:$confidenceLevel, gated:$recommendationGating, α:${reliabilityScore.toStringAsFixed(2)})";
}

class AssessmentIntegration {
  static Map<String, dynamic>? _weightModifiersCache;
  static Map<String, dynamic>? _attachmentOverridesCache;
  static Map<String, dynamic>? _guardrailsConfigCache;

  /// Main integration: from assessment results to merged configuration
  static Future<MergedConfig> selectConfiguration(
    AttachmentScores scores,
    GoalRoutingResult routing, {
    String configPath = 'data/',
  }) async {
    // Load JSON configs (cached)
    final weightModifiers = await _loadWeightModifiers(configPath);
    final attachmentOverrides = await _loadAttachmentOverrides(configPath);
    final guardrailsConfig = await _loadGuardrailsConfig(configPath);

    // Select primary profile from weight_modifiers.json
    final primaryProfile = routing.primaryProfile;
    final selectedWeightProfile = _selectWeightModifierProfile(
      weightModifiers, 
      primaryProfile,
    );

    // Map attachment quadrant to attachment_overrides.json
    final attachmentQuadrant = scores.quadrant;
    final selectedAttachmentOverride = _selectAttachmentOverride(
      attachmentOverrides,
      attachmentQuadrant,
    );

    // Select guardrail profile based on combined signals
    final guardrailProfile = _selectGuardrailProfile(
      scores,
      routing,
      primaryProfile,
    );
    final selectedGuardrailConfig = _selectGuardrailConfigProfile(
      guardrailsConfig,
      guardrailProfile,
    );

    // Determine recommendation gating based on reliability and attention
    final recommendationGating = _shouldGateRecommendations(scores);

    return MergedConfig(
      weightModifiers: selectedWeightProfile,
      attachmentOverrides: selectedAttachmentOverride,
      guardrailsConfig: selectedGuardrailConfig,
      primaryProfile: primaryProfile,
      attachmentQuadrant: attachmentQuadrant,
      confidenceLevel: scores.confidenceLabel,
      recommendationGating: recommendationGating,
      reliabilityScore: scores.reliabilityAlpha,
    );
  }

  /// Quick helper: run assessment and return merged config in one call
  static Future<MergedConfig> runAndMerge(
    Map<String, int> responses, {
    String configPath = 'data/',
  }) async {
    final result = AttachmentAssessment.run(responses);
    return await selectConfiguration(
      result.scores,
      result.routing,
      configPath: configPath,
    );
  }

  // ===============================
  // JSON Loading (with caching)
  // ===============================

  static Future<Map<String, dynamic>> _loadWeightModifiers(String configPath) async {
    if (_weightModifiersCache != null) return _weightModifiersCache!;
    
    try {
      // Try to load from assets first (Flutter app context)
      final String jsonString = await rootBundle.loadString('${configPath}weight_modifiers.json');
      _weightModifiersCache = json.decode(jsonString);
    } catch (e) {
      // Fallback to file system (for testing or standalone Dart)
      final file = File('${configPath}weight_modifiers.json');
      final jsonString = await file.readAsString();
      _weightModifiersCache = json.decode(jsonString);
    }
    
    return _weightModifiersCache!;
  }

  static Future<Map<String, dynamic>> _loadAttachmentOverrides(String configPath) async {
    if (_attachmentOverridesCache != null) return _attachmentOverridesCache!;
    
    try {
      final String jsonString = await rootBundle.loadString('${configPath}attachment_overrides.json');
      _attachmentOverridesCache = json.decode(jsonString);
    } catch (e) {
      final file = File('${configPath}attachment_overrides.json');
      final jsonString = await file.readAsString();
      _attachmentOverridesCache = json.decode(jsonString);
    }
    
    return _attachmentOverridesCache!;
  }

  static Future<Map<String, dynamic>> _loadGuardrailsConfig(String configPath) async {
    if (_guardrailsConfigCache != null) return _guardrailsConfigCache!;
    
    try {
      final String jsonString = await rootBundle.loadString('${configPath}guardrails_config.json');
      _guardrailsConfigCache = json.decode(jsonString);
    } catch (e) {
      final file = File('${configPath}guardrails_config.json');
      final jsonString = await file.readAsString();
      _guardrailsConfigCache = json.decode(jsonString);
    }
    
    return _guardrailsConfigCache!;
  }

  // ===============================
  // Profile Selection Logic
  // ===============================

  static Map<String, dynamic> _selectWeightModifierProfile(
    Map<String, dynamic> weightModifiers,
    String primaryProfile,
  ) {
    final profiles = weightModifiers['profiles'] as Map<String, dynamic>? ?? {};
    
    // Direct match first
    if (profiles.containsKey(primaryProfile)) {
      return Map<String, dynamic>.from(profiles[primaryProfile]);
    }

    // Fallback mappings for any mismatches
    final fallbackMap = {
      'dating_sensitive': 'dating_sensitive',
      'empathetic_mirror': 'empathetic_mirror',
      'secure_training': 'secure_training',
      'coparenting_support': 'coparenting_support',
      'boundary_forward': 'boundary_forward',
      'deescalator': 'deescalator',
      'balanced': 'balanced',
    };

    final fallbackProfile = fallbackMap[primaryProfile] ?? 'balanced';
    
    if (profiles.containsKey(fallbackProfile)) {
      return Map<String, dynamic>.from(profiles[fallbackProfile]);
    }

    // Ultimate fallback to 'balanced' or first available profile
    if (profiles.containsKey('balanced')) {
      return Map<String, dynamic>.from(profiles['balanced']);
    }

    return profiles.isNotEmpty 
        ? Map<String, dynamic>.from(profiles.values.first)
        : <String, dynamic>{};
  }

  static Map<String, dynamic> _selectAttachmentOverride(
    Map<String, dynamic> attachmentOverrides,
    String attachmentQuadrant,
  ) {
    final overrides = attachmentOverrides['overrides'] as Map<String, dynamic>? ?? {};
    
    // Map our quadrant names to attachment_overrides.json keys
    final quadrantMap = {
      'secure': 'secure',
      'anxious': 'anxious',
      'avoidant': 'avoidant',
      'disorganized_lean': 'disorganized',
      'mixed': 'secure', // Default mixed to secure override
    };

    final mappedQuadrant = quadrantMap[attachmentQuadrant] ?? 'secure';
    
    if (overrides.containsKey(mappedQuadrant)) {
      return Map<String, dynamic>.from(overrides[mappedQuadrant]);
    }

    // Fallback to secure
    if (overrides.containsKey('secure')) {
      return Map<String, dynamic>.from(overrides['secure']);
    }

    return <String, dynamic>{};
  }

  static String _selectGuardrailProfile(
    AttachmentScores scores,
    GoalRoutingResult routing,
    String primaryProfile,
  ) {
    // Logic to select appropriate guardrail profile based on:
    // - Reliability/confidence
    // - Social desirability
    // - Attachment style
    // - Primary profile needs

    // High social desirability + low reliability = high_sensitivity
    if (scores.socialDesirability > 0.7 && scores.reliabilityAlpha < 0.6) {
      return 'high_sensitivity';
    }

    // Repair-focused profiles prefer repair_mode
    if (primaryProfile == 'empathetic_mirror' || 
        routing.routeTags.contains('empathetic_mirror')) {
      return 'repair_mode';
    }

    // Boundary profiles prefer assertive_moderator
    if (primaryProfile == 'boundary_forward' || 
        routing.routeTags.contains('boundary_forward')) {
      return 'assertive_moderator';
    }

    // Avoidant style + good reliability = low_reactivity
    if (scores.quadrant == 'avoidant' && scores.reliabilityAlpha > 0.65) {
      return 'low_reactivity';
    }

    // High anxiety = high_sensitivity
    if (scores.anxiety > 70) {
      return 'high_sensitivity';
    }

    // Default to balanced approach
    return 'high_sensitivity'; // Conservative default
  }

  static Map<String, dynamic> _selectGuardrailConfigProfile(
    Map<String, dynamic> guardrailsConfig,
    String guardrailProfile,
  ) {
    final profiles = guardrailsConfig['profiles'] as Map<String, dynamic>? ?? {};
    final defaults = guardrailsConfig['defaults'] as Map<String, dynamic>? ?? {};
    
    if (profiles.containsKey(guardrailProfile)) {
      // Merge defaults with profile-specific overrides
      final profileConfig = Map<String, dynamic>.from(defaults);
      final profileOverrides = profiles[guardrailProfile] as Map<String, dynamic>;
      
      // Apply deltas if present
      if (profileOverrides.containsKey('deltas')) {
        final deltas = profileOverrides['deltas'] as Map<String, dynamic>;
        for (final entry in deltas.entries) {
          if (entry.value is num) {
            final currentValue = profileConfig[entry.key] as num? ?? 0;
            profileConfig[entry.key] = currentValue + entry.value;
          }
        }
      }

      // Merge other profile settings
      for (final entry in profileOverrides.entries) {
        if (entry.key != 'deltas' && entry.key != 'notes') {
          profileConfig[entry.key] = entry.value;
        }
      }

      return profileConfig;
    }

    return Map<String, dynamic>.from(defaults);
  }

  static bool _shouldGateRecommendations(AttachmentScores scores) {
    // Gate recommendations if:
    // - Attention check failed
    // - Very low reliability
    // - Extreme social desirability (fake good)
    
    if (!scores.attentionPassed) return true;
    if (scores.reliabilityAlpha < 0.5) return true;
    if (scores.socialDesirability > 0.85) return true;
    
    // Cautious confidence level should gate more aggressive suggestions
    if (scores.confidenceLabel == 'Cautious') return true;
    
    return false;
  }

  // ===============================
  // Utility methods
  // ===============================

  /// Get recommendation intensity multiplier based on confidence
  static double getIntensityMultiplier(AttachmentScores scores) {
    switch (scores.confidenceLabel) {
      case 'High':
        return 1.0;
      case 'Moderate':
        return 0.85;
      case 'Cautious':
        return 0.7;
      default:
        return 0.6;
    }
  }

  /// Check if we should show attachment insights to user
  static bool shouldShowAttachmentInsights(AttachmentScores scores) {
    return scores.attentionPassed && 
           scores.reliabilityAlpha > 0.6 && 
           scores.socialDesirability < 0.8;
  }

  /// Get user-friendly attachment description
  static String getAttachmentDescription(String quadrant) {
    switch (quadrant) {
      case 'secure':
        return 'You tend to feel comfortable with intimacy and autonomy in relationships.';
      case 'anxious':
        return 'You may sometimes worry about relationships and seek reassurance from partners.';
      case 'avoidant':
        return 'You tend to value independence and may sometimes feel uncomfortable with too much closeness.';
      case 'disorganized_lean':
        return 'You may experience mixed feelings about closeness and distance in relationships.';
      case 'mixed':
        return 'Your attachment patterns show some variability across different relationship contexts.';
      default:
        return 'Your attachment patterns are still being understood.';
    }
  }

  /// Clear all caches (useful for testing or config updates)
  static void clearCaches() {
    _weightModifiersCache = null;
    _attachmentOverridesCache = null;
    _guardrailsConfigCache = null;
  }
}

/// Example usage:
///
/// ```dart
/// final responses = <String, int>{
///   // ... user's assessment responses
/// };
/// 
/// final config = await AssessmentIntegration.runAndMerge(responses);
/// 
/// // Now you have:
/// print('Primary profile: ${config.primaryProfile}');
/// print('Attachment: ${config.attachmentQuadrant}');
/// print('Confidence: ${config.confidenceLevel}');
/// print('Should gate: ${config.recommendationGating}');
/// 
/// // Use the merged configs in your ML pipeline:
/// final weightMultipliers = config.weightModifiers;
/// final attachmentSettings = config.attachmentOverrides;
/// final guardrailSettings = config.guardrailsConfig;
/// 
/// // Apply intensity gating:
/// final intensity = AssessmentIntegration.getIntensityMultiplier(scores);
/// 
/// // Show insights to user if appropriate:
/// if (AssessmentIntegration.shouldShowAttachmentInsights(scores)) {
///   final description = AssessmentIntegration.getAttachmentDescription(config.attachmentQuadrant);
///   // ... show to user
/// }
/// ```
