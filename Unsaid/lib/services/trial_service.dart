import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service to manage the 7-day free trial period
class TrialService extends ChangeNotifier {
  static final TrialService _instance = TrialService._internal();
  factory TrialService() => _instance;
  TrialService._internal();

  static const String _trialStartKey = 'trial_start_date';
  static const String _trialActiveKey = 'trial_active';
  static const String _subscriptionActiveKey = 'subscription_active';
  static const String _adminModeKey = 'admin_mode_active';
  static const String _returningUserKey = 'returning_user_access';
  static const String _dailySecureFixesUsedKey = 'daily_secure_fixes_used';
  static const String _lastResetDateKey = 'last_daily_reset_date';
  static const int _trialDurationDays = 7;
  static const int _dailySecureFixesLimit = 10;

  DateTime? _trialStartDate;
  bool _isTrialActive = false;
  bool _hasSubscription = false;
  bool _isAdminMode = false;
  bool _isReturningUser = false;
  int _dailySecureFixesUsed = 0;
  DateTime? _lastResetDate;

  /// Gets the trial start date
  DateTime? get trialStartDate => _trialStartDate;

  /// Whether the trial is currently active
  bool get isTrialActive => _isTrialActive;

  /// Whether the user has an active subscription
  bool get hasSubscription => _hasSubscription;

  /// Whether admin mode is active (bypasses all restrictions)
  bool get isAdminMode => _isAdminMode;

  /// Whether the user is a returning user (has used the app before)
  bool get isReturningUser => _isReturningUser;

  /// Whether the user has access to the app (trial, subscription, admin mode, or returning user)
  bool get hasAccess =>
      _isTrialActive || _hasSubscription || _isAdminMode || _isReturningUser;

  /// Daily secure fixes used today
  int get dailySecureFixesUsed => _dailySecureFixesUsed;

  /// Daily secure fixes remaining
  int get dailySecureFixesRemaining => _isAdminMode || _hasSubscription
      ? 999
      : (_dailySecureFixesLimit - _dailySecureFixesUsed)
          .clamp(0, _dailySecureFixesLimit);

  /// Whether user can use secure fixes today
  bool get canUseSecureFixes =>
      _isAdminMode ||
      _hasSubscription ||
      (_isTrialActive && _dailySecureFixesUsed < _dailySecureFixesLimit);

  /// Whether therapy advice is available (unlimited during trial and premium)
  bool get hasTherapyAdviceAccess =>
      _isTrialActive || _hasSubscription || _isAdminMode;

  /// Whether tone analysis is available (available during trial and premium)
  bool get hasToneAnalysisAccess =>
      _isTrialActive || _hasSubscription || _isAdminMode;

  /// Days remaining in trial (0 if expired or no trial)
  int get daysRemaining {
    if (_trialStartDate == null || !_isTrialActive) return 0;

    final now = DateTime.now();
    final trialEnd =
        _trialStartDate!.add(const Duration(days: _trialDurationDays));
    final remaining = trialEnd.difference(now).inDays;

    return remaining > 0 ? remaining : 0;
  }

  /// Hours remaining in trial (for more precise tracking)
  int get hoursRemaining {
    if (_trialStartDate == null || !_isTrialActive) return 0;

    final now = DateTime.now();
    final trialEnd =
        _trialStartDate!.add(const Duration(days: _trialDurationDays));
    final remaining = trialEnd.difference(now).inHours;

    return remaining > 0 ? remaining : 0;
  }

  /// Whether the trial has expired
  bool get isTrialExpired {
    if (_trialStartDate == null) return false;

    final now = DateTime.now();
    final trialEnd =
        _trialStartDate!.add(const Duration(days: _trialDurationDays));

    return now.isAfter(trialEnd) && !_hasSubscription;
  }

  /// Initialize the trial service
  Future<void> initialize() async {
    await _loadTrialState();
    await _checkTrialStatus();
    await _checkDailyReset();
  }

