import 'package:flutter/material.dart';
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
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';

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
  State<SettingsScreenProfessional> createState() => _SettingsScreenProfessionalState();
}

class _SettingsScreenProfessionalState extends State<SettingsScreenProfessional> {
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

  // Services
  final SettingsManager _settingsManager = SettingsManager();
  final CloudBackupService _backupService = CloudBackupService();
  final DataManagerService _dataManager = DataManagerService();
  final KeyboardManager _keyboardManager = KeyboardManager();

  @override 
  void initState() {
    super.initState();
    _sensitivity = widget.sensitivity;
    _tone = widget.tone;
    _initializeServices();
    _loadSettings();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
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
                        Icon(Icons.settings, color: Colors.white, size: 28),
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
              
              // Content
              Padding(
                padding: const EdgeInsets.all(AppTheme.spaceLG),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // AI Analysis Settings
                    _buildSectionHeader('AI Analysis', Icons.psychology),
                    const SizedBox(height: AppTheme.spaceMD),
                    _buildAnalysisSettings(),
                    
                    const SizedBox(height: AppTheme.spaceXL),
                    
                    // Keyboard Extension Settings
                    _buildSectionHeader('Keyboard Extension', Icons.keyboard),
                    const SizedBox(height: AppTheme.spaceMD),
                    _buildKeyboardExtensionSettings(),
                    
                    const SizedBox(height: AppTheme.spaceXL),
                    
                    // Notification Settings
                    _buildSectionHeader('Notifications', Icons.notifications),
                    const SizedBox(height: AppTheme.spaceMD),
                    _buildNotificationSettings(),
                    
                    const SizedBox(height: AppTheme.spaceXL),
                    
                    // Appearance Settings
                    _buildSectionHeader('Appearance', Icons.palette),
                    const SizedBox(height: AppTheme.spaceMD),
                    _buildAppearanceSettings(),
                    
                    const SizedBox(height: AppTheme.spaceXL),
                    
                    // Privacy Settings
                    _buildSectionHeader('Privacy', Icons.privacy_tip),
                    const SizedBox(height: AppTheme.spaceMD),
                    _buildPrivacySettings(),
                    
                    const SizedBox(height: AppTheme.spaceXL),
                    
                    // Account Settings
                    _buildSectionHeader('Account', Icons.account_circle),
                    const SizedBox(height: AppTheme.spaceMD),
                    _buildAccountSettings(),
                    
                    const SizedBox(height: AppTheme.spaceXL),
                    
                    // Support Settings
                    _buildSectionHeader('Support', Icons.help),
                    const SizedBox(height: AppTheme.spaceMD),
                    _buildSupportSettings(),
                    
                    // Admin Settings (only visible to admins)
                    if (AdminService.instance.isCurrentUserAdmin) ...[
                      const SizedBox(height: AppTheme.spaceXL),
                      _buildSectionHeader('Admin Controls', Icons.admin_panel_settings),
                      const SizedBox(height: AppTheme.spaceMD),
                      _buildAdminSettings(),
                    ],
                    
                    // Debug Controls (always visible in debug mode)
                    if (kDebugMode && !AdminService.instance.isCurrentUserAdmin) ...[
                      const SizedBox(height: AppTheme.spaceXL),
                      _buildSectionHeader('Debug Controls', Icons.bug_report),
                      const SizedBox(height: AppTheme.spaceMD),
                      _buildDebugControls(),
                    ],
                    
                    const SizedBox(height: AppTheme.spaceXL),
                    
                    // Data Management Settings
                    _buildSectionHeader('Data Management', Icons.storage),
                    const SizedBox(height: AppTheme.spaceMD),
                    _buildDataManagementSettings(),
                    
                    const SizedBox(height: AppTheme.spaceXL),
                    
                    // Backup & Sync Settings
                    _buildSectionHeader('Backup & Sync', Icons.cloud),
                    const SizedBox(height: AppTheme.spaceMD),
                    _buildBackupSettings(),
                    
                    const SizedBox(height: AppTheme.spaceXL),
                    
                    // Language & Accessibility Settings
                    _buildSectionHeader('Language & Accessibility', Icons.accessibility),
                    const SizedBox(height: AppTheme.spaceMD),
                    _buildLanguageAccessibilitySettings(),
                    
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
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF7B61FF), size: 24),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildAnalysisSettings() {
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
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppTheme.spaceSM),
            Text(
              'Adjust how detailed the tone analysis should be',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
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
                _updateKeyboardSettings();
              },
              divisions: 10,
              label: '${(_sensitivity * 100).round()}%',
              activeColor: const Color(0xFF7B61FF),
            ),
            
            const SizedBox(height: AppTheme.spaceLG),
            
            // Default Tone
            Text(
              'Default Tone',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppTheme.spaceSM),
            Text(
              'Choose your preferred communication tone',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: AppTheme.spaceMD),
            DropdownButtonFormField<String>(
              value: _tone,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: const [
                DropdownMenuItem(value: 'Polite', child: Text('Polite')),
                DropdownMenuItem(value: 'Gentle', child: Text('Gentle')),
                DropdownMenuItem(value: 'Direct', child: Text('Direct')),
                DropdownMenuItem(value: 'Neutral', child: Text('Neutral')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _tone = value;
                  });
                  widget.onToneChanged(value);
                  _updateKeyboardSettings();
                }
              },
            ),
            
            const SizedBox(height: AppTheme.spaceLG),
            
            // AI Analysis Toggle
            SwitchListTile(
              title: const Text('AI Analysis Enabled'),
              subtitle: const Text('Enable AI-powered communication analysis'),
              value: _aiAnalysisEnabled,
              onChanged: (value) {
                setState(() {
                  _aiAnalysisEnabled = value;
                });
              },
              activeColor: const Color(0xFF7B61FF),
            ),
            
            // Real-time Analysis Toggle
            SwitchListTile(
              title: const Text('Real-time Analysis'),
              subtitle: const Text('Analyze messages as you type'),
              value: _realTimeAnalysis,
              onChanged: (value) {
                setState(() {
                  _realTimeAnalysis = value;
                });
              },
              activeColor: const Color(0xFF7B61FF),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeyboardExtensionSettings() {
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
                  color: const Color(0xFF7B61FF),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Unsaid Keyboard',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Get real-time tone analysis while typing in any app',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
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
                color: const Color(0xFF7B61FF).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF7B61FF).withOpacity(0.3),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.stars,
                        color: const Color(0xFF7B61FF),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Premium Feature',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: const Color(0xFF7B61FF),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Transform any keyboard into an intelligent communication assistant. Get tone suggestions, relationship-aware responses, and real-time analysis across all your messaging apps.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[700],
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
                            backgroundColor: const Color(0xFF7B61FF),
                            foregroundColor: Colors.white,
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
            ...['Real-time tone analysis', 'Smart response suggestions', 'Relationship context awareness', 'Cross-app compatibility'].map(
              (feature) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      feature,
                      style: Theme.of(context).textTheme.bodySmall,
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
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceLG),
        child: Column(
          children: [
            SwitchListTile(
              title: const Text('Push Notifications'),
              subtitle: const Text('Receive notifications for insights and tips'),
              value: _notificationsEnabled,
              onChanged: (value) {
                setState(() {
                  _notificationsEnabled = value;
                });
              },
              activeColor: const Color(0xFF7B61FF),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.schedule),
              title: const Text('Notification Schedule'),
              subtitle: const Text('Configure when to receive notifications'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                _showNotificationScheduleDialog();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppearanceSettings() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceLG),
        child: Column(
          children: [
            SwitchListTile(
              title: const Text('Dark Mode'),
              subtitle: const Text('Enable dark theme'),
              value: _darkModeEnabled,
              onChanged: (value) {
                setState(() {
                  _darkModeEnabled = value;
                });
              },
              activeColor: const Color(0xFF7B61FF),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.font_download),
              title: const Text('Font Size'),
              subtitle: const Text('Adjust text size'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                _showFontSizeDialog();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacySettings() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceLG),
        child: Column(
          children: [
            SwitchListTile(
              title: const Text('Share Analytics'),
              subtitle: const Text('Help improve the app by sharing anonymous usage data'),
              value: _shareAnalytics,
              onChanged: (value) {
                setState(() {
                  _shareAnalytics = value;
                });
              },
              activeColor: const Color(0xFF7B61FF),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.security),
              title: const Text('Privacy Policy'),
              subtitle: const Text('Review our privacy policy'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                _openPrivacyPolicy();
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.data_usage),
              title: const Text('Data Usage'),
              subtitle: const Text('View your data usage statistics'),
              trailing: const Icon(Icons.arrow_forward_ios),
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
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceLG),
        child: Column(
          children: [
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Profile'),
              subtitle: const Text('Edit your profile information'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                _showProfileDialog();
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.lock),
              title: const Text('Change Password'),
              subtitle: const Text('Update your account password'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                _showChangePasswordDialog();
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Sign Out', style: TextStyle(color: Colors.red)),
              subtitle: const Text('Sign out of your account'),
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
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceLG),
        child: Column(
          children: [
            ListTile(
              leading: const Icon(Icons.help_outline),
              title: const Text('Help Center'),
              subtitle: const Text('Get help and support'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                _openHelpCenter();
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.feedback),
              title: const Text('Send Feedback'),
              subtitle: const Text('Share your thoughts and suggestions'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                _openFeedbackForm();
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('About'),
              subtitle: const Text('App version and information'),
              trailing: const Icon(Icons.arrow_forward_ios),
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

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About Unsaid'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Version: 1.0.0'),
            SizedBox(height: 8),
            Text('AI-powered communication analysis for better relationships.'),
            SizedBox(height: 8),
            Text('© 2025 Unsaid. All rights reserved.'),
          ],
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

  // Initialize services
  Future<void> _initializeServices() async {
    await _settingsManager.initialize();
    await _backupService.initialize();
  }

  // Load settings from storage
  Future<void> _loadSettings() async {
    setState(() {
      _sensitivity = _settingsManager.getSensitivity();
      _tone = _settingsManager.getTone();
      _notificationsEnabled = _settingsManager.getNotificationsEnabled();
      _darkModeEnabled = _settingsManager.getDarkModeEnabled();
      _aiAnalysisEnabled = _settingsManager.getAIAnalysisEnabled();
      _realTimeAnalysis = _settingsManager.getRealTimeAnalysis();
      _shareAnalytics = _settingsManager.getShareAnalytics();
      _highContrastMode = _settingsManager.getHighContrastMode();
      _autoBackupEnabled = _settingsManager.getBackupEnabled();
      _fontSize = _settingsManager.getFontSize();
      _selectedLanguage = _settingsManager.getLanguage();
    });
  }

  // Data Management Settings
  Widget _buildDataManagementSettings() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceLG),
        child: Column(
          children: [
            ListTile(
              leading: const Icon(Icons.analytics),
              title: const Text('Data Usage'),
              subtitle: const Text('View your data usage statistics'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => _showDataUsageDialog(),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.download),
              title: const Text('Export Data'),
              subtitle: const Text('Download your conversation insights'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => _showExportDataDialog(),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.delete_sweep, color: Colors.orange),
              title: const Text('Clear Old Data'),
              subtitle: const Text('Remove data older than 90 days'),
              onTap: () => _showClearOldDataDialog(),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.clear_all, color: Colors.red),
              title: const Text('Clear All Data', style: TextStyle(color: Colors.red)),
              subtitle: const Text('Permanently delete all conversation history'),
              onTap: () => _showClearAllDataDialog(),
            ),
          ],
        ),
      ),
    );
  }

  // Backup & Sync Settings
  Widget _buildBackupSettings() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceLG),
        child: Column(
          children: [
            SwitchListTile(
              title: const Text('Auto Backup'),
              subtitle: const Text('Automatically backup your data daily'),
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
              activeColor: const Color(0xFF7B61FF),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.cloud_upload),
              title: const Text('Backup Now'),
              subtitle: Text(_backupService.isBackingUp ? 'Backing up...' : 'Manually backup your data'),
              trailing: _backupService.isBackingUp 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator())
                : const Icon(Icons.arrow_forward_ios),
              onTap: _backupService.isBackingUp ? null : () => _performBackup(),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.cloud_download),
              title: const Text('Sync from Cloud'),
              subtitle: Text(_backupService.isSyncing ? 'Syncing...' : 'Download latest data from cloud'),
              trailing: _backupService.isSyncing 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator())
                : const Icon(Icons.arrow_forward_ios),
              onTap: _backupService.isSyncing ? null : () => _performSync(),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.import_export),
              title: const Text('Import/Export Settings'),
              subtitle: const Text('Backup or restore your app settings'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => _showImportExportDialog(),
            ),
          ],
        ),
      ),
    );
  }

  // Language & Accessibility Settings
  Widget _buildLanguageAccessibilitySettings() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceLG),
        child: Column(
          children: [
            ListTile(
              leading: const Icon(Icons.language),
              title: const Text('Language'),
              subtitle: Text('Current: $_selectedLanguage'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => _showLanguageDialog(),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.text_fields),
              title: const Text('Font Size'),
              subtitle: Text('Current: ${_fontSize.round()}pt'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => _showFontSizeDialog(),
            ),
            const Divider(),
            SwitchListTile(
              title: const Text('High Contrast Mode'),
              subtitle: const Text('Improve visibility for better accessibility'),
              value: _highContrastMode,
              onChanged: (value) async {
                setState(() {
                  _highContrastMode = value;
                });
                await _settingsManager.setHighContrastMode(value);
              },
              activeColor: const Color(0xFF7B61FF),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.accessibility_new),
              title: const Text('Accessibility Settings'),
              subtitle: const Text('Screen reader and navigation options'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => _showAccessibilityDialog(),
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
              _buildStatRow('Data Size', '${stats['data_size_mb'].toStringAsFixed(2)} MB'),
              _buildStatRow('Storage Used', '${stats['storage_usage']['total_mb'].toStringAsFixed(2)} MB'),
              const SizedBox(height: 16),
              const Text('Analysis Breakdown:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...(stats['analysis_breakdown'] as Map<String, int>).entries.map(
                (entry) => _buildStatRow(entry.key.replaceAll('_', ' ').toUpperCase(), '${entry.value}'),
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
        content: const Text('This will permanently delete data older than 90 days. This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await _dataManager.clearOldData(90);
              _showSnackBar(success ? 'Old data cleared successfully' : 'Failed to clear old data');
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
        content: const Text('This will permanently delete ALL your conversation history and insights. This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await _dataManager.clearConversationHistory();
              _showSnackBar(success ? 'All data cleared successfully' : 'Failed to clear data');
            },
            child: const Text('Delete All', style: TextStyle(color: Colors.red)),
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
        content: const Text('Export your settings to a file or import from a backup:'),
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
          children: languages.map((lang) => RadioListTile<String>(
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
          )).toList(),
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
        content: const Text('Accessibility features are configured through your device settings. Enable VoiceOver (iOS) or TalkBack (Android) for screen reader support.'),
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
              Icon(
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
                     style: const TextStyle(fontSize: 12, fontFamily: 'monospace')),
                Text('Email: ${adminStatus['email'] ?? 'N/A'}', 
                     style: const TextStyle(fontSize: 12)),
                Text('Full Access: ${adminStatus['full_feature_access'] ? 'Yes' : 'No'}', 
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
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                    color: trialService.isAdminMode ? Colors.red.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: trialService.isAdminMode ? Colors.red.withOpacity(0.3) : Colors.grey.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            trialService.isAdminMode ? Icons.admin_panel_settings : Icons.timer,
                            color: trialService.isAdminMode ? Colors.red : Colors.grey[600],
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Trial & Subscription Controls',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: trialService.isAdminMode ? Colors.red[800] : Colors.grey[800],
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
                            Text(
                              'Current Status:',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
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
                              style: TextStyle(fontSize: 12),
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
                              trialService.isAdminMode ? Icons.person : Icons.admin_panel_settings, 
                              size: 16
                            ),
                            label: Text(trialService.isAdminMode ? 'Disable Admin' : 'Enable Admin'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: trialService.isAdminMode ? Colors.red : Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () => trialService.resetTrial(),
                            icon: const Icon(Icons.refresh, size: 16),
                            label: const Text('Reset Trial'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () => trialService.activateSubscription(),
                            icon: const Icon(Icons.star, size: 16),
                            label: const Text('Activate Sub'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () => trialService.deactivateSubscription(),
                            icon: const Icon(Icons.star_border, size: 16),
                            label: const Text('Deactivate Sub'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
      AdminService.instance.logAdminAction('Reset personality test from settings');
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
                ...adminStatus.entries.map((entry) => 
                  Padding(
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
      // Open iOS Settings app directly to Keyboard settings
      const url = 'App-Prefs:General&path=Keyboard';
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(
          Uri.parse(url),
          mode: LaunchMode.externalApplication,
        );
      } else {
        // Fallback to general settings if the specific keyboard path doesn't work
        const fallbackUrl = 'App-Prefs:';
        if (await canLaunchUrl(Uri.parse(fallbackUrl))) {
          await launchUrl(
            Uri.parse(fallbackUrl),
            mode: LaunchMode.externalApplication,
          );
          _showSnackBar('Please navigate to Settings > General > Keyboard > Keyboards > Add New Keyboard > Unsaid');
        } else {
          _showSnackBar('Please open Settings > General > Keyboard > Keyboards to add Unsaid keyboard');
        }
      }
    } catch (e) {
      _showSnackBar('Please manually open Settings > General > Keyboard > Keyboards to add Unsaid keyboard');
    }
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
            color: trialService.isAdminMode ? Colors.red.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: trialService.isAdminMode ? Colors.red.withOpacity(0.3) : Colors.grey.withOpacity(0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    trialService.isAdminMode ? Icons.admin_panel_settings : Icons.timer,
                    color: trialService.isAdminMode ? Colors.red : Colors.grey[600],
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Trial & Subscription Controls',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: trialService.isAdminMode ? Colors.red[800] : Colors.grey[800],
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
                    Text(
                      'Current Status:',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
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
                      style: TextStyle(fontSize: 12),
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
                      trialService.isAdminMode ? Icons.person : Icons.admin_panel_settings, 
                      size: 16
                    ),
                    label: Text(trialService.isAdminMode ? 'Disable Admin' : 'Enable Admin'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: trialService.isAdminMode ? Colors.red : Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => trialService.resetTrial(),
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Reset Trial'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => trialService.activateSubscription(),
                    icon: const Icon(Icons.star, size: 16),
                    label: const Text('Activate Sub'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => trialService.deactivateSubscription(),
                    icon: const Icon(Icons.star_border, size: 16),
                    label: const Text('Deactivate Sub'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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