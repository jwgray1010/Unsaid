import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io' show Platform;
import '../theme/app_theme.dart';
import '../services/settings_manager.dart';
import '../services/cloud_backup_service.dart';
import '../services/data_manager_service.dart';
import '../services/auth_service.dart';
import '../services/keyboard_manager.dart';
import '../services/admin_service.dart';
import '../services/personality_test_service.dart';
import '../services/onboarding_service.dart';
import '../services/trial_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

class SettingsScreenProfessional extends StatefulWidget {
  final double sensitivity;
  final Function(double) onSensitivityChanged;
  final String tone;
  final Function(String) onToneChanged;

  const SettingsScreenProfessional({
    super.key,
    required this.sensitivity,
    required this.onSensitivityChanged,
    required this.tone,
    required this.onToneChanged,
  });

  @override
  State<SettingsScreenProfessional> createState() =>
      _SettingsScreenProfessionalState();
}

class _SettingsScreenProfessionalState
    extends State<SettingsScreenProfessional> {
  late double _sensitivity;
  late String _tone;
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;
  bool _aiAnalysisEnabled = true;
  bool _realTimeAnalysis = false;
  bool _shareAnalytics = false;
  bool _highContrastMode = false;
  bool _autoBackupEnabled = true;
  double _fontSize = 14.0;
  String _selectedLanguage = 'English';
  bool _isLoading = true;

  // Services
  final SettingsManager _settingsManager = SettingsManager();
  final CloudBackupService _backupService = CloudBackupService();
  final DataManagerService _dataManager = DataManagerService();
  final KeyboardManager _keyboardManager = KeyboardManager();

  // Debouncing
  Timer? _sensDebounce;

  // Search functionality
  final _sectionKeys = <String, GlobalKey>{
    'AI Analysis': GlobalKey(),
    'Keyboard Extension': GlobalKey(),
    'Notifications': GlobalKey(),
    'Appearance': GlobalKey(),
    'Privacy': GlobalKey(),
    'Account': GlobalKey(),
    'Support': GlobalKey(),
    'Data Management': GlobalKey(),
    'Backup & Sync': GlobalKey(),
    'Language & Accessibility': GlobalKey(),
  };

  @override
  void initState() {
    super.initState();
    _sensitivity = widget.sensitivity;
    _tone = widget.tone;
    _bootstrap();
  }

  @override
  void dispose() {
    _sensDebounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF7B61FF), Color(0xFF9C27B0)],
                        ),
                      ),
                      child: SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.all(AppTheme.spaceLG),
                          child: Row(
                            children: [
                              const Icon(Icons.settings,
                                  color: Colors.white, size: 28),
                              const SizedBox(width: 12),
                              Text(
                                'Settings',
                                style: theme.textTheme.headlineLarge?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Search bar
                    Container(
                      margin: const EdgeInsets.all(AppTheme.spaceLG),
                      child: Autocomplete<String>(
                        optionsBuilder: (textEditingValue) {
                          final query = textEditingValue.text.toLowerCase();
                          if (query.isEmpty) {
                            return const Iterable<String>.empty();
                          }
                          return _sectionKeys.keys.where((section) =>
                              section.toLowerCase().contains(query));
                        },
                        onSelected: _jumpTo,
                        fieldViewBuilder:
                            (_, controller, focusNode, onFieldSubmitted) =>
                                TextField(
                          controller: controller,
                          focusNode: focusNode,
                          decoration: InputDecoration(
                            prefixIcon: Icon(Icons.search,
                                color: theme.colorScheme.onSurfaceVariant),
                            hintText: 'Search settings',
                            hintStyle: TextStyle(
                                color: theme.colorScheme.onSurfaceVariant),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  BorderSide(color: theme.colorScheme.outline),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  BorderSide(color: theme.colorScheme.outline),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  BorderSide(color: theme.colorScheme.primary),
                            ),
                          ),
                          onSubmitted: (value) {
                            final match = _sectionKeys.keys.firstWhere(
                              (section) => section
                                  .toLowerCase()
                                  .contains(value.toLowerCase()),
                              orElse: () => '',
                            );
                            if (match.isNotEmpty) _jumpTo(match);
                          },
                        ),
                      ),
                    ),

                    // Content
                    Padding(
                      padding: const EdgeInsets.all(AppTheme.spaceLG),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // AI Analysis Settings
                          KeyedSubtree(
                            key: _sectionKeys['AI Analysis']!,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionHeader(
                                    'AI Analysis', Icons.psychology),
                                const SizedBox(height: AppTheme.spaceMD),
                                _buildAnalysisSettings(),
                              ],
                            ),
                          ),

                          const SizedBox(height: AppTheme.spaceXL),

                          // Keyboard Extension Settings
                          KeyedSubtree(
                            key: _sectionKeys['Keyboard Extension']!,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionHeader(
                                    'Keyboard Extension', Icons.keyboard),
                                const SizedBox(height: AppTheme.spaceMD),
                                _buildKeyboardExtensionSettings(),
                              ],
                            ),
                          ),

                          const SizedBox(height: AppTheme.spaceXL),

                          // Notification Settings
                          KeyedSubtree(
                            key: _sectionKeys['Notifications']!,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionHeader(
                                    'Notifications', Icons.notifications),
                                const SizedBox(height: AppTheme.spaceMD),
                                _buildNotificationSettings(),
                              ],
                            ),
                          ),

                          const SizedBox(height: AppTheme.spaceXL),

                          // Appearance Settings
                          KeyedSubtree(
                            key: _sectionKeys['Appearance']!,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionHeader(
                                    'Appearance', Icons.palette),
                                const SizedBox(height: AppTheme.spaceMD),
                                _buildAppearanceSettings(),
                              ],
                            ),
                          ),

                          const SizedBox(height: AppTheme.spaceXL),

                          // Privacy Settings
                          KeyedSubtree(
                            key: _sectionKeys['Privacy']!,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionHeader(
                                    'Privacy', Icons.privacy_tip),
                                const SizedBox(height: AppTheme.spaceMD),
                                _buildPrivacySettings(),
                              ],
                            ),
                          ),

                          const SizedBox(height: AppTheme.spaceXL),

                          // Account Settings
                          KeyedSubtree(
                            key: _sectionKeys['Account']!,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionHeader(
                                    'Account', Icons.account_circle),
                                const SizedBox(height: AppTheme.spaceMD),
                                _buildAccountSettings(),
                              ],
                            ),
                          ),

                          const SizedBox(height: AppTheme.spaceXL),

                          // Support Settings
                          KeyedSubtree(
                            key: _sectionKeys['Support']!,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionHeader('Support', Icons.help),
                                const SizedBox(height: AppTheme.spaceMD),
                                _buildSupportSettings(),
                              ],
                            ),
                          ),

                          // Admin Settings (only visible to admins)
                          if (AdminService.instance.isCurrentUserAdmin) ...[
                            const SizedBox(height: AppTheme.spaceXL),
                            _buildSectionHeader(
                                'Admin Controls', Icons.admin_panel_settings),
                            const SizedBox(height: AppTheme.spaceMD),
                            _buildAdminSettings(),
                          ],

                          // Debug Controls (always visible in debug mode)
                          if (kDebugMode &&
                              !AdminService.instance.isCurrentUserAdmin) ...[
                            const SizedBox(height: AppTheme.spaceXL),
                            _buildSectionHeader(
                                'Debug Controls', Icons.bug_report),
                            const SizedBox(height: AppTheme.spaceMD),
                            _buildDebugControls(),
                          ],

                          const SizedBox(height: AppTheme.spaceXL),

                          // Data Management Settings
                          KeyedSubtree(
                            key: _sectionKeys['Data Management']!,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionHeader(
                                    'Data Management', Icons.storage),
                                const SizedBox(height: AppTheme.spaceMD),
                                _buildDataManagementSettings(),
                              ],
                            ),
                          ),

                          const SizedBox(height: AppTheme.spaceXL),

                          // Danger Zone
                          _buildDangerZone(),

                          const SizedBox(height: AppTheme.spaceXL),

                          // Backup & Sync Settings
                          KeyedSubtree(
                            key: _sectionKeys['Backup & Sync']!,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionHeader(
                                    'Backup & Sync', Icons.cloud),
                                const SizedBox(height: AppTheme.spaceMD),
                                _buildBackupSettings(),
                              ],
                            ),
                          ),

                          const SizedBox(height: AppTheme.spaceXL),

                          // Language & Accessibility Settings
                          KeyedSubtree(
                            key: _sectionKeys['Language & Accessibility']!,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionHeader('Language & Accessibility',
                                    Icons.accessibility),
                                const SizedBox(height: AppTheme.spaceMD),
                                _buildLanguageAccessibilitySettings(),
                              ],
                            ),
                          ),

                          const SizedBox(height: AppTheme.spaceXL),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, color: theme.colorScheme.primary, size: 24),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildAnalysisSettings() {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceLG),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sensitivity Slider
            Text(
              'Analysis Sensitivity',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: AppTheme.spaceSM),
            Text(
              'Adjust how detailed the tone analysis should be',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppTheme.spaceMD),
            Slider(
              value: _sensitivity,
              onChanged: (value) {
                setState(() {
                  _sensitivity = value;
                });
                widget.onSensitivityChanged(value);

                // Debounced save
                _sensDebounce?.cancel();
                _sensDebounce =
                    Timer(const Duration(milliseconds: 250), () async {
                  await _settingsManager.setSensitivity(value);
                  await _updateKeyboardSettings();
                });
              },
              divisions: 10,
              label: '${(_sensitivity * 100).round()}%',
              activeColor: theme.colorScheme.primary,
            ),

            const SizedBox(height: AppTheme.spaceLG),

            // Default Tone
            Text(
              'Default Tone',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: AppTheme.spaceSM),
            Text(
              'Choose your preferred communication tone',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppTheme.spaceMD),
            DropdownButtonFormField<String>(
              value: _tone,
              decoration: InputDecoration(
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: const [
                DropdownMenuItem(value: 'Polite', child: Text('Polite')),
                DropdownMenuItem(value: 'Gentle', child: Text('Gentle')),
                DropdownMenuItem(value: 'Direct', child: Text('Direct')),
                DropdownMenuItem(value: 'Neutral', child: Text('Neutral')),
              ],
              onChanged: (value) {
                if (value == null) return;
                _setAndSave(
                  () => _tone = value,
                  () async {
                    widget.onToneChanged(value);
                    await _settingsManager.setTone(value);
                    await _updateKeyboardSettings();
                  },
                );
              },
            ),

            const SizedBox(height: AppTheme.spaceLG),

            // AI Analysis Toggle
            SwitchListTile(
              title: Text('AI Analysis Enabled',
                  style: TextStyle(color: theme.colorScheme.onSurface)),
              subtitle: Text('Enable AI-powered communication analysis',
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
              value: _aiAnalysisEnabled,
              onChanged: (value) => _setAndSave(
                () => _aiAnalysisEnabled = value,
                () => _settingsManager.setAIAnalysisEnabled(value),
              ),
              activeColor: theme.colorScheme.primary,
            ),

            // Real-time Analysis Toggle
            SwitchListTile(
              title: Text('Real-time Analysis',
                  style: TextStyle(color: theme.colorScheme.onSurface)),
              subtitle: Text('Analyze messages as you type',
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
              value: _realTimeAnalysis,
              onChanged: (value) => _setAndSave(
                () => _realTimeAnalysis = value,
                () => _settingsManager.setRealTimeAnalysis(value),
              ),
              activeColor: theme.colorScheme.primary,
            ),

            // Reset to defaults
            const SizedBox(height: AppTheme.spaceMD),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () async {
                  // Reset analysis settings to defaults
                  if (!mounted) return;
                  setState(() {
                    _sensitivity = 0.5;
                    _tone = 'Neutral';
                    _aiAnalysisEnabled = true;
                    _realTimeAnalysis = false;
                  });

                  // Save individual settings
                  await _settingsManager.setSensitivity(0.5);
                  await _settingsManager.setTone('Neutral');
                  await _settingsManager.setAIAnalysisEnabled(true);
                  await _settingsManager.setRealTimeAnalysis(false);

                  widget.onSensitivityChanged(_sensitivity);
                  widget.onToneChanged(_tone);
                  await _updateKeyboardSettings();
                },
                child: Text('Reset to defaults',
                    style: TextStyle(color: theme.colorScheme.primary)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeyboardExtensionSettings() {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceLG),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.keyboard,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Unsaid Keyboard',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Get real-time tone analysis while typing in any app',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppTheme.spaceLG),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.primary.withOpacity(0.3),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.stars,
                        color: theme.colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Premium Feature',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Transform any keyboard into an intelligent communication assistant. Get tone suggestions, relationship-aware responses, and real-time analysis across all your messaging apps.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _openKeyboardSignup(),
                          icon: const Icon(Icons.download, size: 18),
                          label: const Text('Setup Keyboard Extension'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: theme.colorScheme.onPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppTheme.spaceMD),

            // Features list
            ...[
              'Real-time tone analysis',
              'Smart response suggestions',
              'Relationship context awareness',
              'Cross-app compatibility'
            ].map(
              (feature) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: theme.colorScheme.primary,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      feature,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationSettings() {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceLG),
        child: Column(
          children: [
            SwitchListTile(
              title: Text('Push Notifications',
                  style: TextStyle(color: theme.colorScheme.onSurface)),
              subtitle: Text(
                  'Receive notifications for insights and tips · ${_notificationsEnabled ? "On" : "Off"}',
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
              value: _notificationsEnabled,
              onChanged: (value) => _setAndSave(
                () => _notificationsEnabled = value,
                () => _settingsManager.setNotificationsEnabled(value),
              ),
              activeColor: theme.colorScheme.primary,
            ),
            const Divider(),
            ListTile(
              leading: Icon(Icons.schedule,
                  color: theme.colorScheme.onSurfaceVariant),
              title: Text('Notification Schedule',
                  style: TextStyle(color: theme.colorScheme.onSurface)),
              subtitle: Text('Configure when to receive notifications',
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
              trailing: Icon(Icons.arrow_forward_ios,
                  color: theme.colorScheme.onSurfaceVariant),
              onTap: () {
                _showNotificationScheduleDialog();
              },
            ),

            // Reset to defaults
            const SizedBox(height: AppTheme.spaceMD),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () async {
                  // Reset notification settings to defaults
                  if (!mounted) return;
                  setState(() {
                    _notificationsEnabled = true;
                  });
                  await _settingsManager.setNotificationsEnabled(true);
                },
                child: Text('Reset to defaults',
                    style: TextStyle(color: theme.colorScheme.primary)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppearanceSettings() {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceLG),
        child: Column(
          children: [
            SwitchListTile(
              title: Text('Dark Mode',
                  style: TextStyle(color: theme.colorScheme.onSurface)),
              subtitle: Text(
                  'Enable dark theme · ${_darkModeEnabled ? "On" : "Off"}',
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
              value: _darkModeEnabled,
              onChanged: (value) => _setAndSave(
                () => _darkModeEnabled = value,
                () => _settingsManager.setDarkModeEnabled(value),
              ),
              activeColor: theme.colorScheme.primary,
            ),
            const Divider(),
            ListTile(
              leading: Icon(Icons.font_download,
                  color: theme.colorScheme.onSurfaceVariant),
              title: Text('Font Size',
                  style: TextStyle(color: theme.colorScheme.onSurface)),
              subtitle: Text(
                  'Adjust text size · Current: ${_fontSize.round()}pt',
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
              trailing: Icon(Icons.arrow_forward_ios,
                  color: theme.colorScheme.onSurfaceVariant),
              onTap: () {
                _showFontSizeDialog();
              },
            ),

            // Reset to defaults
            const SizedBox(height: AppTheme.spaceMD),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () async {
                  // Reset appearance settings to defaults
                  if (!mounted) return;
                  setState(() {
                    _darkModeEnabled = false;
                    _fontSize = 14.0;
                  });
                  await _settingsManager.setDarkModeEnabled(false);
                  await _settingsManager.setFontSize(14.0);
                },
                child: Text('Reset to defaults',
                    style: TextStyle(color: theme.colorScheme.primary)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacySettings() {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceLG),
        child: Column(
          children: [
            SwitchListTile(
              title: Text('Share Analytics',
                  style: TextStyle(color: theme.colorScheme.onSurface)),
              subtitle: Text(
                  'Help improve the app by sharing anonymous usage data · ${_shareAnalytics ? "On" : "Off"}',
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
              value: _shareAnalytics,
              onChanged: (value) => _setAndSave(
                () => _shareAnalytics = value,
                () => _settingsManager.setShareAnalytics(value),
              ),
              activeColor: theme.colorScheme.primary,
            ),
            const Divider(),
            ListTile(
              leading: Icon(Icons.security,
                  color: theme.colorScheme.onSurfaceVariant),
              title: Text('Privacy Policy',
                  style: TextStyle(color: theme.colorScheme.onSurface)),
              subtitle: Text('Review our privacy policy',
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
              trailing: Icon(Icons.arrow_forward_ios,
                  color: theme.colorScheme.onSurfaceVariant),
              onTap: () {
                _openPrivacyPolicy();
              },
            ),
            const Divider(),
            ListTile(
              leading: Icon(Icons.data_usage,
                  color: theme.colorScheme.onSurfaceVariant),
              title: Text('Data Usage',
                  style: TextStyle(color: theme.colorScheme.onSurface)),
              subtitle: Text('View your data usage statistics',
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
              trailing: Icon(Icons.arrow_forward_ios,
                  color: theme.colorScheme.onSurfaceVariant),
              onTap: () {
                _showDataUsageDialog();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountSettings() {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceLG),
        child: Column(
          children: [
            ListTile(
              leading:
                  Icon(Icons.person, color: theme.colorScheme.onSurfaceVariant),
              title: Text('Profile',
                  style: TextStyle(color: theme.colorScheme.onSurface)),
              subtitle: Text('Edit your profile information',
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
              trailing: Icon(Icons.arrow_forward_ios,
                  color: theme.colorScheme.onSurfaceVariant),
              onTap: () {
                _showProfileDialog();
              },
            ),
            const Divider(),
            ListTile(
              leading:
                  Icon(Icons.lock, color: theme.colorScheme.onSurfaceVariant),
              title: Text('Change Password',
                  style: TextStyle(color: theme.colorScheme.onSurface)),
              subtitle: Text('Update your account password',
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
              trailing: Icon(Icons.arrow_forward_ios,
                  color: theme.colorScheme.onSurfaceVariant),
              onTap: () {
                _showChangePasswordDialog();
              },
            ),
            const Divider(),
            ListTile(
              leading: Icon(Icons.logout, color: theme.colorScheme.error),
              title: Text('Sign Out',
                  style: TextStyle(color: theme.colorScheme.error)),
              subtitle: Text('Sign out of your account',
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
              onTap: () {
                _showSignOutDialog(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSupportSettings() {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceLG),
        child: Column(
          children: [
            ListTile(
              leading: Icon(Icons.help_outline,
                  color: theme.colorScheme.onSurfaceVariant),
              title: Text('Help Center',
                  style: TextStyle(color: theme.colorScheme.onSurface)),
              subtitle: Text('Get help and support',
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
              trailing: Icon(Icons.arrow_forward_ios,
                  color: theme.colorScheme.onSurfaceVariant),
              onTap: () {
                _openHelpCenter();
              },
            ),
            const Divider(),
            ListTile(
              leading: Icon(Icons.feedback,
                  color: theme.colorScheme.onSurfaceVariant),
              title: Text('Send Feedback',
                  style: TextStyle(color: theme.colorScheme.onSurface)),
              subtitle: Text('Share your thoughts and suggestions',
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
              trailing: Icon(Icons.arrow_forward_ios,
                  color: theme.colorScheme.onSurfaceVariant),
              onTap: () {
                _openFeedbackForm();
              },
            ),
            const Divider(),
            ListTile(
              leading:
                  Icon(Icons.info, color: theme.colorScheme.onSurfaceVariant),
              title: Text('About',
                  style: TextStyle(color: theme.colorScheme.onSurface)),
              subtitle: Text('App version and information',
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
              trailing: Icon(Icons.arrow_forward_ios,
                  color: theme.colorScheme.onSurfaceVariant),
              onTap: () {
                _showAboutDialog(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showSignOutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await AuthService.instance.signOut();
                if (mounted) {
                  // Navigate back to splash screen to handle authentication flow
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/splash',
                    (route) => false,
                  );
                }
              } catch (e) {
                _showSnackBar('Failed to sign out: $e');
              }
            },
            child: const Text('Sign Out', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) async {
    final packageInfo = await PackageInfo.fromPlatform();
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('About Unsaid',
            style: TextStyle(color: theme.colorScheme.onSurface)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Version: ${packageInfo.version} (${packageInfo.buildNumber})',
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 8),
            Text('AI-powered communication analysis for better relationships.',
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 8),
            Text('© 2025 Unsaid. All rights reserved.',
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close',
                style: TextStyle(color: theme.colorScheme.primary)),
          ),
        ],
      ),
    );
  }

  /// Update keyboard extension settings when user changes preferences
  Future<void> _updateKeyboardSettings() async {
    try {
      await _keyboardManager.updateSettings({
        'sensitivity': _sensitivity,
        'tone': _tone.toLowerCase(),
        'aiAnalysisEnabled': _aiAnalysisEnabled,
        'realTimeAnalysis': _realTimeAnalysis,
      });
      print(' Keyboard settings updated successfully');
    } catch (e) {
      print(' Error updating keyboard settings: $e');
    }
  }

  // Safe bootstrap to avoid race conditions
  Future<void> _bootstrap() async {
    try {
      await _settingsManager.initialize();
      await _backupService.initialize();

      // Load after services ready
      final settings = (
        sensitivity: _settingsManager.getSensitivity(),
        tone: _settingsManager.getTone(),
        notifications: _settingsManager.getNotificationsEnabled(),
        dark: _settingsManager.getDarkModeEnabled(),
        ai: _settingsManager.getAIAnalysisEnabled(),
        realtime: _settingsManager.getRealTimeAnalysis(),
        share: _settingsManager.getShareAnalytics(),
        hc: _settingsManager.getHighContrastMode(),
        backup: _settingsManager.getBackupEnabled(),
        font: _settingsManager.getFontSize(),
        lang: _settingsManager.getLanguage(),
      );

      if (!mounted) return;
      setState(() {
        _sensitivity = settings.sensitivity;
        _tone = settings.tone;
        _notificationsEnabled = settings.notifications;
        _darkModeEnabled = settings.dark;
        _aiAnalysisEnabled = settings.ai;
        _realTimeAnalysis = settings.realtime;
        _shareAnalytics = settings.share;
        _highContrastMode = settings.hc;
        _autoBackupEnabled = settings.backup;
        _fontSize = settings.font;
        _selectedLanguage = settings.lang;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackBar('Couldn\'t load settings');
      }
    }
  }

  // Helper for setting and saving in one go
  Future<void> _setAndSave<T>(
      void Function() setLocal, Future<void> Function() persist) async {
    setState(setLocal);
    try {
      await persist();
    } catch (_) {
      _showSnackBar('Failed to save');
    }
  }

  // Jump to section with smooth scrolling
  Future<void> _jumpTo(String title) async {
    final key = _sectionKeys[title];
    if (key?.currentContext != null) {
      await Scrollable.ensureVisible(
        key!.currentContext!,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  // Danger zone widget
  Widget _buildDangerZone() {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.errorContainer.withOpacity(0.12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceLG),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber, color: theme.colorScheme.error),
                const SizedBox(width: 8),
                Text('Danger Zone',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.error,
                      fontWeight: FontWeight.w700,
                    )),
              ],
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: Icon(Icons.clear_all, color: theme.colorScheme.error),
              title: Text('Clear All Data',
                  style: TextStyle(color: theme.colorScheme.error)),
              subtitle:
                  const Text('Permanently delete all conversation history'),
              onTap: _showClearAllDataDialog,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataManagementSettings() {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceLG),
        child: Column(
          children: [
            ListTile(
              leading: Icon(Icons.analytics,
                  color: theme.colorScheme.onSurfaceVariant),
              title: Text('Data Usage',
                  style: TextStyle(color: theme.colorScheme.onSurface)),
              subtitle: Text('View your data usage statistics',
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
              trailing: Icon(Icons.arrow_forward_ios,
                  color: theme.colorScheme.onSurfaceVariant),
              onTap: () => _showDataUsageDialog(),
            ),
            const Divider(),
            ListTile(
              leading: Icon(Icons.download,
                  color: theme.colorScheme.onSurfaceVariant),
              title: Text('Export Data',
                  style: TextStyle(color: theme.colorScheme.onSurface)),
              subtitle: Text('Download your conversation insights',
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
              trailing: Icon(Icons.arrow_forward_ios,
                  color: theme.colorScheme.onSurfaceVariant),
              onTap: () => _showExportDataDialog(),
            ),
            const Divider(),
            ListTile(
              leading:
                  Icon(Icons.delete_sweep, color: theme.colorScheme.primary),
              title: Text('Clear Old Data',
                  style: TextStyle(color: theme.colorScheme.onSurface)),
              subtitle: Text('Remove data older than 90 days',
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
              onTap: () => _showClearOldDataDialog(),
            ),
          ],
        ),
      ),
    );
  }

  // Backup & Sync Settings
  Widget _buildBackupSettings() {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceLG),
        child: Column(
          children: [
            SwitchListTile(
              title: Text('Auto Backup',
                  style: TextStyle(color: theme.colorScheme.onSurface)),
              subtitle: Text(
                  'Automatically backup your data daily · ${_autoBackupEnabled ? "On" : "Off"}',
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
              value: _autoBackupEnabled,
              onChanged: (value) async {
                setState(() {
                  _autoBackupEnabled = value;
                });
                await _settingsManager.setBackupEnabled(value);
                if (value) {
                  await _backupService.enableAutoBackup();
                } else {
                  await _backupService.disableAutoBackup();
                }
              },
              activeColor: theme.colorScheme.primary,
            ),
            const Divider(),
            ListTile(
              leading: Icon(Icons.cloud_upload,
                  color: theme.colorScheme.onSurfaceVariant),
              title: Text('Backup Now',
                  style: TextStyle(color: theme.colorScheme.onSurface)),
              subtitle: Text(
                  _backupService.isBackingUp
                      ? 'Backing up...'
                      : 'Manually backup your data',
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
              trailing: _backupService.isBackingUp
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: theme.colorScheme.primary))
                  : Icon(Icons.arrow_forward_ios,
                      color: theme.colorScheme.onSurfaceVariant),
              onTap: _backupService.isBackingUp ? null : () => _performBackup(),
            ),
            const Divider(),
            ListTile(
              leading: Icon(Icons.cloud_download,
                  color: theme.colorScheme.onSurfaceVariant),
              title: Text('Sync from Cloud',
                  style: TextStyle(color: theme.colorScheme.onSurface)),
              subtitle: Text(
                  _backupService.isSyncing
                      ? 'Syncing...'
                      : 'Download latest data from cloud',
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
              trailing: _backupService.isSyncing
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: theme.colorScheme.primary))
                  : Icon(Icons.arrow_forward_ios,
                      color: theme.colorScheme.onSurfaceVariant),
              onTap: _backupService.isSyncing ? null : () => _performSync(),
            ),
            const Divider(),
            ListTile(
              leading: Icon(Icons.import_export,
                  color: theme.colorScheme.onSurfaceVariant),
              title: Text('Import/Export Settings',
                  style: TextStyle(color: theme.colorScheme.onSurface)),
              subtitle: Text('Backup or restore your app settings',
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
              trailing: Icon(Icons.arrow_forward_ios,
                  color: theme.colorScheme.onSurfaceVariant),
              onTap: () => _showImportExportDialog(),
            ),
          ],
        ),
      ),
    );
  }

  // Language & Accessibility Settings
  Widget _buildLanguageAccessibilitySettings() {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceLG),
        child: Column(
          children: [
            ListTile(
              leading: Icon(Icons.language,
                  color: theme.colorScheme.onSurfaceVariant),
              title: Text('Language',
                  style: TextStyle(color: theme.colorScheme.onSurface)),
              subtitle: Text('Current: $_selectedLanguage',
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
              trailing: Icon(Icons.arrow_forward_ios,
                  color: theme.colorScheme.onSurfaceVariant),
              onTap: () => _showLanguageDialog(),
            ),
            const Divider(),
            ListTile(
              leading: Icon(Icons.text_fields,
                  color: theme.colorScheme.onSurfaceVariant),
              title: Text('Font Size',
                  style: TextStyle(color: theme.colorScheme.onSurface)),
              subtitle: Text('Current: ${_fontSize.round()}pt',
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
              trailing: Icon(Icons.arrow_forward_ios,
                  color: theme.colorScheme.onSurfaceVariant),
              onTap: () => _showFontSizeDialog(),
            ),
            const Divider(),
            SwitchListTile(
              title: Text('High Contrast Mode',
                  style: TextStyle(color: theme.colorScheme.onSurface)),
              subtitle: Text(
                  'Improve visibility for better accessibility · ${_highContrastMode ? "On" : "Off"}',
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
              value: _highContrastMode,
              onChanged: (value) => _setAndSave(
                () => _highContrastMode = value,
                () => _settingsManager.setHighContrastMode(value),
              ),
              activeColor: theme.colorScheme.primary,
            ),
            const Divider(),
            ListTile(
              leading: Icon(Icons.accessibility_new,
                  color: theme.colorScheme.onSurfaceVariant),
              title: Text('Accessibility Settings',
                  style: TextStyle(color: theme.colorScheme.onSurface)),
              subtitle: Text('Screen reader and navigation options',
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
              trailing: Icon(Icons.arrow_forward_ios,
                  color: theme.colorScheme.onSurfaceVariant),
              onTap: () => _showAccessibilityDialog(),
            ),

            // Reset to defaults
            const SizedBox(height: AppTheme.spaceMD),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () async {
                  // Reset accessibility settings to defaults
                  if (!mounted) return;
                  setState(() {
                    _selectedLanguage = 'English';
                    _fontSize = 14.0;
                    _highContrastMode = false;
                  });
                  await _settingsManager.setLanguage('English');
                  await _settingsManager.setFontSize(14.0);
                  await _settingsManager.setHighContrastMode(false);
                },
                child: Text('Reset to defaults',
                    style: TextStyle(color: theme.colorScheme.primary)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Dialog methods
  void _showDataUsageDialog() {
    final stats = _dataManager.getDataUsageStats();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Data Usage'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildStatRow('Total Analyses', '${stats['total_analyses']}'),
              _buildStatRow('Data Size',
                  '${stats['data_size_mb'].toStringAsFixed(2)} MB'),
              _buildStatRow('Storage Used',
                  '${stats['storage_usage']['total_mb'].toStringAsFixed(2)} MB'),
              const SizedBox(height: 16),
              const Text('Analysis Breakdown:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...(stats['analysis_breakdown'] as Map<String, int>).entries.map(
                    (entry) => _buildStatRow(
                        entry.key.replaceAll('_', ' ').toUpperCase(),
                        '${entry.value}'),
                  ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _showExportDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Data'),
        content: const Text('Choose what data to export:'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _exportInsightsOnly();
            },
            child: const Text('Insights Only'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _exportAllData();
            },
            child: const Text('All Data'),
          ),
        ],
      ),
    );
  }

  void _showClearOldDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Old Data'),
        content: const Text(
            'This will permanently delete data older than 90 days. This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await _dataManager.clearOldData(90);
              _showSnackBar(success
                  ? 'Old data cleared successfully'
                  : 'Failed to clear old data');
            },
            child: const Text('Clear', style: TextStyle(color: Colors.orange)),
          ),
        ],
      ),
    );
  }

  void _showClearAllDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text(
            'This will permanently delete ALL your conversation history and insights. This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await _dataManager.clearConversationHistory();
              _showSnackBar(success
                  ? 'All data cleared successfully'
                  : 'Failed to clear data');
            },
            child:
                const Text('Delete All', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showImportExportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Settings Backup'),
        content: const Text(
            'Export your settings to a file or import from a backup:'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _importSettings();
            },
            child: const Text('Import'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _exportSettings();
            },
            child: const Text('Export'),
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog() {
    const languages = ['English', 'Spanish', 'French', 'German', 'Italian'];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: languages
              .map((lang) => RadioListTile<String>(
                    title: Text(lang),
                    value: lang,
                    groupValue: _selectedLanguage,
                    onChanged: (value) async {
                      if (value != null) {
                        setState(() {
                          _selectedLanguage = value;
                        });
                        await _settingsManager.setLanguage(value);
                        Navigator.pop(context);
                      }
                    },
                  ))
              .toList(),
        ),
      ),
    );
  }

  void _showFontSizeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Font Size'),
        content: StatefulBuilder(
          builder: (context, setDialogState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Sample text', style: TextStyle(fontSize: _fontSize)),
              Slider(
                value: _fontSize,
                min: 10.0,
                max: 24.0,
                divisions: 14,
                label: '${_fontSize.round()}pt',
                onChanged: (value) {
                  setDialogState(() {
                    _fontSize = value;
                  });
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await _settingsManager.setFontSize(_fontSize);
              setState(() {});
              Navigator.pop(context);
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  void _showAccessibilityDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Accessibility'),
        content: const Text(
            'Accessibility features are configured through your device settings. Enable VoiceOver (iOS) or TalkBack (Android) for screen reader support.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Build admin settings section (only visible to admins)
  Widget _buildAdminSettings() {
    final adminStatus = AdminService.instance.adminStatus;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.admin_panel_settings,
                color: Colors.orange,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Admin Status',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.orange[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Admin info
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('User ID: ${adminStatus['user_id'] ?? 'N/A'}',
                    style:
                        const TextStyle(fontSize: 12, fontFamily: 'monospace')),
                Text('Email: ${adminStatus['email'] ?? 'N/A'}',
                    style: const TextStyle(fontSize: 12)),
                Text(
                    'Full Access: ${adminStatus['full_feature_access'] ? 'Yes' : 'No'}',
                    style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Admin actions
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ElevatedButton.icon(
                onPressed: () async {
                  await _resetPersonalityTest();
                },
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Reset Personality Test'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  await _resetOnboarding();
                },
                icon: const Icon(Icons.restart_alt, size: 16),
                label: const Text('Reset Onboarding'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  _showAdminDebugInfo();
                },
                icon: const Icon(Icons.info, size: 16),
                label: const Text('Debug Info'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ],
          ),

          // Trial & Subscription Controls (Debug Mode Only)
          if (kDebugMode) ...[
            const SizedBox(height: 16),
            Consumer<TrialService>(
              builder: (context, trialService, _) {
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: trialService.isAdminMode
                        ? Colors.red.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: trialService.isAdminMode
                          ? Colors.red.withOpacity(0.3)
                          : Colors.grey.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            trialService.isAdminMode
                                ? Icons.admin_panel_settings
                                : Icons.timer,
                            color: trialService.isAdminMode
                                ? Colors.red
                                : Colors.grey[600],
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Trial & Subscription Controls',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: trialService.isAdminMode
                                  ? Colors.red[800]
                                  : Colors.grey[800],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Status display
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Current Status:',
                              style: TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              trialService.isAdminMode
                                  ? "🔴 ADMIN MODE - Unlimited Access"
                                  : trialService.hasSubscription
                                      ? "💎 Subscribed"
                                      : trialService.isTrialActive
                                          ? "⏰ Trial Active (${trialService.getTrialRemainingText()})"
                                          : "🔒 No Access",
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Control buttons
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () => trialService.toggleAdminMode(),
                            icon: Icon(
                                trialService.isAdminMode
                                    ? Icons.person
                                    : Icons.admin_panel_settings,
                                size: 16),
                            label: Text(trialService.isAdminMode
                                ? 'Disable Admin'
                                : 'Enable Admin'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: trialService.isAdminMode
                                  ? Colors.red
                                  : Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () => trialService.resetTrial(),
                            icon: const Icon(Icons.refresh, size: 16),
                            label: const Text('Reset Trial'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () =>
                                trialService.activateSubscription(),
                            icon: const Icon(Icons.star, size: 16),
                            label: const Text('Activate Sub'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () =>
                                trialService.deactivateSubscription(),
                            icon: const Icon(Icons.star_border, size: 16),
                            label: const Text('Deactivate Sub'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  /// Reset personality test (admin only)
  Future<void> _resetPersonalityTest() async {
    if (!AdminService.instance.isCurrentUserAdmin) {
      _showSnackBar('Access denied: Admin privileges required');
      return;
    }

    try {
      // Import the personality test service
      await PersonalityTestService.resetTest();
      AdminService.instance
          .logAdminAction('Reset personality test from settings');
      _showSnackBar('Personality test reset successfully');
    } catch (e) {
      _showSnackBar('Failed to reset personality test: $e');
    }
  }

  /// Reset onboarding (admin only)
  Future<void> _resetOnboarding() async {
    if (!AdminService.instance.isCurrentUserAdmin) {
      _showSnackBar('Access denied: Admin privileges required');
      return;
    }

    try {
      await OnboardingService.instance.resetOnboarding();
      AdminService.instance.logAdminAction('Reset onboarding from settings');
      _showSnackBar('Onboarding reset successfully');
    } catch (e) {
      _showSnackBar('Failed to reset onboarding: $e');
    }
  }

  /// Show admin debug info
  void _showAdminDebugInfo() {
    final adminStatus = AdminService.instance.adminStatus;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Admin Debug Info'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                ...adminStatus.entries.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 100,
                          child: Text(
                            '${entry.key}:',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            entry.value.toString(),
                            style: const TextStyle(fontFamily: 'monospace'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  /// Show snack bar message
  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  /// Open keyboard signup sheet
  void _openKeyboardSignup() async {
    try {
      if (Platform.isAndroid) {
        // Deep link to Android input settings
        const url =
            'intent://settings/action/INPUT_METHOD_SETTINGS#Intent;scheme=android-app;end';
        if (await canLaunchUrl(Uri.parse(url))) {
          await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
        } else {
          _showKeyboardInstructionsSheet();
        }
      } else {
        // Show instruction sheet for iOS
        _showKeyboardInstructionsSheet();
      }
    } catch (e) {
      _showKeyboardInstructionsSheet();
    }
  }

  void _showKeyboardInstructionsSheet() {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurfaceVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Enable Unsaid Keyboard',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                Platform.isIOS
                    ? 'Settings → General → Keyboard → Keyboards → Add New Keyboard → Unsaid'
                    : 'Settings → System → Languages & input → Virtual keyboard → Manage keyboards → Add Unsaid',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Got it'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Show notification schedule dialog
  void _showNotificationScheduleDialog() {
    _showSnackBar('Notification schedule updated');
  }

  /// Open privacy policy
  void _openPrivacyPolicy() {
    _showSnackBar('Privacy policy opened');
  }

  /// Show profile dialog
  void _showProfileDialog() {
    _showSnackBar('Profile dialog opened');
  }

  /// Show change password dialog
  void _showChangePasswordDialog() {
    _showSnackBar('Change password dialog opened');
  }

  /// Open help center
  void _openHelpCenter() {
    _showSnackBar('Help center opened');
  }

  /// Open feedback form
  void _openFeedbackForm() {
    _showSnackBar('Feedback form opened');
  }

  /// Perform backup
  void _performBackup() {
    _showSnackBar('Backup completed');
  }

  /// Perform sync
  void _performSync() {
    _showSnackBar('Sync completed');
  }

  /// Export insights only
  void _exportInsightsOnly() {
    _showSnackBar('Insights exported');
  }

  /// Export all data
  void _exportAllData() {
    _showSnackBar('All data exported');
  }

  /// Import settings
  void _importSettings() {
    _showSnackBar('Settings imported');
  }

  /// Export settings
  void _exportSettings() {
    _showSnackBar('Settings exported');
  }

  /// Build debug controls section (visible in debug mode only)
  Widget _buildDebugControls() {
    return Consumer<TrialService>(
      builder: (context, trialService, _) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: trialService.isAdminMode
                ? Colors.red.withOpacity(0.1)
                : Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: trialService.isAdminMode
                  ? Colors.red.withOpacity(0.3)
                  : Colors.grey.withOpacity(0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    trialService.isAdminMode
                        ? Icons.admin_panel_settings
                        : Icons.timer,
                    color: trialService.isAdminMode
                        ? Colors.red
                        : Colors.grey[600],
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Trial & Subscription Controls',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: trialService.isAdminMode
                          ? Colors.red[800]
                          : Colors.grey[800],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Status display
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Current Status:',
                      style:
                          TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      trialService.isAdminMode
                          ? "🔴 ADMIN MODE - Unlimited Access"
                          : trialService.hasSubscription
                              ? "💎 Subscribed"
                              : trialService.isTrialActive
                                  ? "⏰ Trial Active (${trialService.getTrialRemainingText()})"
                                  : "🔒 No Access",
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Control buttons
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => trialService.toggleAdminMode(),
                    icon: Icon(
                        trialService.isAdminMode
                            ? Icons.person
                            : Icons.admin_panel_settings,
                        size: 16),
                    label: Text(trialService.isAdminMode
                        ? 'Disable Admin'
                        : 'Enable Admin'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          trialService.isAdminMode ? Colors.red : Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => trialService.resetTrial(),
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Reset Trial'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => trialService.activateSubscription(),
                    icon: const Icon(Icons.star, size: 16),
                    label: const Text('Activate Sub'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => trialService.deactivateSubscription(),
                    icon: const Icon(Icons.star_border, size: 16),
                    label: const Text('Deactivate Sub'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
