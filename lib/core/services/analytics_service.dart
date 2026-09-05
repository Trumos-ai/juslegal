import 'dart:async' show unawaited;
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart'
    show kDebugMode, kIsWeb, debugPrint, PlatformDispatcher;
import 'package:flutter/material.dart' show FlutterError, FlutterErrorDetails;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:juslegal/core/config/app_config.dart';
import 'package:juslegal/core/utils/logger.dart';

final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return AnalyticsService.instance;
});

class AnalyticsService {
  AnalyticsService._internal();

  static final AnalyticsService instance = AnalyticsService._internal();

  FirebaseAnalytics? _analytics;
  FirebaseCrashlytics? _crashlytics;
  FirebaseRemoteConfig? _remoteConfig;

  bool _isInitialized = false;
  bool _isAvailable = false;
  bool _analyticsEnabled = false;
  bool _crashlyticsEnabled = false;
  bool _performanceMonitoringEnabled = false;
  bool _userEngagementEnabled = false;

  static const String _analyticsConsentKey = 'analytics_consent';
  static const String _crashlyticsConsentKey = 'crashlytics_consent';
  static const String _performanceConsentKey = 'performance_consent';
  static const String _engagementConsentKey = 'engagement_consent';
  static const String _consentTimestampKey = 'analytics_consent_timestamp';

  String _sessionSalt = '';
  DateTime? _consentTimestamp;

  void Function(FlutterErrorDetails)? _previousFlutterErrorHandler;
  bool Function(Object, StackTrace)? _previousPlatformErrorHandler;

  DateTime? _engagementSessionStart;
  final Map<String, DateTime> _screenStartTime = {};
  final Map<String, int> _featureUsageCount = {};

  static const int _maxEventNameLength = 40;
  static const int _maxParameterCount = 25;
  static const int _maxParameterKeyLength = 24;
  static const int _maxParameterStringValueLength = 100;
  static final RegExp _eventNamePattern = RegExp(r'^[a-zA-Z][a-zA-Z0-9_]{0,39}$');

  bool get isInitialized => _isInitialized;
  bool get isAvailable => _isAvailable;
  bool get analyticsEnabled => _analyticsEnabled;
  bool get crashlyticsEnabled => _crashlyticsEnabled;
  bool get performanceMonitoringEnabled => _performanceMonitoringEnabled;
  bool get userEngagementEnabled => _userEngagementEnabled;
  bool get isConsentExpired => _isConsentExpired();

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _generateSessionSalt();

      final apps = Firebase.apps;
      if (apps.isEmpty) {
        if (kDebugMode) {
          debugPrint('[AnalyticsService] Firebase not initialized, analytics disabled');
        }
        logWarning('Firebase not initialized; analytics unavailable');
        _isInitialized = true;
        _isAvailable = false;
        return;
      }

      _analytics = FirebaseAnalytics.instance;

      if (!kIsWeb) {
        try {
          _crashlytics = FirebaseCrashlytics.instance;
        } catch (e) {
          if (kDebugMode) {
            debugPrint('[AnalyticsService] Crashlytics unavailable on this platform: $e');
          }
          logWarning('Crashlytics instantiation failed', error: e);
        }
      } else if (kDebugMode) {
        debugPrint('[AnalyticsService] Crashlytics skipped on web (unsupported)');
      }

      _isAvailable = true;

      await _loadConsentPreferences();

      if (FeatureFlags.remoteConfigEnabled) {
        await _initializeRemoteConfig();
      }

      await _applyConsentSettings();

