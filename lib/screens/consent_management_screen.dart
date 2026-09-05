import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:juslegal/core/core.dart';
import 'package:juslegal/l10n/gen/app_localizations.dart';

class _Labels {
  static const String privacyPreferences = 'Privacy Preferences';
  static const String dataCollection = 'Data Collection';
  static const String analyticsTitle = 'Usage Analytics';
  static const String analyticsSubtitle =
      'Help improve the app by sharing anonymous usage patterns. Data like which screens you visit and which features you use.';
  static const String crashlyticsTitle = 'Crash Reports';
  static const String crashlyticsSubtitle =
      'Share crash data to help fix bugs faster. Includes device info and stack traces. No personal content is sent.';
  static const String performanceEngagement = 'Performance & Engagement';
  static const String performanceTitle = 'Performance Monitoring';
  static const String performanceSubtitle =
      'Measure app responsiveness and load times. Helps identify slow operations so they can be fixed.';
  static const String engagementTitle = 'Engagement Tracking';
  static const String engagementSubtitle =
      'Track session duration, time spent on screens, and how often features are used. All data is aggregated.';
  static const String yourPrivacyChoices = 'Your Privacy Choices';
  static const String privacyChoicesSubtitle =
      'You control what data we collect. All settings take effect immediately.';
  static const String consentLastUpdated = 'Consent last updated';
  static const String never = 'Never';
  static const String consentExpiresIn = 'Consent expires in';
  static const String days = 'days';
  static const String expired = 'Expired';
  static const String weNeverCollect = 'We Never Collect';
  static const String weDontCollectContent = 'Legal case details you enter';
  static const String weDontCollectCredentials = 'Passwords or authentication credentials';
  static const String weDontCollectDocuments = 'Uploaded documents or file contents';
  static const String consentSaved = 'Preferences saved';
  static const String consentSaveError = 'Failed to save preferences. Please try again.';
  static const String saving = 'Saving...';
  static const String savePreferences = 'Save Preferences';
  static const String rejectAll = 'Reject All';
  static const String acceptAll = 'Accept All';
}

class ConsentManagementScreen extends ConsumerStatefulWidget {
  const ConsentManagementScreen({super.key});

  @override
  ConsumerState<ConsentManagementScreen> createState() =>
      _ConsentManagementScreenState();
}

