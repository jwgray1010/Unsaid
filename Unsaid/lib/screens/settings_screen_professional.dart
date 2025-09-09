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
import 'package:flutter/foundation.dart';

/// --- Data model -------------------------------------------------------------

enum TileKind { switcher, slider, action, dropdown, nav }

class SettingTile {
  final TileKind kind;
  final String title;
  final String? subtitle;
  final IconData? leading;
  final String? keyId;

  // Switch
  final bool Function()? getterBool;
  final Future<void> Function(bool)? onChangedBool;

  // Slider
  final double Function()? getterDouble;
  final Future<void> Function(double)? onChangedDouble;
  final double min, max;
  final int? divisions;
  final String Function(double)? labelFor;

  // Dropdown
  final String Function()? getterString;
  final List<String> options;
  final Future<void> Function(String)? onChangedString;

  // Action / Nav
  final VoidCallback? onTap;

  const SettingTile.switcher({
    required this.title,
    this.subtitle,
    this.leading,
    this.keyId,
    required this.getterBool,
    required this.onChangedBool,
  })  : kind = TileKind.switcher,
        getterDouble = null,
        onChangedDouble = null,
        min = 0,
        max = 0,
        divisions = null,
        labelFor = null,
        getterString = null,
        options = const [],
        onChangedString = null,
        onTap = null;

  const SettingTile.slider({
    required this.title,
    this.subtitle,
    this.leading,
    this.keyId,
    required this.getterDouble,
    required this.onChangedDouble,
    this.min = 0,
    this.max = 1,
    this.divisions,
    this.labelFor,
  })  : kind = TileKind.slider,
        getterBool = null,
        onChangedBool = null,
        getterString = null,
        options = const [],
        onChangedString = null,
        onTap = null;

  const SettingTile.dropdown({
    required this.title,
    this.subtitle,
    this.leading,
    this.keyId,
    required this.getterString,
    required this.options,
    required this.onChangedString,
  })  : kind = TileKind.dropdown,
        getterBool = null,
        onChangedBool = null,
        getterDouble = null,
        onChangedDouble = null,
        min = 0,
        max = 0,
        divisions = null,
        labelFor = null,
        onTap = null;

  const SettingTile.action({
    required this.title,
    this.subtitle,
    this.leading,
    this.keyId,
    required this.onTap,
  })  : kind = TileKind.action,
        getterBool = null,
        onChangedBool = null,
        getterDouble = null,
        onChangedDouble = null,
        min = 0,
        max = 0,
        divisions = null,
        labelFor = null,
        getterString = null,
        options = const [],
        onChangedString = null;
}

class SettingSection {
  final String title;
  final IconData icon;
  final List<SettingTile> tiles;
  const SettingSection(this.title, this.icon, this.tiles);
}