      if (kDebugMode) {
        debugPrint('[AnalyticsService] Initialized successfully');
        debugPrint('[AnalyticsService] Analytics: $_analyticsEnabled, Crashlytics: $_crashlyticsEnabled');
        debugPrint('[AnalyticsService] Performance: $_performanceMonitoringEnabled, Engagement: $_userEngagementEnabled');
      }
      logInfo('Analytics initialized (available=$_isAvailable, analytics=$_analyticsEnabled)');
    } catch (e, stackTrace) {
      logError('Failed to initialize analytics', error: e, stackTrace: stackTrace);
      _isAvailable = false;
    } finally {
      _isInitialized = true;
    }
  }

  void _generateSessionSalt() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    _sessionSalt = base64Url.encode(bytes);
    if (kDebugMode) {
      debugPrint('[AnalyticsService] Session salt generated (${_sessionSalt.length} chars)');
    }
  }

  Future<void> _loadConsentPreferences() async {
    SharedPreferences? prefs;
    try {
      prefs = await SharedPreferences.getInstance();
    } catch (e, stackTrace) {
      logError('SharedPreferences.getInstance failed in _loadConsentPreferences',
          error: e, stackTrace: stackTrace);
      _analyticsEnabled = false;
      _crashlyticsEnabled = false;
      _performanceMonitoringEnabled = false;
      _userEngagementEnabled = false;
      return;
    }

    try {
      _analyticsEnabled = prefs.getBool(_analyticsConsentKey) ?? false;
      if (!FeatureFlags.analyticsConsentEnabled) {
        _analyticsEnabled = false;
      }

      _crashlyticsEnabled = prefs.getBool(_crashlyticsConsentKey) ?? false;

      _performanceMonitoringEnabled =
          FeatureFlags.performanceMonitoringEnabled &&
              (prefs.getBool(_performanceConsentKey) ?? false);

      _userEngagementEnabled =
          FeatureFlags.userEngagementTrackingEnabled &&
              (prefs.getBool(_engagementConsentKey) ?? false);

      final consentMillis = prefs.getInt(_consentTimestampKey);
      if (consentMillis != null) {
        _consentTimestamp = DateTime.fromMillisecondsSinceEpoch(consentMillis);
      }

      if (_isConsentExpired()) {
        _analyticsEnabled = false;
        _crashlyticsEnabled = false;
        _performanceMonitoringEnabled = false;
        _userEngagementEnabled = false;
        try {
          await prefs.remove(_analyticsConsentKey);
          await prefs.remove(_crashlyticsConsentKey);
          await prefs.remove(_performanceConsentKey);
          await prefs.remove(_engagementConsentKey);
          await prefs.remove(_consentTimestampKey);
        } catch (e, stackTrace) {
          logError('Failed to clear expired consent', error: e, stackTrace: stackTrace);
        }
        logInfo('Consent expired; all tracking disabled');
      }
    } catch (e, stackTrace) {
      logError('Failed to read consent preferences', error: e, stackTrace: stackTrace);
      _analyticsEnabled = false;
      _crashlyticsEnabled = false;
      _performanceMonitoringEnabled = false;
      _userEngagementEnabled = false;
    }
  }

  bool _isConsentExpired() {
    if (_consentTimestamp == null) return true;
    final expiryDuration = FeatureFlags.consentExpiryDuration;
    final now = DateTime.now();
    return now.difference(_consentTimestamp!) > expiryDuration;
  }

  DateTime? get consentTimestamp => _consentTimestamp;
  Duration get remainingConsentDuration {
    if (_consentTimestamp == null) return Duration.zero;
    final expiryDuration = FeatureFlags.consentExpiryDuration;
    final elapsed = DateTime.now().difference(_consentTimestamp!);
    final remaining = expiryDuration - elapsed;
    return remaining.isNegative ? Duration.zero : remaining;
  }

  Future<void> _initializeRemoteConfig() async {
    if (kIsWeb) return;
    try {
      _remoteConfig = FirebaseRemoteConfig.instance;
      await _remoteConfig!.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          minimumFetchInterval: kDebugMode
              ? const Duration(minutes: 1)
              : const Duration(hours: 12),
        ),
      );
      await _remoteConfig!.setDefaults(const <String, dynamic>{
        'analytics_sampling_rate': 1.0,
        'max_events_per_minute': 60,
      });
      try {
        final updated = await _remoteConfig!.fetchAndActivate();
        logInfo('RemoteConfig fetchAndActivate: $updated');
      } catch (e) {
        logWarning('RemoteConfig fetchAndActivate failed; using defaults/cached', error: e);
      }
    } catch (e, stackTrace) {
      logWarning('RemoteConfig initialization failed', error: e, stackTrace: stackTrace);
      _remoteConfig = null;
    }
  }

  T? getRemoteConfigValue<T>(String key, {T? defaultValue}) {
    if (_remoteConfig == null) return defaultValue;
    try {
      final value = _remoteConfig!.getValue(key);
      if (value.source == ValueSource.valueStatic) return defaultValue;
      switch (T) {
        case const (bool):
          return value.asBool() as T;
        case const (int):
          return value.asInt() as T;
        case const (double):
          return value.asDouble() as T;
        case const (String):
          return value.asString() as T;
        default:
          return defaultValue;
      }
    } catch (e, stackTrace) {
      logError('Failed to read remote config key "$key"', error: e, stackTrace: stackTrace);
      return defaultValue;
    }
  }

  Future<void> _applyConsentSettings() async {
    try {
      if (_analytics != null) {
        await _analytics!.setAnalyticsCollectionEnabled(_analyticsEnabled);
      }
    } catch (e, stackTrace) {
      logError('Failed to apply analytics collection setting', error: e, stackTrace: stackTrace);
    }

    if (!kIsWeb && _crashlytics != null) {
      try {
        await _crashlytics!.setCrashlyticsCollectionEnabled(_crashlyticsEnabled);
      } catch (e, stackTrace) {
        logError('Failed to apply crashlytics collection setting', error: e, stackTrace: stackTrace);
      }

      if (_crashlyticsEnabled) {
        _installErrorHandlers();
      } else {
        _restoreErrorHandlers();
      }
    }

    if (_userEngagementEnabled && _engagementSessionStart == null) {
      _trackSessionStart();
    } else if (!_userEngagementEnabled && _engagementSessionStart != null) {
      unawaited(_trackSessionEnd());
    }
  }

  void _installErrorHandlers() {
    if (_crashlytics == null) return;

    _previousFlutterErrorHandler ??= FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) async {
      try {
        await _crashlytics!.recordFlutterFatalError(details);
      } catch (_) {}
      final prev = _previousFlutterErrorHandler;
      if (prev != null) {
        try {
          prev(details);
        } catch (_) {}
      }
    };

    _previousPlatformErrorHandler ??= PlatformDispatcher.instance.onError;
    PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      bool result = true;
      try {
        _crashlytics!.recordError(error, stack, fatal: true);
      } catch (_) {}
      final prev = _previousPlatformErrorHandler;
      if (prev != null) {
        try {
          result = prev(error, stack);
        } catch (_) {}
      }
      return result;
    };

    logInfo('Error handlers installed (chained with previous handlers)');
  }

  void _restoreErrorHandlers() {
    if (_previousFlutterErrorHandler != null) {
      FlutterError.onError = _previousFlutterErrorHandler;
      _previousFlutterErrorHandler = null;
    }
    if (_previousPlatformErrorHandler != null) {
      PlatformDispatcher.instance.onError = _previousPlatformErrorHandler;
      _previousPlatformErrorHandler = null;
    }
  }

  Future<void> setAnalyticsConsent({
    required bool analytics,
    required bool crashlytics,
    bool performance = true,
    bool engagement = true,
  }) async {
    final anyEnabled = analytics || crashlytics || performance || engagement;

    if (anyEnabled && !FeatureFlags.analyticsConsentEnabled) {
      logWarning('analyticsConsentEnabled feature flag is off; refusing consent');
      return;
    }

    SharedPreferences? prefs;
    try {
      prefs = await SharedPreferences.getInstance();
    } catch (e, stackTrace) {
      logError('SharedPreferences.getInstance failed in setAnalyticsConsent',
          error: e, stackTrace: stackTrace);
      return;
    }

    try {
      _analyticsEnabled = analytics;
      _crashlyticsEnabled = crashlytics;
      _performanceMonitoringEnabled =
          FeatureFlags.performanceMonitoringEnabled && performance;
      _userEngagementEnabled =
          FeatureFlags.userEngagementTrackingEnabled && engagement;

      await Future.wait([
        prefs.setBool(_analyticsConsentKey, _analyticsEnabled),
        prefs.setBool(_crashlyticsConsentKey, _crashlyticsEnabled),
        prefs.setBool(_performanceConsentKey, _performanceMonitoringEnabled),
        prefs.setBool(_engagementConsentKey, _userEngagementEnabled),
        prefs.setInt(_consentTimestampKey, DateTime.now().millisecondsSinceEpoch),
      ]);

      _consentTimestamp = DateTime.now();
    } catch (e, stackTrace) {
      logError('Failed to persist consent preferences', error: e, stackTrace: stackTrace);
    }

    await _applyConsentSettings();
    logInfo('Consent updated: analytics=$_analyticsEnabled, crashlytics=$_crashlyticsEnabled, '
        'perf=$_performanceMonitoringEnabled, engagement=$_userEngagementEnabled');
  }

  Future<void> enableAll() async {
    await setAnalyticsConsent(
      analytics: true,
      crashlytics: true,
      performance: true,
      engagement: true,
    );
  }

  Future<void> disableAll() async {
    await setAnalyticsConsent(
      analytics: false,
      crashlytics: false,
      performance: false,
      engagement: false,
    );
  }

  bool _validateEvent(String name, Map<String, dynamic>? parameters) {
    if (name.isEmpty) {
      logWarning('Event name cannot be empty');
      return false;
    }
    if (name.length > _maxEventNameLength) {
      logWarning('Event name "$name" exceeds max length $_maxEventNameLength (${name.length})');
      return false;
    }
    if (!_eventNamePattern.hasMatch(name)) {
      logWarning('Event name "$name" does not match required pattern '
          '(must start with letter, alphanumeric + underscore only, <=40 chars)');
      return false;
    }
    if (parameters != null) {
      if (parameters.length > _maxParameterCount) {
        logWarning('Event "$name" has ${parameters.length} parameters; max is $_maxParameterCount');
        return false;
      }
      for (final entry in parameters.entries) {
        if (entry.key.isEmpty || entry.key.length > _maxParameterKeyLength) {
          logWarning('Event "$name" parameter key "${entry.key}" invalid (1-$_maxParameterKeyLength chars)');
          return false;
        }
        final value = entry.value;
        if (value is String && value.length > _maxParameterStringValueLength) {
          logWarning('Event "$name" param "${entry.key}" string exceeds max length '
              '$_maxParameterStringValueLength (${value.length})');
          return false;
        }
        if (value is! String && value is! int && value is! double && value is! num && value is! bool) {
          logWarning('Event "$name" param "${entry.key}" has unsupported type ${value.runtimeType}');
          return false;
        }
      }
    }
    return true;
  }

  Future<void> logEvent({
    required String name,
    Map<String, dynamic>? parameters,
  }) async {
    if (!_isAvailable || _analytics == null || !_analyticsEnabled) {
      return;
    }

    if (!_validateEvent(name, parameters)) {
      return;
    }

    try {
      final filtered = filterSensitiveParameters(parameters ?? const {});
      final sanitized = <String, Object>{};
      filtered.forEach((key, value) {
        if (value is String) {
          sanitized[key] = value;
        } else if (value is int) {
          sanitized[key] = value;
        } else if (value is double) {
          sanitized[key] = value;
        } else if (value is num) {
          sanitized[key] = value.toDouble();
        } else if (value is bool) {
          sanitized[key] = value ? 1 : 0;
        } else {
          sanitized[key] = value.toString();
        }
      });

      await _analytics!.logEvent(name: name, parameters: sanitized.isEmpty ? null : sanitized);
      if (kDebugMode) {
        debugPrint('[AnalyticsService] Logged event: $name');
      }
    } catch (e, stackTrace) {
      logError('Failed to log event "$name"', error: e, stackTrace: stackTrace);
    }
  }

  Future<void> logScreenView({required String screenName}) async {
    await logEvent(name: 'screen_view', parameters: {'screen_name': screenName});
    if (_userEngagementEnabled) {
      _screenStartTime[screenName] = DateTime.now();
    }
  }

  Future<void> logScreenExit({required String screenName}) async {
    if (!_userEngagementEnabled) return;
    final start = _screenStartTime.remove(screenName);
    if (start == null) return;
    final durationMs = DateTime.now().difference(start).inMilliseconds;
    await logEvent(
      name: 'screen_time',
      parameters: {
        'screen_name': screenName,
        'duration_ms': durationMs.clamp(0, 2147483647),
      },
    );
  }

  Future<void> logAction({
    required String actionName,
    Map<String, dynamic>? parameters,
  }) async {
    await logEvent(name: actionName, parameters: parameters);
    if (_userEngagementEnabled) {
      _featureUsageCount[actionName] = (_featureUsageCount[actionName] ?? 0) + 1;
    }
  }

  Future<void> setUserId({String? id}) async {
    if (!_isAvailable || _analytics == null) return;
    try {
      final hashedId = id == null ? null : hashSensitiveText(id);
      await _analytics!.setUserId(id: hashedId);
      if (!kIsWeb && _crashlytics != null && id != null) {
        await _crashlytics!.setUserIdentifier(hashedId ?? '');
      }
    } catch (e, stackTrace) {
      logError('Failed to set user ID', error: e, stackTrace: stackTrace);
    }
  }

  Future<void> setUserProperty({
    required String name,
    required String value,
  }) async {
    if (!_isAvailable || _analytics == null) return;
    try {
      await _analytics!.setUserProperty(name: name, value: value);
    } catch (e, stackTrace) {
      logError('Failed to set user property "$name"', error: e, stackTrace: stackTrace);
    }
  }

  void reset() {
    _restoreErrorHandlers();
    _engagementSessionStart = null;
    _screenStartTime.clear();
    _featureUsageCount.clear();
    _isInitialized = false;
    _isAvailable = false;
    _analytics = null;
    _crashlytics = null;
    _remoteConfig = null;
  }

  void _trackSessionStart() {
    _engagementSessionStart = DateTime.now();
    unawaited(logEvent(name: 'session_start', parameters: {
      'timestamp': DateTime.now().millisecondsSinceEpoch ~/ 1000,
    }));
  }

  Future<void> _trackSessionEnd() async {
    if (_engagementSessionStart == null) return;
    final durationMs = DateTime.now().difference(_engagementSessionStart!).inMilliseconds;
    _engagementSessionStart = null;
    await logEvent(name: 'session_end', parameters: {
      'duration_ms': durationMs.clamp(0, 2147483647),
      'feature_usage_count': _featureUsageCount.values.fold<int>(0, (a, b) => a + b),
      'distinct_features': _featureUsageCount.length,
    });
  }

  Future<void> trackAppLifecyclePause() async {
    if (_userEngagementEnabled) {
      await _trackSessionEnd();
    }
  }

  void trackAppLifecycleResume() {
    if (_userEngagementEnabled) {
      _trackSessionStart();
    }
  }

  Future<T> trackPerformance<T>({
    required String name,
    required Future<T> Function() operation,
    Map<String, dynamic>? attributes,
  }) async {
    final shouldTrack = _isAvailable &&
        _analyticsEnabled &&
        _performanceMonitoringEnabled &&
        FeatureFlags.performanceMonitoringEnabled;

    if (!shouldTrack) return operation();

    final stopwatch = Stopwatch()..start();
    bool success = true;
    try {
      return await operation();
    } catch (_) {
      success = false;
      rethrow;
    } finally {
      stopwatch.stop();
      try {
        final params = <String, dynamic>{
          'perf_name': name,
          'duration_ms': stopwatch.elapsedMilliseconds.clamp(0, 2147483647),
          'success': success ? 1 : 0,
        };
        if (attributes != null) {
          for (final e in attributes.entries.take(20)) {
            params['attr_${e.key}'] = _truncateForAnalytics(e.value.toString());
          }
        }
        unawaited(logEvent(name: 'perf_trace', parameters: params));
      } catch (_) {}
    }
  }

  T trackPerformanceSync<T>({
    required String name,
    required T Function() operation,
    Map<String, dynamic>? attributes,
  }) {
    final shouldTrack = _isAvailable &&
        _analyticsEnabled &&
        _performanceMonitoringEnabled &&
        FeatureFlags.performanceMonitoringEnabled;

    if (!shouldTrack) return operation();

    final stopwatch = Stopwatch()..start();
    bool success = true;
    try {
      return operation();
    } catch (_) {
      success = false;
      rethrow;
    } finally {
      stopwatch.stop();
      try {
        final params = <String, dynamic>{
          'perf_name': name,
          'duration_ms': stopwatch.elapsedMilliseconds.clamp(0, 2147483647),
          'success': success ? 1 : 0,
        };
        if (attributes != null) {
          for (final e in attributes.entries.take(20)) {
            params['attr_${e.key}'] = _truncateForAnalytics(e.value.toString());
          }
        }
        unawaited(logEvent(name: 'perf_trace', parameters: params));
      } catch (_) {}
    }
  }

  String _truncateForAnalytics(String value) {
    if (value.length <= _maxParameterStringValueLength) return value;
    return '${value.substring(0, _maxParameterStringValueLength - 3)}...';
  }

  String hashSensitiveText(String text) {
    try {
      final saltedInput = '$_sessionSalt|$text';
      final bytes = utf8.encode(saltedInput);
      final digest = sha256.convert(bytes);
      final fullHash = digest.toString();
      return 'h_${fullHash.substring(0, 16)}';
    } catch (error, stackTrace) {
      logError('Error hashing text', error: error, stackTrace: stackTrace);
      return 'h_error';
    }
  }

  String hashSensitiveTextStable(String text) {
    try {
      final bytes = utf8.encode(text);
      final digest = sha256.convert(bytes);
      return 'hs_${digest.toString().substring(0, 12)}';
    } catch (error, stackTrace) {
      logError('Error hashing text (stable)', error: error, stackTrace: stackTrace);
      return 'hs_error';
    }
  }

  String maskCurrencyAmount(double amount) {
    if (amount <= 0) return 'no_amount';
    if (amount < 1000) return 'bracket_<1k';
    if (amount < 10000) return 'bracket_1k-10k';
    if (amount < 50000) return 'bracket_10k-50k';
    if (amount < 100000) return 'bracket_50k-1L';
    if (amount < 500000) return 'bracket_1L-5L';
    if (amount < 1000000) return 'bracket_5L-10L';
    if (amount < 10000000) return 'bracket_10L-1Cr';
    return 'bracket_>1Cr';
  }

  static final List<_PiiRule> _piiRules = [
    _PiiRule(
      RegExp(r'''[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}'''),
      '[EMAIL]',
    ),
    _PiiRule(
      RegExp(r'''(?<!\d)(?:\+?\d{1,3}[-.\s]?)?(?:\(?\d{3}\)?[-.\s]?)?\d{3}[-.\s]?\d{4}(?!\d)'''),
      '[PHONE]',
    ),
    _PiiRule(
      RegExp(r'''(?<!\d)\d{4}[\s-]?\d{4}[\s-]?\d{4}(?!\d)'''),
      '[AADHAR]',
    ),
    _PiiRule(
      RegExp(r'''(?<![A-Z0-9])[A-Z]{5}\d{4}[A-Z](?![A-Z0-9])'''),
      '[PAN]',
    ),
    _PiiRule(
      RegExp(r'''(?<![A-Z0-9])[A-Z]\d{7}[A-Z](?![A-Z0-9])'''),
      '[PASSPORT]',
    ),
    _PiiRule(
      RegExp(r'''(?<![\d.])(?:(?:25[0-5]|2[0-4]\d|[01]?\d\d?)\.){3}(?:25[0-5]|2[0-4]\d|[01]?\d\d?)(?![\d.])'''),
      '[IP]',
    ),
    _PiiRule(
      RegExp(r'''(?<!\d)\d{4}[\s-]?\d{4}[\s-]?\d{4}[\s-]?\d{4}(?!\d)'''),
      '[CREDIT_CARD]',
    ),
    _PiiRule(
      RegExp(r'''(?<!\d)\d{9,18}(?!\d)'''),
      '[BANK_ACC]',
    ),
    _PiiRule(
      RegExp(r'''[₹$€£¥₽]\s?\d+(?:[.,]\d+)?(?:\s?\w{0,3})?'''),
      '[AMOUNT]',
    ),
    _PiiRule(
      RegExp(r'''\d+(?:[.,]\d+)?\s?(?:rs|rupees?|inr|usd|dollars?|euros?|pounds?)\b''', caseSensitive: false),
      '[AMOUNT]',
    ),
    _PiiRule(
      RegExp(r'''https?://[^\s<>"']+'''),
      '[URL]',
    ),
    _PiiRule(
      RegExp(r'''(?<![\w.-])(?:\d{1,2}\s?(?:jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)[a-z]*\s?\d{2,4}|\d{1,2}[-/]\d{1,2}[-/]\d{2,4})(?![\w.-])''', caseSensitive: false),
      '[DATE]',
    ),
  ];

  String sanitizeForLogging(String text) {
    try {
      var sanitized = text;
      for (final rule in _piiRules) {
        sanitized = sanitized.replaceAllMapped(rule.pattern, (match) {
          final matched = match.group(0) ?? '';
          if (_isLikelyFalsePositive(matched)) return matched;
          return rule.replacement;
        });
      }
      return sanitized;
    } catch (error, stackTrace) {
      logError('Error sanitizing text', error: error, stackTrace: stackTrace);
      return '[SANITIZATION_ERROR]';
    }
  }

  bool _isLikelyFalsePositive(String matched) {
    if (RegExp(r'^\d{4}$').hasMatch(matched)) return true;
    if (matched.length == 10 && double.tryParse(matched) != null) {
      if (int.tryParse(matched[0]) == 0 || int.tryParse(matched[0]) == 1) return true;
    }
    return false;
  }

  Map<String, dynamic> filterSensitiveParameters(Map<String, dynamic> params) {
    const sensitiveKeys = {
      'amount', 'money', 'cost', 'price', 'value', 'fee', 'salary',
      'name', 'fullname', 'full_name', 'firstname', 'first_name',
      'lastname', 'last_name', 'middlename', 'middle_name',
      'phone', 'mobile', 'cell', 'telephone', 'contact',
      'email', 'emailid', 'email_id', 'mail',
      'address', 'street', 'city', 'state', 'pincode', 'zip', 'zipcode',
      'country', 'location', 'latitude', 'longitude', 'lat', 'lng',
      'dob', 'birthdate', 'birth_date', 'birthday', 'age',
      'aadhar', 'aadharnumber', 'aadhaar', 'uid', 'uidai',
      'pan', 'pannumber', 'pan_number', 'tin', 'tan', 'gstin', 'gst',
      'passport', 'passportno', 'passport_number', 'passport_no',
      'bank', 'account', 'accountno', 'account_number', 'accno', 'ifsc',
      'creditcard', 'credit_card', 'debitcard', 'debit_card', 'cardnumber', 'card_number', 'cvv',
      'ip', 'ipaddress', 'ip_address',
      'userid', 'user_id', 'customerid', 'customer_id', 'ssn',
      'password', 'passwd', 'secret', 'token', 'apikey', 'api_key', 'authorization',
    };

    final filtered = <String, dynamic>{};
    params.forEach((key, value) {
      final lowerKey = key.toLowerCase();
      if (sensitiveKeys.any((sensitive) => lowerKey.contains(sensitive))) {
        return;
      }
      if (value is String) {
        filtered[key] = sanitizeForLogging(value);
      } else {
        filtered[key] = value;
      }
    });
    return filtered;
  }

  Future<void> logCaseAnalysis({
    required String caseCategory,
    required String caseTopic,
    required double caseAmount,
    required int strengthScore,
  }) async {
    final sanitizedTopic = hashSensitiveText(caseTopic);
    final amountBracket = maskCurrencyAmount(caseAmount);
    await logEvent(
      name: 'case_analysis',
      parameters: {
        'category': caseCategory,
        'topic_hash': sanitizedTopic,
        'amount_bracket': amountBracket,
        'strength_score': strengthScore.clamp(1, 10),
      },
    );
  }

  Future<void> logLetterGeneration({
    required String letterType,
    required String category,
    required bool success,
    required int timeMs,
  }) async {
    await logEvent(
      name: 'letter_generated',
      parameters: {
        'letter_type': letterType,
        'category': category,
        'success': success ? 1 : 0,
        'generation_time_ms': timeMs.clamp(0, 2147483647),
      },
    );
  }

  void logInfo(String message, {String? tag}) => logger.info(message, tag: tag ?? 'AnalyticsService');
  void logWarning(String message, {Object? error, StackTrace? stackTrace}) =>
      logger.warning(message, tag: 'AnalyticsService', error: error, stackTrace: stackTrace);
  void logError(String message, {Object? error, StackTrace? stackTrace}) =>
      logger.error(message, tag: 'AnalyticsService', error: error, stackTrace: stackTrace);
}