  /// Use one secure fix (decrements daily count)
  Future<bool> useSecureFix() async {
    if (!canUseSecureFixes) {
      return false;
    }

    if (_isAdminMode || _hasSubscription) {
      return true; // Unlimited for premium users
    }

    _dailySecureFixesUsed++;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_dailySecureFixesUsedKey, _dailySecureFixesUsed);

    notifyListeners();
    return true;
  }

  /// Check if daily limits need to be reset
  Future<void> _checkDailyReset() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (_lastResetDate == null || _lastResetDate!.isBefore(today)) {
      await _resetDailyLimits();
    }
  }

  /// Reset daily limits (called automatically at midnight)
  Future<void> _resetDailyLimits() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    _dailySecureFixesUsed = 0;
    _lastResetDate = today;

    await prefs.setInt(_dailySecureFixesUsedKey, 0);
    await prefs.setString(_lastResetDateKey, today.toIso8601String());

    notifyListeners();
  }

  /// Start the free trial
  Future<void> startTrial() async {
    if (_trialStartDate != null) {
      // Trial already started
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();

    _trialStartDate = now;
    _isTrialActive = true;

    await prefs.setString(_trialStartKey, now.toIso8601String());
    await prefs.setBool(_trialActiveKey, true);

    notifyListeners();
  }

  /// Activate subscription (ends trial, starts paid access)
  Future<void> activateSubscription() async {
    final prefs = await SharedPreferences.getInstance();

    _hasSubscription = true;
    _isTrialActive = false;

    await prefs.setBool(_subscriptionActiveKey, true);
    await prefs.setBool(_trialActiveKey, false);

    notifyListeners();
  }

  /// Cancel subscription (user loses access after trial expires)
  Future<void> cancelSubscription() async {
    final prefs = await SharedPreferences.getInstance();

    _hasSubscription = false;

    await prefs.setBool(_subscriptionActiveKey, false);

    // If trial is still active, keep it active
    if (!isTrialExpired && _trialStartDate != null) {
      _isTrialActive = true;
      await prefs.setBool(_trialActiveKey, true);
    }

    notifyListeners();
  }

  /// Deactivate subscription (for testing or cancellation)
  Future<void> deactivateSubscription() async {
    final prefs = await SharedPreferences.getInstance();

    _hasSubscription = false;
    await prefs.setBool(_subscriptionActiveKey, false);

    notifyListeners();
  }

  /// Mark user as returning (has used the app before)
  Future<void> markAsReturningUser() async {
    final prefs = await SharedPreferences.getInstance();

    _isReturningUser = true;
    await prefs.setBool(_returningUserKey, true);

    notifyListeners();
  }

  /// Reset trial (for testing purposes - remove in production)
  Future<void> resetTrial() async {
    if (kDebugMode) {
      final prefs = await SharedPreferences.getInstance();

      await prefs.remove(_trialStartKey);
      await prefs.remove(_trialActiveKey);
      await prefs.remove(_subscriptionActiveKey);
      await prefs.remove(_adminModeKey);
      await prefs.remove(_returningUserKey);
      await prefs.remove(_dailySecureFixesUsedKey);
      await prefs.remove(_lastResetDateKey);

      _trialStartDate = null;
      _isTrialActive = false;
      _hasSubscription = false;
      _isAdminMode = false;
      _isReturningUser = false;
      _dailySecureFixesUsed = 0;
      _lastResetDate = null;

      notifyListeners();
    }
  }

  /// Load trial state from SharedPreferences
  Future<void> _loadTrialState() async {
    final prefs = await SharedPreferences.getInstance();

    final trialStartString = prefs.getString(_trialStartKey);
    if (trialStartString != null) {
      _trialStartDate = DateTime.tryParse(trialStartString);
    }

    _isTrialActive = prefs.getBool(_trialActiveKey) ?? false;
    _hasSubscription = prefs.getBool(_subscriptionActiveKey) ?? false;
    _isAdminMode = prefs.getBool(_adminModeKey) ?? false;
    _isReturningUser = prefs.getBool(_returningUserKey) ?? false;
    _dailySecureFixesUsed = prefs.getInt(_dailySecureFixesUsedKey) ?? 0;

    final lastResetString = prefs.getString(_lastResetDateKey);
    if (lastResetString != null) {
      _lastResetDate = DateTime.tryParse(lastResetString);
    }
  }

  /// Check if trial has expired and update status
  Future<void> _checkTrialStatus() async {
    if (_trialStartDate == null) return;

    final now = DateTime.now();
    final trialEnd =
        _trialStartDate!.add(const Duration(days: _trialDurationDays));

    if (now.isAfter(trialEnd) && !_hasSubscription) {
      // Trial has expired and no subscription
      _isTrialActive = false;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_trialActiveKey, false);

      notifyListeners();
    }
  }

  /// Get trial progress as a percentage (0.0 to 1.0)
  double getTrialProgress() {
    if (_trialStartDate == null) return 0.0;

    final now = DateTime.now();
    final trialStart = _trialStartDate!;
    final trialEnd = trialStart.add(const Duration(days: _trialDurationDays));

    final totalDuration = trialEnd.difference(trialStart).inMilliseconds;
    final elapsed = now.difference(trialStart).inMilliseconds;

    final progress = elapsed / totalDuration;
    return progress.clamp(0.0, 1.0);
  }

  /// Check if user should see subscription prompt
  bool shouldShowSubscriptionPrompt() {
    if (_hasSubscription) return false;
    if (!_isTrialActive) return true;

    // Show prompt when 2 days or less remaining
    return daysRemaining <= 2;
  }

  /// Get subscription prompt message
  String getSubscriptionPromptMessage() {
    if (isTrialExpired) {
      return 'Your free trial has expired. Subscribe to continue using Unsaid.';
    } else if (daysRemaining <= 1) {
      return 'Your trial expires soon. Subscribe now to keep your insights.';
    } else {
      return 'Subscribe to Unsaid Premium for unlimited access.';
    }
  }

  /// Get time remaining as a user-friendly string
  String getTimeRemainingString() {
    if (isTrialExpired) {
      return 'Trial expired';
    }

    if (daysRemaining > 1) {
      return '$daysRemaining days remaining';
    } else if (daysRemaining == 1) {
      return '1 day remaining';
    } else {
      final hours = hoursRemaining;
      if (hours > 1) {
        return '$hours hours remaining';
      } else if (hours == 1) {
        return '1 hour remaining';
      } else {
        return 'Less than 1 hour remaining';
      }
    }
  }

  /// Get detailed trial remaining text for UI
  String getTrialRemainingText() {
    if (isTrialExpired) {
      return 'Trial expired';
    }

    if (daysRemaining > 0) {
      return '$daysRemaining day${daysRemaining == 1 ? '' : 's'} left';
    } else {
      final hours = hoursRemaining;
      if (hours > 0) {
        return '$hours hour${hours == 1 ? '' : 's'} left';
      } else {
        return 'Expires soon';
      }
    }
  }

  /// Enable admin mode (bypasses all trial restrictions)
  Future<void> enableAdminMode() async {
    final prefs = await SharedPreferences.getInstance();

    _isAdminMode = true;
    await prefs.setBool(_adminModeKey, true);

    notifyListeners();
  }

  /// Disable admin mode (re-enables normal trial restrictions)
  Future<void> disableAdminMode() async {
    final prefs = await SharedPreferences.getInstance();

    _isAdminMode = false;
    await prefs.setBool(_adminModeKey, false);

    notifyListeners();
  }

  /// Toggle admin mode (for debugging/testing)
  Future<void> toggleAdminMode() async {
    if (_isAdminMode) {
      await disableAdminMode();
    } else {
      await enableAdminMode();
    }
  }

  /// Check if admin mode should be available (debug mode only)
  bool get canAccessAdminMode => kDebugMode;

  /// Enable admin mode for returning users (bypasses all restrictions)
  Future<void> enableAdminModeForReturningUser() async {
    final prefs = await SharedPreferences.getInstance();

    _isAdminMode = true;
    _isReturningUser = true;

    await prefs.setBool(_adminModeKey, true);
    await prefs.setBool(_returningUserKey, true);

    notifyListeners();
  }
}
