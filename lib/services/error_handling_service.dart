/// Error Handling Service for global error management
/// 
/// This service provides global error handling, user-friendly error messages,
/// retry mechanisms, and error logging throughout the app.
import 'dart:async';
import '../config/api_config.dart';
import 'network_service.dart';

class ErrorHandlingService {
  static ErrorHandlingService? _instance;
  static ErrorHandlingService get instance => _instance ??= ErrorHandlingService._();
  
  ErrorHandlingService._();
  
  // Error tracking
  final List<AppError> _errorHistory = [];
  final List<AppError> _criticalErrors = [];
  
  // Stream controllers
  final StreamController<AppError> _errorController = StreamController<AppError>.broadcast();
  final StreamController<AppError> _criticalErrorController = StreamController<AppError>.broadcast();
  
  // Configuration
  static const int _maxErrorHistory = 100;
  static const int _maxCriticalErrors = 20;
  static const int _maxRetryAttempts = 3;
  
  /// Get error stream
  Stream<AppError> get errorStream => _errorController.stream;
  
  /// Get critical error stream
  Stream<AppError> get criticalErrorStream => _criticalErrorController.stream;
  
  /// Get error history
  List<AppError> get errorHistory => List.unmodifiable(_errorHistory);
  
  /// Get critical errors
  List<AppError> get criticalErrors => List.unmodifiable(_criticalErrors);
  
  /// Handle error with automatic categorization
  void handleError(
    dynamic error,
    String context, {
    StackTrace? stackTrace,
    Map<String, dynamic>? additionalData,
    bool isCritical = false,
    String? userMessage,
  }) {
    final appError = AppError(
      error: error,
      context: context,
      stackTrace: stackTrace,
      additionalData: additionalData,
      isCritical: isCritical,
      userMessage: userMessage,
      timestamp: DateTime.now(),
    );
    
    // Log error
    ApiConfig.logApiError(context, error);
    
    // Add to history
    _addErrorToHistory(appError);
    
    // Handle critical errors
    if (isCritical) {
      _addCriticalError(appError);
      _criticalErrorController.add(appError);
    }
    
    // Broadcast error
    _errorController.add(appError);
    
    // Log additional data if provided
    if (additionalData != null) {
      ApiConfig.logApiCall('Error additional data', data: additionalData);
    }
  }
  
  /// Handle API error with retry logic
  Future<T?> handleApiError<T>(
    Future<T> Function() operation, {
    String context = 'API Operation',
    int maxRetries = _maxRetryAttempts,
    Duration retryDelay = const Duration(seconds: 1),
    bool exponentialBackoff = true,
    String? userMessage,
  }) async {
    int attempts = 0;
    Duration currentDelay = retryDelay;
    
    while (attempts < maxRetries) {
      try {
        attempts++;
        
        ApiConfig.logApiCall('API operation attempt', data: {
          'context': context,
          'attempt': attempts,
          'max_retries': maxRetries,
        });
        
        final result = await operation();
        
        // Success - log and return
        if (attempts > 1) {
          ApiConfig.logApiCall('API operation succeeded after retry', data: {
            'context': context,
            'attempts': attempts,
          });
        }
        
        return result;
      } catch (error) {
        attempts++;
        
        // Check if we should retry
        if (attempts > maxRetries || !_shouldRetryError(error)) {
          // Final failure - log and throw
          handleError(
            error,
            context,
            userMessage: userMessage ?? 'Operation failed after $attempts attempts',
            isCritical: _isCriticalError(error),
          );
          rethrow;
        }
        
        // Log retry attempt
        ApiConfig.logApiCall('API operation retry', data: {
          'context': context,
          'attempt': attempts,
          'error': error.toString(),
          'retry_delay_ms': currentDelay.inMilliseconds,
        });
        
        // Wait before retry
        await Future.delayed(currentDelay);
        
        // Apply exponential backoff if enabled
        if (exponentialBackoff) {
          currentDelay = Duration(
            milliseconds: (currentDelay.inMilliseconds * 1.5).round(),
          );
        }
      }
    }
    
    // This should never be reached, but just in case
    throw Exception('Unexpected error in retry logic');
  }
  
  /// Handle network error with offline fallback
  Future<T?> handleNetworkError<T>(
    Future<T> Function() onlineOperation, {
    T? offlineFallback,
    Future<T> Function()? offlineOperation,
    String context = 'Network Operation',
    String? userMessage,
  }) async {
    try {
      // Check if we're online
      if (NetworkService.instance.isOnline) {
        return await onlineOperation();
      } else {
        // Offline mode
        if (offlineOperation != null) {
          return await offlineOperation();
        } else if (offlineFallback != null) {
          return offlineFallback;
        } else {
          throw Exception('No offline fallback available');
        }
      }
    } catch (error) {
      handleError(
        error,
        context,
        userMessage: userMessage ?? 'Network operation failed',
        isCritical: _isCriticalError(error),
      );
      rethrow;
    }
  }
  