class _PiiRule {
  final Pattern pattern;
  final String replacement;
  const _PiiRule(this.pattern, this.replacement);
}

@Deprecated('Use analyticsServiceProvider (Riverpod) or AnalyticsService.instance directly')
class SafeAnalytics {
  static AnalyticsService get _svc => AnalyticsService.instance;

  @Deprecated('Call AnalyticsService.instance.initialize() or ref.read(analyticsServiceProvider).initialize()')
  static Future<void> initialize() => _svc.initialize();

  @Deprecated('Use AnalyticsService.instance or analyticsServiceProvider')
  static bool get isAvailable => _svc.isAvailable;

  @Deprecated('Use AnalyticsService.instance or analyticsServiceProvider')
  static bool get analyticsEnabled => _svc.analyticsEnabled;

  @Deprecated('Use AnalyticsService.instance or analyticsServiceProvider')
  static bool get crashlyticsEnabled => _svc.crashlyticsEnabled;

  @Deprecated('Use setAnalyticsConsent() on AnalyticsService.instance')
  static Future<void> enableAnalytics() => _svc.setAnalyticsConsent(
        analytics: true,
        crashlytics: _svc.crashlyticsEnabled,
        performance: _svc.performanceMonitoringEnabled,
        engagement: _svc.userEngagementEnabled,
      );

