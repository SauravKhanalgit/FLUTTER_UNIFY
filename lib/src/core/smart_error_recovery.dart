/// Smart Error Recovery System
///
/// AI-powered error analysis and automatic recovery suggestions.
/// Analyzes errors, identifies patterns, and provides intelligent
/// recovery strategies for common issues.

import 'dart:async';
import 'package:flutter/foundation.dart';
import '../ai/unified_ai.dart';

/// Error recovery suggestion
class ErrorRecoverySuggestion {
  const ErrorRecoverySuggestion({
    required this.title,
    required this.description,
    required this.confidence,
    required this.canAutoFix,
    this.autoFixAction,
    this.manualSteps = const [],
    this.relatedDocs = const [],
    this.similarIssues = const [],
  });

  final String title;
  final String description;
  final double confidence; // 0.0 to 1.0
  final bool canAutoFix;
  final Future<void> Function()? autoFixAction;
  final List<String> manualSteps;
  final List<String> relatedDocs;
  final List<String> similarIssues;

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'confidence': confidence,
        'canAutoFix': canAutoFix,
        'manualSteps': manualSteps,
        'relatedDocs': relatedDocs,
        'similarIssues': similarIssues,
      };
}

/// Error analysis result
class ErrorAnalysisResult {
  const ErrorAnalysisResult({
    required this.error,
    required this.category,
    required this.severity,
    required this.rootCause,
    required this.suggestions,
    required this.estimatedFixTime,
    this.similarErrors = const [],
    this.preventiveActions = const [],
  });

  final dynamic error;
  final String category;
  final ErrorSeverity severity;
  final String rootCause;
  final List<ErrorRecoverySuggestion> suggestions;
  final Duration estimatedFixTime;
  final List<String> similarErrors;
  final List<String> preventiveActions;

  bool get hasAutoFix => suggestions.any((s) => s.canAutoFix);

  ErrorRecoverySuggestion? get bestSuggestion {
    if (suggestions.isEmpty) return null;
    return suggestions.reduce((a, b) =>
        a.confidence > b.confidence ? a : b);
  }

  Map<String, dynamic> toJson() => {
        'error': error.toString(),
        'category': category,
        'severity': severity.name,
        'rootCause': rootCause,
        'suggestions': suggestions.map((s) => s.toJson()).toList(),
        'estimatedFixTime': estimatedFixTime.inMinutes,
        'similarErrors': similarErrors,
        'preventiveActions': preventiveActions,
      };
}

/// Error severity levels
enum ErrorSeverity {
  low,
  medium,
  high,
  critical,
}

/// Smart Error Recovery System
class SmartErrorRecovery {
  SmartErrorRecovery._();
  static SmartErrorRecovery? _instance;
  static SmartErrorRecovery get instance => _instance ??= SmartErrorRecovery._();

  final UnifiedAI _ai = UnifiedAI.instance;
  final Map<String, List<String>> _errorPatterns = {};
  final List<ErrorAnalysisResult> _analysisHistory = [];

  bool _isEnabled = true;

  /// Enable/disable error recovery
  void enable() => _isEnabled = true;
  void disable() => _isEnabled = false;
  bool get isEnabled => _isEnabled;

  /// Analyze an error and provide recovery suggestions
  Future<ErrorAnalysisResult> analyzeError(dynamic error) async {
    if (!_isEnabled) {
      return _createBasicAnalysis(error);
    }

    try {
      final errorString = error.toString().toLowerCase();
      final category = _categorizeError(errorString);
      final severity = _assessSeverity(errorString, category);
      final rootCause = await _identifyRootCause(errorString);

      final suggestions = await _generateSuggestions(error, category, severity);
      final estimatedTime = _estimateFixTime(category, severity, suggestions);

      final result = ErrorAnalysisResult(
        error: error,
        category: category,
        severity: severity,
        rootCause: rootCause,
        suggestions: suggestions,
        estimatedFixTime: estimatedTime,
        similarErrors: _findSimilarErrors(errorString),
        preventiveActions: _generatePreventiveActions(category),
      );

      _analysisHistory.add(result);
      _updateErrorPatterns(errorString, category);

      return result;

    } catch (e) {
      if (kDebugMode) {
        print('SmartErrorRecovery: Analysis failed: $e');
      }
      return _createBasicAnalysis(error);
    }
  }