  /// Get user-friendly error message
  String getUserFriendlyMessage(AppError error) {
    // Use custom user message if provided
    if (error.userMessage != null) {
      return error.userMessage!;
    }
    
    // Generate user-friendly message based on error type
    final errorString = error.error.toString().toLowerCase();
    
    if (errorString.contains('network') || errorString.contains('connection')) {
      return 'Network connection issue. Please check your internet connection and try again.';
    }
    
    if (errorString.contains('timeout')) {
      return 'Request timed out. Please try again.';
    }
    
    if (errorString.contains('unauthorized') || errorString.contains('401')) {
      return 'Authentication required. Please log in again.';
    }
    
    if (errorString.contains('forbidden') || errorString.contains('403')) {
      return 'Access denied. You don\'t have permission to perform this action.';
    }
    
    if (errorString.contains('not found') || errorString.contains('404')) {
      return 'The requested resource was not found.';
    }
    
    if (errorString.contains('server') || errorString.contains('500')) {
      return 'Server error. Please try again later.';
    }
    
    if (errorString.contains('validation')) {
      return 'Invalid data provided. Please check your input and try again.';
    }
    
    // Default message
    return 'An unexpected error occurred. Please try again.';
  }
  
  /// Get error severity level
  ErrorSeverity getErrorSeverity(AppError error) {
    if (error.isCritical) return ErrorSeverity.critical;
    
    final errorString = error.error.toString().toLowerCase();
    
    if (errorString.contains('network') || errorString.contains('connection')) {
      return ErrorSeverity.warning;
    }
    
    if (errorString.contains('timeout')) {
      return ErrorSeverity.warning;
    }
    
    if (errorString.contains('unauthorized') || errorString.contains('401')) {
      return ErrorSeverity.error;
    }
    
    if (errorString.contains('forbidden') || errorString.contains('403')) {
      return ErrorSeverity.error;
    }
    
    if (errorString.contains('not found') || errorString.contains('404')) {
      return ErrorSeverity.info;
    }
    
    if (errorString.contains('server') || errorString.contains('500')) {
      return ErrorSeverity.error;
    }
    
    if (errorString.contains('validation')) {
      return ErrorSeverity.warning;
    }
    
    return ErrorSeverity.info;
  }
  
  /// Get error statistics
  ErrorStatistics getErrorStatistics() {
    final totalErrors = _errorHistory.length;
    final criticalErrors = _errorHistory.where((e) => e.isCritical).length;
    final networkErrors = _errorHistory.where((e) => 
      e.error.toString().toLowerCase().contains('network') ||
      e.error.toString().toLowerCase().contains('connection')
    ).length;
    final apiErrors = _errorHistory.where((e) => 
      e.error.toString().toLowerCase().contains('api') ||
      e.error.toString().toLowerCase().contains('http')
    ).length;
    
    // Calculate error rate (errors per hour)
    double errorRate = 0;
    if (_errorHistory.isNotEmpty) {
      final firstError = _errorHistory.first.timestamp;
      final lastError = _errorHistory.last.timestamp;
      final timeSpan = lastError.difference(firstError).inHours;
      if (timeSpan > 0) {
        errorRate = totalErrors / timeSpan;
      }
    }
    
    return ErrorStatistics(
      totalErrors: totalErrors,
      criticalErrors: criticalErrors,
      networkErrors: networkErrors,
      apiErrors: apiErrors,
      errorRate: errorRate,
      lastErrorTime: _errorHistory.isNotEmpty ? _errorHistory.last.timestamp : null,
    );
  }
  
  /// Clear error history
  void clearErrorHistory() {
    _errorHistory.clear();
    ApiConfig.logApiCall('Error history cleared');
  }
  
  /// Clear critical errors
  void clearCriticalErrors() {
    _criticalErrors.clear();
    ApiConfig.logApiCall('Critical errors cleared');
  }
  
  /// Check if error should be retried
  bool _shouldRetryError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    
    // Don't retry authentication errors
    if (errorString.contains('unauthorized') || errorString.contains('401')) {
      return false;
    }
    
    // Don't retry permission errors
    if (errorString.contains('forbidden') || errorString.contains('403')) {
      return false;
    }
    