  @Deprecated('Use setAnalyticsConsent() on AnalyticsService.instance')
  static Future<void> disableAnalytics() => _svc.setAnalyticsConsent(
        analytics: false,
        crashlytics: _svc.crashlyticsEnabled,
        performance: _svc.performanceMonitoringEnabled,
        engagement: _svc.userEngagementEnabled,
      );

  @Deprecated('Use setAnalyticsConsent() on AnalyticsService.instance')
  static Future<void> enableCrashlytics() => _svc.setAnalyticsConsent(
        analytics: _svc.analyticsEnabled,
        crashlytics: true,
        performance: _svc.performanceMonitoringEnabled,
        engagement: _svc.userEngagementEnabled,
      );

  @Deprecated('Use setAnalyticsConsent() on AnalyticsService.instance')
  static Future<void> disableCrashlytics() => _svc.setAnalyticsConsent(
        analytics: _svc.analyticsEnabled,
        crashlytics: false,
        performance: _svc.performanceMonitoringEnabled,
        engagement: _svc.userEngagementEnabled,
      );

  @Deprecated('Use enableAll() on AnalyticsService.instance')
  static Future<void> enableAll() => _svc.enableAll();

  @Deprecated('Use disableAll() on AnalyticsService.instance')
  static Future<void> disableAll() => _svc.disableAll();