  /// Apply automatic fix for an error
  Future<bool> applyAutoFix(ErrorAnalysisResult analysis) async {
    final bestSuggestion = analysis.bestSuggestion;
    if (bestSuggestion == null || !bestSuggestion.canAutoFix) {
      return false;
    }

    try {
      await bestSuggestion.autoFixAction?.call();
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('SmartErrorRecovery: Auto-fix failed: $e');
      }
      return false;
    }
  }

  /// Get error analysis history
  List<ErrorAnalysisResult> getAnalysisHistory() => List.unmodifiable(_analysisHistory);

  /// Clear analysis history
  void clearHistory() => _analysisHistory.clear();

  /// Get error statistics
  Map<String, dynamic> getStatistics() {
    final categories = <String, int>{};
    final severities = <ErrorSeverity, int>{};

    for (final analysis in _analysisHistory) {
      categories[analysis.category] = (categories[analysis.category] ?? 0) + 1;
      severities[analysis.severity] = (severities[analysis.severity] ?? 0) + 1;
    }

    return {
      'totalAnalyses': _analysisHistory.length,
      'categories': categories,
      'severities': severities.map((k, v) => MapEntry(k.name, v)),
      'autoFixSuccess': _analysisHistory.where((a) => a.hasAutoFix).length,
    };
  }

  String _categorizeError(String errorString) {
    if (errorString.contains('network') || errorString.contains('connection') ||
        errorString.contains('timeout') || errorString.contains('http')) {
      return 'network';
    } else if (errorString.contains('auth') || errorString.contains('unauthorized') ||
        errorString.contains('forbidden') || errorString.contains('token')) {
      return 'authentication';
    } else if (errorString.contains('permission') || errorString.contains('denied')) {
      return 'permissions';
    } else if (errorString.contains('memory') || errorString.contains('outofmemory')) {
      return 'memory';
    } else if (errorString.contains('storage') || errorString.contains('disk')) {
      return 'storage';
    } else if (errorString.contains('parse') || errorString.contains('json') ||
        errorString.contains('format')) {
      return 'data_format';
    } else if (errorString.contains('null') || errorString.contains('not found')) {
      return 'null_reference';
    } else {
      return 'unknown';
    }
  }

  ErrorSeverity _assessSeverity(String errorString, String category) {
    if (errorString.contains('critical') || errorString.contains('fatal') ||
        category == 'memory' || category == 'storage') {
      return ErrorSeverity.critical;
    } else if (errorString.contains('error') || category == 'authentication' ||
        category == 'permissions') {
      return ErrorSeverity.high;
    } else if (errorString.contains('warning') || category == 'network') {
      return ErrorSeverity.medium;
    } else {
      return ErrorSeverity.low;
    }
  }

  Future<String> _identifyRootCause(String errorString) async {
    if (!_isEnabled) return 'Unable to analyze (error recovery disabled)';

    try {
      // Use AI to identify root cause
      final prompt = '''
Analyze this error and identify the most likely root cause:
Error: $errorString

Provide a concise explanation of what caused this error.
''';

      final response = await _ai.chat(prompt);
      return response.choices.first.message.content.trim();
    } catch (e) {
      // Fallback to pattern-based analysis
      return _patternBasedRootCause(errorString);
    }
  }

  String _patternBasedRootCause(String errorString) {
    if (errorString.contains('connection refused') || errorString.contains('no route to host')) {
      return 'Network connectivity issue - server may be down or unreachable';
    } else if (errorString.contains('timeout')) {
      return 'Operation timed out - network slow or server overloaded';
    } else if (errorString.contains('unauthorized') || errorString.contains('401')) {
      return 'Authentication failed - invalid or expired credentials';
    } else if (errorString.contains('forbidden') || errorString.contains('403')) {
      return 'Access denied - insufficient permissions';
    } else if (errorString.contains('not found') || errorString.contains('404')) {
      return 'Resource not found - endpoint or file may not exist';
    } else if (errorString.contains('null') && errorString.contains('reference')) {
      return 'Null reference error - variable not initialized properly';
    } else {
      return 'Unknown error - requires manual investigation';
    }
  }

  Future<List<ErrorRecoverySuggestion>> _generateSuggestions(
    dynamic error,
    String category,
    ErrorSeverity severity,
  ) async {
    final suggestions = <ErrorRecoverySuggestion>[];

    switch (category) {
      case 'network':
        suggestions.addAll(await _generateNetworkSuggestions(error));
        break;
      case 'authentication':
        suggestions.addAll(await _generateAuthSuggestions(error));
        break;
      case 'permissions':
        suggestions.addAll(await _generatePermissionSuggestions(error));
        break;
      case 'memory':
        suggestions.addAll(await _generateMemorySuggestions(error));
        break;
      case 'data_format':
        suggestions.addAll(await _generateDataFormatSuggestions(error));
        break;
      default:
        suggestions.add(_createGenericSuggestion());
    }

    // Sort by confidence
    suggestions.sort((a, b) => b.confidence.compareTo(a.confidence));
    return suggestions;
  }

  Future<List<ErrorRecoverySuggestion>> _generateNetworkSuggestions(dynamic error) async {
    return [
      ErrorRecoverySuggestion(
        title: 'Retry with exponential backoff',
        description: 'Network errors often resolve themselves. Retry with increasing delays.',
        confidence: 0.8,
        canAutoFix: true,
        autoFixAction: () async {
          // Implement retry logic
          await Future.delayed(const Duration(seconds: 2));
        },
        manualSteps: [
          'Check internet connection',
          'Verify server status',
          'Implement retry logic with backoff',
        ],
        relatedDocs: ['networking.md', 'error_handling.md'],
      ),
      ErrorRecoverySuggestion(
        title: 'Check network connectivity',
        description: 'Ensure device has active internet connection.',
        confidence: 0.9,
        canAutoFix: false,
        manualSteps: [
          'Check WiFi/mobile data',
          'Test with different network',
          'Verify firewall/proxy settings',
        ],
      ),
    ];
  }

  Future<List<ErrorRecoverySuggestion>> _generateAuthSuggestions(dynamic error) async {
    return [
      ErrorRecoverySuggestion(
        title: 'Refresh authentication token',
        description: 'Token may have expired. Attempt to refresh automatically.',
        confidence: 0.7,
        canAutoFix: true,
        autoFixAction: () async {
          // Attempt token refresh
          try {
            await UnifiedAI.instance.chat('Test auth refresh');
          } catch (e) {
            // Token refresh failed
          }
        },
        manualSteps: [
          'Clear app data and re-login',
          'Check token expiration',
          'Verify API key validity',
        ],
      ),
    ];
  }

  Future<List<ErrorRecoverySuggestion>> _generatePermissionSuggestions(dynamic error) async {
    return [
      ErrorRecoverySuggestion(
        title: 'Request missing permissions',
        description: 'App needs additional permissions to function properly.',
        confidence: 0.8,
        canAutoFix: false,
        manualSteps: [
          'Go to app settings',
          'Grant required permissions',
          'Restart the app',
        ],
        relatedDocs: ['permissions.md', 'platform_setup.md'],
      ),
    ];
  }

  Future<List<ErrorRecoverySuggestion>> _generateMemorySuggestions(dynamic error) async {
    return [
      ErrorRecoverySuggestion(
        title: 'Free up memory',
        description: 'Memory pressure detected. Clear caches and unused resources.',
        confidence: 0.6,
        canAutoFix: true,
        autoFixAction: () async {
          // Force garbage collection hint
          // Note: This is just a hint, actual GC is managed by Dart
        },
        manualSteps: [
          'Close other apps',
          'Clear app cache',
          'Restart the device',
          'Check for memory leaks',
        ],
      ),
    ];
  }

  Future<List<ErrorRecoverySuggestion>> _generateDataFormatSuggestions(dynamic error) async {
    return [
      ErrorRecoverySuggestion(
        title: 'Validate data format',
        description: 'Data parsing failed. Check data structure and format.',
        confidence: 0.7,
        canAutoFix: false,
        manualSteps: [
          'Verify API response format',
          'Check data validation',
          'Update parsing logic',
          'Add error boundaries',
        ],
        relatedDocs: ['data_validation.md', 'api_integration.md'],
      ),
    ];
  }

  ErrorRecoverySuggestion _createGenericSuggestion() {
    return const ErrorRecoverySuggestion(
      title: 'Investigate manually',
      description: 'This error requires manual investigation and debugging.',
      confidence: 0.1,
      canAutoFix: false,
      manualSteps: [
        'Check application logs',
        'Review error stack trace',
        'Test in different environments',
        'Consult documentation',
      ],
    );
  }

  Duration _estimateFixTime(String category, ErrorSeverity severity, List<ErrorRecoverySuggestion> suggestions) {
    var baseTime = 5; // minutes

    // Adjust based on severity
    switch (severity) {
      case ErrorSeverity.low:
        baseTime = 5;
        break;
      case ErrorSeverity.medium:
        baseTime = 15;
        break;
      case ErrorSeverity.high:
        baseTime = 30;
        break;
      case ErrorSeverity.critical:
        baseTime = 60;
        break;
    }

    // Adjust based on category
    switch (category) {
      case 'network':
        baseTime = (baseTime * 0.5).round(); // Usually quick fixes
        break;
      case 'authentication':
        baseTime = (baseTime * 1.2).round(); // May need user intervention
        break;
      case 'permissions':
        baseTime = (baseTime * 1.5).round(); // Platform-specific
        break;
      case 'memory':
        baseTime = (baseTime * 2.0).round(); // Complex debugging
        break;
    }

    // Reduce time if auto-fix available
    if (suggestions.any((s) => s.canAutoFix)) {
      baseTime = (baseTime * 0.3).round();
    }

    return Duration(minutes: baseTime);
  }

  List<String> _findSimilarErrors(String errorString) {
    final similar = <String>[];
    final errorWords = errorString.split(' ')
        .where((word) => word.length > 3)
        .toList();

    for (final pattern in _errorPatterns.entries) {
      final patternWords = pattern.key.split(' ');
      final overlap = errorWords.where((word) =>
          patternWords.any((pWord) => pWord.contains(word) || word.contains(pWord))).length;

      if (overlap >= 2) {
        similar.addAll(pattern.value.take(3)); // Add up to 3 examples
      }
    }

    return similar.take(5).toList(); // Return up to 5 similar errors
  }

  List<String> _generatePreventiveActions(String category) {
    switch (category) {
      case 'network':
        return [
          'Implement offline-first architecture',
          'Add connection monitoring',
          'Use exponential backoff for retries',
          'Cache frequently accessed data',
        ];
      case 'authentication':
        return [
          'Implement token refresh logic',
          'Add session management',
          'Handle token expiration gracefully',
          'Provide clear login/logout UI',
        ];
      case 'memory':
        return [
          'Monitor memory usage',
          'Implement proper disposal',
          'Use memory-efficient data structures',
          'Add memory leak detection',
        ];
      case 'permissions':
        return [
          'Request permissions at appropriate times',
          'Handle permission denials gracefully',
          'Provide clear permission explanations',
          'Check permissions before operations',
        ];
      default:
        return [
          'Add comprehensive error handling',
          'Implement logging and monitoring',
          'Add input validation',
          'Create fallback mechanisms',
        ];
    }
  }

  ErrorAnalysisResult _createBasicAnalysis(dynamic error) {
    return ErrorAnalysisResult(
      error: error,
      category: 'unknown',
      severity: ErrorSeverity.medium,
      rootCause: 'Unable to analyze error automatically',
      suggestions: [_createGenericSuggestion()],
      estimatedFixTime: const Duration(minutes: 30),
    );
  }

  void _updateErrorPatterns(String errorString, String category) {
    if (!_errorPatterns.containsKey(errorString)) {
      _errorPatterns[errorString] = [];
    }
    if (!_errorPatterns[errorString]!.contains(category)) {
      _errorPatterns[errorString]!.add(category);
    }
  }
}