    // Don't retry validation errors
    if (errorString.contains('validation')) {
      return false;
    }
    
    // Don't retry not found errors
    if (errorString.contains('not found') || errorString.contains('404')) {
      return false;
    }
    
    // Retry network, timeout, and server errors
    return errorString.contains('network') ||
           errorString.contains('connection') ||
           errorString.contains('timeout') ||
           errorString.contains('server') ||
           errorString.contains('500');
  }
  
  /// Check if error is critical
  bool _isCriticalError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    
    // Authentication errors are critical
    if (errorString.contains('unauthorized') || errorString.contains('401')) {
      return true;
    }
    
    // Database errors are critical
    if (errorString.contains('database') || errorString.contains('sql')) {
      return true;
    }
    
    // File system errors are critical
    if (errorString.contains('file') || errorString.contains('storage')) {
      return true;
    }
    
    // Memory errors are critical
    if (errorString.contains('memory') || errorString.contains('out of memory')) {
      return true;
    }
    
    return false;
  }
  
  /// Add error to history
  void _addErrorToHistory(AppError error) {
    _errorHistory.add(error);
    
    // Keep only recent errors
    if (_errorHistory.length > _maxErrorHistory) {
      _errorHistory.removeAt(0);
    }
  }
  
  /// Add critical error
  void _addCriticalError(AppError error) {
    _criticalErrors.add(error);
    
    // Keep only recent critical errors
    if (_criticalErrors.length > _maxCriticalErrors) {
      _criticalErrors.removeAt(0);
    }
  }
  
  /// Dispose resources
  void dispose() {
    _errorController.close();
    _criticalErrorController.close();
  }
}

/// App Error class
class AppError {
  final dynamic error;
  final String context;
  final StackTrace? stackTrace;
  final Map<String, dynamic>? additionalData;
  final bool isCritical;
  final String? userMessage;
  final DateTime timestamp;
  
  AppError({
    required this.error,
    required this.context,
    this.stackTrace,
    this.additionalData,
    this.isCritical = false,
    this.userMessage,
    required this.timestamp,
  });
  
  /// Get error type
  String get errorType {
    return error.runtimeType.toString();
  }
  
  /// Get error message
  String get errorMessage {
    return error.toString();
  }
  
  /// Get time since error
  String get timeSinceError {
    final timeDiff = DateTime.now().difference(timestamp);
    if (timeDiff.inDays > 0) {
      return '${timeDiff.inDays}d ago';
    } else if (timeDiff.inHours > 0) {
      return '${timeDiff.inHours}h ago';
    } else if (timeDiff.inMinutes > 0) {
      return '${timeDiff.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
  
  /// Get formatted timestamp
  String get formattedTimestamp {
    return '${timestamp.day}/${timestamp.month}/${timestamp.year} ${timestamp.hour}:${timestamp.minute}';
  }
  
  @override
  String toString() {
    return 'AppError(context: $context, error: $error, isCritical: $isCritical)';
  }
}

/// Error severity enum
enum ErrorSeverity {
  info,
  warning,
  error,
  critical,
}

/// Error statistics
class ErrorStatistics {
  final int totalErrors;
  final int criticalErrors;
  final int networkErrors;
  final int apiErrors;
  final double errorRate;
  final DateTime? lastErrorTime;
  
  ErrorStatistics({
    required this.totalErrors,
    required this.criticalErrors,
    required this.networkErrors,
    required this.apiErrors,
    required this.errorRate,
    this.lastErrorTime,
  });
  
  /// Get error rate description
  String get errorRateDescription {
    if (errorRate < 1) return 'Low (< 1 per hour)';
    if (errorRate < 5) return 'Moderate (1-5 per hour)';
    if (errorRate < 10) return 'High (5-10 per hour)';
    return 'Very High (> 10 per hour)';
  }
  
  /// Get time since last error
  String get timeSinceLastError {
    if (lastErrorTime == null) return 'Never';
    
    final timeDiff = DateTime.now().difference(lastErrorTime!);
    if (timeDiff.inDays > 0) {
      return '${timeDiff.inDays}d ago';
    } else if (timeDiff.inHours > 0) {
      return '${timeDiff.inHours}h ago';
    } else if (timeDiff.inMinutes > 0) {
      return '${timeDiff.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
  
  /// Check if error rate is concerning
  bool get isErrorRateConcerning {
    return errorRate > 5; // More than 5 errors per hour
  }
  
  /// Check if critical errors are frequent
  bool get areCriticalErrorsFrequent {
    return criticalErrors > 5; // More than 5 critical errors
  }
} 