  @Deprecated('Use AnalyticsService.instance or analyticsServiceProvider')
  static Future<void> logEvent({
    required String name,
    Map<String, dynamic>? parameters,
  }) =>
      _svc.logEvent(name: name, parameters: parameters);

  @Deprecated('Use AnalyticsService.instance or analyticsServiceProvider')
  static Future<void> logScreenView({required String screenName}) =>
      _svc.logScreenView(screenName: screenName);

  @Deprecated('Use AnalyticsService.instance or analyticsServiceProvider')
  static Future<void> logAction({
    required String actionName,
    Map<String, dynamic>? parameters,
  }) =>
      _svc.logAction(actionName: actionName, parameters: parameters);

  @Deprecated('Use AnalyticsService.instance or analyticsServiceProvider')
  static Future<void> setUserId({String? id}) => _svc.setUserId(id: id);

  @Deprecated('Use AnalyticsService.instance or analyticsServiceProvider')
  static Future<void> setUserProperty({
    required String name,
    required String value,
  }) =>
      _svc.setUserProperty(name: name, value: value);

  @Deprecated('Call reset() on AnalyticsService.instance')
  static void reset() => _svc.reset();

  @Deprecated('Use AnalyticsService.instance.hashSensitiveText()')
  static String hashSensitiveText(String text) => _svc.hashSensitiveText(text);