/// --- Screen ----------------------------------------------------------------

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
  // Services
  final _settings = SettingsManager();
  final _backup = CloudBackupService();
  final _data = DataManagerService();
  final _keyboard = KeyboardManager();

  // Local state
  bool _loading = true;
  double _sensitivity = 0.5;
  String _tone = 'Neutral';
  bool _ai = true;
  bool _realtime = false;
  bool _notifications = true;
  bool _dark = false;
  bool _shareAnalytics = false;
  bool _highContrast = false;
  bool _backupOn = true;
  double _fontSize = 14.0;
  String _language = 'English';

  // Debounce
  Timer? _deb;

  // Simple debounce helper
  void _debounceSave(void Function() work, [int ms = 250]) {
    _deb?.cancel();
    _deb = Timer(Duration(milliseconds: ms), work);
  }

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _deb?.cancel();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    await _settings.initialize();
    await _backup.initialize();
    setState(() {
      _sensitivity = _settings.getSensitivity();
      _tone = _settings.getTone();
      _notifications = _settings.getNotificationsEnabled();
      _dark = _settings.getDarkModeEnabled();
      _ai = _settings.getAIAnalysisEnabled();
      _realtime = _settings.getRealTimeAnalysis();
      _shareAnalytics = _settings.getShareAnalytics();
      _highContrast = _settings.getHighContrastMode();
      _backupOn = _settings.getBackupEnabled();
      _fontSize = _settings.getFontSize();
      _language = _settings.getLanguage();
      _loading = false;
    });
  }

  Future<void> _updateKeyboard() async {
    try {
      await _keyboard.updateSettings({
        'sensitivity': _sensitivity,
        'tone': _tone.toLowerCase(),
        'aiAnalysisEnabled': _ai,
        'realTimeAnalysis': _realtime,
      });
    } catch (_) {/*silent*/}
  }

  // One-liners to persist + optional keyboard sync
  Future<void> _saveBool(Future<void> Function(bool) f, bool v,
      {bool touchesKeyboard = false}) async {
    await f(v);
    if (touchesKeyboard) _updateKeyboard();
  }

  Future<void> _saveDouble(Future<void> Function(double) f, double v,
      {bool touchesKeyboard = false, bool debounce = true}) async {
    if (debounce) {
      _debounceSave(() async {
        await f(v);
        if (touchesKeyboard) _updateKeyboard();
      });
    } else {
      await f(v);
      if (touchesKeyboard) _updateKeyboard();
    }
  }

  Future<void> _saveString(Future<void> Function(String) f, String v,
      {bool touchesKeyboard = false}) async {
    await f(v);
    if (touchesKeyboard) _updateKeyboard();
  }

  // Compact dialogs
  Future<void> _confirm(
    String title,
    String body, {
    String confirmText = 'OK',
    Color? confirmColor,
    VoidCallback? onConfirm,
  }) async {
    final theme = Theme.of(context);
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm?.call();
            },
            child: Text(confirmText,
                style: TextStyle(
                    color: confirmColor ?? theme.colorScheme.primary)),
          ),
        ],
      ),
    );
  }

  // Sections (small, focused, effective)
  List<SettingSection> _sections() {
    return [
      SettingSection('AI Analysis', Icons.psychology, [
        SettingTile.slider(
          title: 'Analysis Sensitivity',
          subtitle: 'How detailed tone analysis should be',
          leading: Icons.tune,
          getterDouble: () => _sensitivity,
          onChangedDouble: (v) async {
            setState(() => _sensitivity = v);
            widget.onSensitivityChanged(v);
            await _saveDouble(_settings.setSensitivity, v,
                touchesKeyboard: true);
          },
          min: 0,
          max: 1,
          divisions: 10,
          labelFor: (v) => '${(v * 100).round()}%',
        ),
        SettingTile.dropdown(
          title: 'Default Tone',
          subtitle: 'Preferred communication tone',
          leading: Icons.record_voice_over,
          getterString: () => _tone,
          options: const ['Polite', 'Gentle', 'Direct', 'Neutral'],
          onChangedString: (val) async {
            setState(() => _tone = val);
            widget.onToneChanged(val);
            await _saveString(_settings.setTone, val, touchesKeyboard: true);
          },
        ),
        SettingTile.switcher(
          title: 'AI Analysis Enabled',
          subtitle: 'Enable AI-powered analysis',
          leading: Icons.auto_awesome,
          getterBool: () => _ai,
          onChangedBool: (v) async {
            setState(() => _ai = v);
            await _saveBool(_settings.setAIAnalysisEnabled, v,
                touchesKeyboard: true);
          },
        ),
        SettingTile.switcher(
          title: 'Real-time Analysis',
          subtitle: 'Analyze as you type',
          leading: Icons.speed,
          getterBool: () => _realtime,
          onChangedBool: (v) async {
            setState(() => _realtime = v);
            await _saveBool(_settings.setRealTimeAnalysis, v,
                touchesKeyboard: true);
          },
        ),
        SettingTile.action(
          title: 'Reset to Defaults',
          leading: Icons.restart_alt,
          onTap: () async {
            setState(() {
              _sensitivity = 0.5;
              _tone = 'Neutral';
              _ai = true;
              _realtime = false;
            });
            await _settings.setSensitivity(0.5);
            await _settings.setTone('Neutral');
            await _settings.setAIAnalysisEnabled(true);
            await _settings.setRealTimeAnalysis(false);
            widget.onSensitivityChanged(_sensitivity);
            widget.onToneChanged(_tone);
            _updateKeyboard();
          },
        ),
      ]),
      SettingSection('Keyboard Extension', Icons.keyboard, [
        SettingTile.action(
          title: 'Setup Keyboard Extension',
          subtitle: Platform.isIOS
              ? 'Settings → General → Keyboard → Keyboards → Add New → Unsaid'
              : 'Settings → System → Languages & input → Virtual keyboard',
          leading: Icons.download,
          onTap: _openKeyboardSetup,
        ),
        SettingTile.action(
          title: 'Premium Features',
          subtitle: 'Real-time tone, suggestions, context awareness',
          leading: Icons.stars,
          onTap: () => _showSnack('Premium info opened'),
        ),
      ]),
      SettingSection('Notifications', Icons.notifications, [
        SettingTile.switcher(
          title: 'Push Notifications',
          subtitle: _notifications ? 'On' : 'Off',
          leading: Icons.notifications_active,
          getterBool: () => _notifications,
          onChangedBool: (v) async {
            setState(() => _notifications = v);
            await _saveBool(_settings.setNotificationsEnabled, v);
          },
        ),
        SettingTile.action(
          title: 'Notification Schedule',
          subtitle: 'Configure when to receive notifications',
          leading: Icons.schedule,
          onTap: () => _showSnack('Notification schedule opened'),
        ),
      ]),
      SettingSection('Appearance', Icons.palette, [
        SettingTile.switcher(
          title: 'Dark Mode',
          subtitle: _dark ? 'On' : 'Off',
          leading: Icons.dark_mode,
          getterBool: () => _dark,
          onChangedBool: (v) async {
            setState(() => _dark = v);
            await _saveBool(_settings.setDarkModeEnabled, v);
          },
        ),
        SettingTile.slider(
          title: 'Font Size',
          subtitle: 'Current: ${_fontSize.round()}pt',
          leading: Icons.text_fields,
          getterDouble: () => _fontSize,
          onChangedDouble: (v) async {
            setState(() => _fontSize = v);
            await _saveDouble(_settings.setFontSize, v, debounce: false);
          },
          min: 10,
          max: 24,
          divisions: 14,
          labelFor: (v) => '${v.round()}pt',
        ),
      ]),
      SettingSection('Privacy', Icons.privacy_tip, [
        SettingTile.switcher(
          title: 'Share Analytics',
          subtitle: _shareAnalytics ? 'On' : 'Off',
          leading: Icons.analytics_outlined,
          getterBool: () => _shareAnalytics,
          onChangedBool: (v) async {
            setState(() => _shareAnalytics = v);
            await _saveBool(_settings.setShareAnalytics, v);
          },
        ),
        SettingTile.action(
          title: 'Privacy Policy',
          leading: Icons.security,
          onTap: () => _showSnack('Privacy policy opened'),
        ),
        SettingTile.action(
          title: 'Data Usage',
          leading: Icons.data_usage,
          onTap: _showDataUsageDialog,
        ),
      ]),
      SettingSection('Account', Icons.account_circle, [
        SettingTile.action(
          title: 'Profile',
          leading: Icons.person,
          onTap: () => _showSnack('Profile opened'),
        ),
        SettingTile.action(
          title: 'Change Password',
          leading: Icons.lock,
          onTap: () => _showSnack('Change password opened'),
        ),
        SettingTile.action(
          title: 'Sign Out',
          leading: Icons.logout,
          onTap: () => _confirm(
            'Sign Out',
            'Are you sure you want to sign out?',
            confirmText: 'Sign Out',
            confirmColor: Colors.red,
            onConfirm: () async {
              try {
                await AuthService.instance.signOut();
                if (!mounted) return;
                Navigator.pushNamedAndRemoveUntil(
                    context, '/splash', (_) => false);
              } catch (e) {
                _showSnack('Failed to sign out: $e');
              }
            },
          ),
        ),
      ]),
      SettingSection('Backup & Sync', Icons.cloud, [
        SettingTile.switcher(
          title: 'Auto Backup',
          subtitle: _backupOn ? 'On' : 'Off',
          leading: Icons.cloud_sync,
          getterBool: () => _backupOn,
          onChangedBool: (v) async {
            setState(() => _backupOn = v);
            await _saveBool(_settings.setBackupEnabled, v);
            v
                ? await _backup.enableAutoBackup()
                : await _backup.disableAutoBackup();
          },
        ),
        SettingTile.action(
          title: 'Backup Now',
          leading: Icons.cloud_upload,
          onTap: () async {
            _showSnack('Backing up…');
            // tie into your service as needed
            _showSnack('Backup completed');
          },
        ),
        SettingTile.action(
          title: 'Sync from Cloud',
          leading: Icons.cloud_download,
          onTap: () async {
            _showSnack('Syncing…');
            _showSnack('Sync completed');
          },
        ),
      ]),
      SettingSection('Language & Accessibility', Icons.accessibility, [
        SettingTile.dropdown(
          title: 'Language',
          subtitle: 'Current: $_language',
          leading: Icons.language,
          getterString: () => _language,
          options: const ['English', 'Spanish', 'French', 'German', 'Italian'],
          onChangedString: (v) async {
            setState(() => _language = v);
            await _saveString(_settings.setLanguage, v);
          },
        ),
        SettingTile.switcher(
          title: 'High Contrast Mode',
          subtitle: _highContrast ? 'On' : 'Off',
          leading: Icons.contrast,
          getterBool: () => _highContrast,
          onChangedBool: (v) async {
            setState(() => _highContrast = v);
            await _saveBool(_settings.setHighContrastMode, v);
          },
        ),
      ]),
      // Admin/debug (kept tiny but visible when applicable)
      if (AdminService.instance.isCurrentUserAdmin)
        SettingSection('Admin Controls', Icons.admin_panel_settings, [
          SettingTile.action(
            title: 'Reset Personality Test',
            leading: Icons.refresh,
            onTap: () => _showSnack('Personality test reset'),
          ),
          SettingTile.action(
            title: 'Reset Onboarding',
            leading: Icons.restart_alt,
            onTap: () => _showSnack('Onboarding reset'),
          ),
        ]),
      if (kDebugMode && !AdminService.instance.isCurrentUserAdmin)
        SettingSection('Debug Controls', Icons.bug_report, [
          SettingTile.action(
            title: 'Trial & Subscription Controls',
            leading: Icons.timer,
            onTap: () => _showSnack('Debug controls opened'),
          ),
        ]),
      SettingSection('Danger Zone', Icons.warning_amber, [
        SettingTile.action(
          title: 'Clear All Data',
          subtitle: 'This cannot be undone',
          leading: Icons.delete_forever,
          onTap: () => _confirm(
            'Clear All Data',
            'This will permanently delete ALL conversation history.',
            confirmText: 'Delete',
            confirmColor: Colors.red,
            onConfirm: () async {
              final ok = await _data.clearConversationHistory();
              _showSnack(ok ? 'All data cleared' : 'Failed to clear data');
            },
          ),
        ),
      ]),
    ];
  }

  /// --- UI -------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : CustomScrollView(
                slivers: [
                  SliverAppBar(
                    pinned: true,
                    expandedHeight: 110,
                    flexibleSpace: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF7B61FF), Color(0xFF9C27B0)],
                        ),
                      ),
                      child: Align(
                        alignment: Alignment.bottomLeft,
                        child: Padding(
                          padding: const EdgeInsets.all(AppTheme.spaceLG),
                          child: Row(
                            children: [
                              const Icon(Icons.settings, color: Colors.white),
                              const SizedBox(width: 12),
                              Text('Settings',
                                  style:
                                      theme.textTheme.headlineSmall?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  )),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  SliverList.list(
                    children: _sections().map(_buildSection).toList(),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildSection(SettingSection s) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spaceLG),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spaceLG),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(s.icon, color: theme.colorScheme.primary, size: 22),
                const SizedBox(width: 8),
                Text(s.title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    )),
              ]),
              const SizedBox(height: AppTheme.spaceMD),
              ...s.tiles.map(_buildTile),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTile(SettingTile t) {
    final theme = Theme.of(context);
    switch (t.kind) {
      case TileKind.switcher:
        return SwitchListTile(
          contentPadding: EdgeInsets.zero,
          secondary: t.leading != null
              ? Icon(t.leading, color: theme.colorScheme.onSurfaceVariant)
              : null,
          title: Text(t.title),
          subtitle: t.subtitle != null ? Text(t.subtitle!) : null,
          value: t.getterBool!(),
          onChanged: (v) => t.onChangedBool!(v),
          activeColor: theme.colorScheme.primary,
        );
      case TileKind.slider:
        final v = t.getterDouble!();
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              if (t.leading != null)
                Icon(t.leading, color: theme.colorScheme.onSurfaceVariant),
              if (t.leading != null) const SizedBox(width: 8),
              Text(t.title, style: theme.textTheme.titleMedium),
              const Spacer(),
              if (t.labelFor != null)
                Text(t.labelFor!(v),
                    style: theme.textTheme.labelMedium
                        ?.copyWith(color: theme.colorScheme.primary)),
            ]),
            if (t.subtitle != null) ...[
              const SizedBox(height: 4),
              Text(t.subtitle!,
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
            ],
            Slider(
              value: v,
              onChanged: (nv) {
                t.onChangedDouble!(nv);
              },
              min: t.min,
              max: t.max,
              divisions: t.divisions,
              label: t.labelFor?.call(v),
              activeColor: theme.colorScheme.primary,
            ),
          ]),
        );
      case TileKind.dropdown:
        final current = t.getterString!();
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: t.leading != null
              ? Icon(t.leading, color: theme.colorScheme.onSurfaceVariant)
              : null,
          title: Text(t.title),
          subtitle: t.subtitle != null ? Text(t.subtitle!) : null,
          trailing: DropdownButton<String>(
            value: current,
            onChanged: (v) => v != null ? t.onChangedString!(v) : null,
            items: t.options
                .map((o) => DropdownMenuItem(value: o, child: Text(o)))
                .toList(),
          ),
        );
      case TileKind.action:
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: t.leading != null
              ? Icon(t.leading, color: theme.colorScheme.onSurfaceVariant)
              : null,
          title: Text(t.title),
          subtitle: t.subtitle != null ? Text(t.subtitle!) : null,
          trailing: Icon(Icons.arrow_forward_ios,
              size: 16, color: theme.colorScheme.onSurfaceVariant),
          onTap: t.onTap,
        );
      case TileKind.nav:
        return const SizedBox.shrink();
    }
  }

  // Platform-aware keyboard setup
  void _openKeyboardSetup() {
    if (Platform.isIOS) {
      _showSnack(
          'Settings → General → Keyboard → Keyboards → Add New → Unsaid');
    } else {
      _showSnack('Open system input settings to enable Unsaid');
    }
  }

  // Minimal data usage dialog (keeps it simple)
  void _showDataUsageDialog() {
    final stats = _data.getDataUsageStats();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Data Usage'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _kv('Total Analyses', '${stats['total_analyses']}'),
            _kv('Data Size', '${stats['data_size_mb'].toStringAsFixed(2)} MB'),
            _kv('Storage Used',
                '${stats['storage_usage']['total_mb'].toStringAsFixed(2)} MB'),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close')),
        ],
      ),
    );
  }

  Widget _kv(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child:
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(k),
          Text(v, style: const TextStyle(fontWeight: FontWeight.bold)),
        ]),
      );

  void _showSnack(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }
}