class _ConsentManagementScreenState
    extends ConsumerState<ConsentManagementScreen> {
  bool _analytics = false;
  bool _crashlytics = false;
  bool _performance = false;
  bool _engagement = false;

  bool _isSaving = false;
  bool _isLoading = true;

  final int _consentExpiryDays =
      FeatureFlags.consentExpiryDuration.inDays;

  @override
  void initState() {
    super.initState();
    _loadCurrentConsent();
  }

  Future<void> _loadCurrentConsent() async {
    final service = ref.read(analyticsServiceProvider);
    if (!service.isInitialized) {
      try {
        await service.initialize();
      } catch (_) {}
    }
    if (!mounted) return;
    setState(() {
      _analytics = service.analyticsEnabled;
      _crashlytics = service.crashlyticsEnabled;
      _performance = service.performanceMonitoringEnabled;
      _engagement = service.userEngagementEnabled;
      _isLoading = false;
    });
  }

  String _formatDuration(Duration d) {
    if (d.inDays > 0) {
      final months = (d.inDays / 30).round();
      if (months >= 1) return '$months month${months == 1 ? '' : 's'}';
      return '${d.inDays} day${d.inDays == 1 ? '' : 's'}';
    }
    if (d.inHours > 0) return '${d.inHours} hour${d.inHours == 1 ? '' : 's'}';
    if (d.inMinutes > 0) return '${d.inMinutes} minute${d.inMinutes == 1 ? '' : 's'}';
    return _Labels.expired;
  }

  String? _formatTimestamp(DateTime? dt) {
    if (dt == null) return null;
    try {
      return DateFormat.yMMMd().add_jm().format(dt.toLocal());
    } catch (_) {
      return dt.toIso8601String().substring(0, 10);
    }
  }

  Future<void> _saveConsent() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    final messenger = ScaffoldMessenger.of(context);

    try {
      final service = ref.read(analyticsServiceProvider);
      await service.setAnalyticsConsent(
        analytics: _analytics,
        crashlytics: _crashlytics,
        performance: _performance,
        engagement: _engagement,
      );
      messenger.showSnackBar(
        SnackBar(
          content: const Text(_Labels.consentSaved),
          backgroundColor: AppColors.primaryContainer,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 400));
      if (mounted && context.canPop()) context.pop();
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: const Text(_Labels.consentSaveError),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _acceptAll() async {
    setState(() {
      _analytics = FeatureFlags.analyticsConsentEnabled;
      _crashlytics = !kIsWeb;
      _performance = FeatureFlags.performanceMonitoringEnabled;
      _engagement = FeatureFlags.userEngagementTrackingEnabled;
    });
    await _saveConsent();
  }

  Future<void> _rejectAll() async {
    setState(() {
      _analytics = false;
      _crashlytics = false;
      _performance = false;
      _engagement = false;
    });
    await _saveConsent();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final service = ref.watch(analyticsServiceProvider);
    final consentDate = service.consentTimestamp;
    final remaining = service.remainingConsentDuration;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_Labels.privacyPreferences),
        backgroundColor: AppColors.background,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.only(bottom: 120),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeaderCard(l10n, consentDate, remaining),
                          const SizedBox(height: 8),
                          _buildSectionLabel(_Labels.dataCollection),
                          _buildToggleTile(
                            icon: Icons.analytics_outlined,
                            title: _Labels.analyticsTitle,
                            subtitle: _Labels.analyticsSubtitle,
                            value: _analytics,
                            onChanged: FeatureFlags.analyticsConsentEnabled
                                ? (v) => setState(() => _analytics = v)
                                : null,
                            enabled: FeatureFlags.analyticsConsentEnabled,
                          ),
                          if (!kIsWeb) ...[
                            const Divider(indent: 72, endIndent: 16, height: 1),
                            _buildToggleTile(
                              icon: Icons.bug_report_outlined,
                              title: _Labels.crashlyticsTitle,
                              subtitle: _Labels.crashlyticsSubtitle,
                              value: _crashlytics,
                              onChanged: (v) => setState(() => _crashlytics = v),
                            ),
                          ],
                          const Divider(indent: 16, endIndent: 16),
                          _buildSectionLabel(_Labels.performanceEngagement),
                          _buildToggleTile(
                            icon: Icons.speed_outlined,
                            title: _Labels.performanceTitle,
                            subtitle: _Labels.performanceSubtitle,
                            value: _performance,
                            onChanged: FeatureFlags.performanceMonitoringEnabled
                                ? (v) => setState(() => _performance = v)
                                : null,
                            enabled: FeatureFlags.performanceMonitoringEnabled,
                          ),
                          const Divider(indent: 72, endIndent: 16, height: 1),
                          _buildToggleTile(
                            icon: Icons.timeline_outlined,
                            title: _Labels.engagementTitle,
                            subtitle: _Labels.engagementSubtitle,
                            value: _engagement,
                            onChanged: FeatureFlags.userEngagementTrackingEnabled
                                ? (v) => setState(() => _engagement = v)
                                : null,
                            enabled: FeatureFlags.userEngagementTrackingEnabled,
                          ),
                          const Divider(indent: 16, endIndent: 16),
                          _buildWhatWeDontCollect(),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                  _buildBottomActionBar(),
                ],
              ),
            ),
    );
  }

  Widget _buildHeaderCard(
    AppLocalizations l10n,
    DateTime? consentDate,
    Duration remaining,
  ) {
    final service = ref.read(analyticsServiceProvider);
    final isExpired = service.isConsentExpired;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderLow),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.shield_outlined,
                    color: AppColors.primary,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        _Labels.yourPrivacyChoices,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        _Labels.privacyChoicesSubtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.borderLow),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        _Labels.consentLastUpdated,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        _formatTimestamp(consentDate) ?? _Labels.never,
                        style: TextStyle(
                          fontSize: 12,
                          color: consentDate == null
                              ? AppColors.textSecondary
                              : AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        _Labels.consentExpiresIn,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '$_consentExpiryDays ${_Labels.days} (${isExpired ? _Labels.expired : _formatDuration(remaining)})',
                        style: TextStyle(
                          fontSize: 12,
                          color: isExpired
                              ? AppColors.error
                              : AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          letterSpacing: 1.0,
          color: AppColors.legalGold,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildToggleTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool>? onChanged,
    bool enabled = true,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ListTile(
        horizontalTitleGap: 8,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        enabled: enabled,
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: enabled
                ? AppColors.primaryContainer.withValues(alpha: 0.15)
                : AppColors.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 22,
            color: enabled ? AppColors.primary : AppColors.textSecondary.withValues(alpha: 0.5),
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: enabled ? AppColors.textPrimary : AppColors.textSecondary.withValues(alpha: 0.6),
            height: 1.3,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: enabled ? AppColors.textSecondary : AppColors.textSecondary.withValues(alpha: 0.5),
              height: 1.4,
            ),
          ),
        ),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeTrackColor: AppColors.primary.withValues(alpha: 0.5),
          activeThumbColor: AppColors.primary,
        ),
        onTap: enabled && onChanged != null
            ? () => onChanged(!value)
            : null,
      ),
    );
  }

  Widget _buildWhatWeDontCollect() {
    final items = [
      Icons.block_outlined,
      Icons.hide_source_outlined,
      Icons.private_connectivity_outlined,
    ];
    final labels = const [
      _Labels.weDontCollectContent,
      _Labels.weDontCollectCredentials,
      _Labels.weDontCollectDocuments,
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.primaryContainer.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.primaryContainer.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lock_outline, color: AppColors.primary, size: 18),
                const SizedBox(width: 8),
                const Text(
                  _Labels.weNeverCollect,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...List.generate(items.length, (i) {
              return Padding(
                padding: EdgeInsets.only(bottom: i < items.length - 1 ? 6 : 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Icon(items[i], size: 16, color: AppColors.primary.withValues(alpha: 0.8)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        labels[i],
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.onPrimaryContainer,
                          height: 1.45,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActionBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(
          top: BorderSide(color: AppColors.borderLow),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveConsent,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSaving
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.onPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            _Labels.saving,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      )
                    : const Text(
                        _Labels.savePreferences,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: _isSaving ? null : _rejectAll,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(color: AppColors.borderLow),
                      ),
                    ),
                    child: const Text(
                      _Labels.rejectAll,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextButton(
                    onPressed: _isSaving || !FeatureFlags.analyticsConsentEnabled
                        ? null
                        : _acceptAll,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(
                          color: FeatureFlags.analyticsConsentEnabled
                              ? AppColors.primary
                              : AppColors.borderLow,
                        ),
                      ),
                    ),
                    child: const Text(
                      _Labels.acceptAll,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