  @Deprecated('Use AnalyticsService.instance.maskCurrencyAmount()')
  static String maskCurrencyAmount(double amount) => _svc.maskCurrencyAmount(amount);

  @Deprecated('Use AnalyticsService.instance.sanitizeForLogging()')
  static String sanitizeForLogging(String text) => _svc.sanitizeForLogging(text);

  @Deprecated('Use AnalyticsService.instance.filterSensitiveParameters()')
  static Map<String, dynamic> filterSensitiveParameters(Map<String, dynamic> params) =>
      _svc.filterSensitiveParameters(params);

  @Deprecated('Use AnalyticsService.instance.logCaseAnalysis()')
  static Future<void> logCaseAnalysis({
    required String caseCategory,
    required String caseTopic,
    required double caseAmount,
    required int strengthScore,
  }) =>
      _svc.logCaseAnalysis(
        caseCategory: caseCategory,
        caseTopic: caseTopic,
        caseAmount: caseAmount,
        strengthScore: strengthScore,
      );

  @Deprecated('Use AnalyticsService.instance.logLetterGeneration()')
  static Future<void> logLetterGeneration({
    required String letterType,
    required String category,
    required bool success,
    required int timeMs,
  }) =>
      _svc.logLetterGeneration(
        letterType: letterType,
        category: category,
        success: success,
        timeMs: timeMs,
      );
}
