// lib/utils/web_utils.dart - Create this new file for web-specific utilities
import 'package:flutter/foundation.dart';

// Conditional import for web-specific functionality
import 'web_utils_stub.dart' if (dart.library.html) 'web_utils_web.dart';

/// Web-safe utility functions
class WebUtils {
  /// Redirect to external URL (web only)
  static void redirectToUrl(String url) {
    if (kIsWeb) {
      redirectToUrlImpl(url);
    } else {
      throw UnsupportedError('URL redirect is only supported on web');
    }
  }
  
  /// Get current URL (web only)
  static String getCurrentUrl() {
    if (kIsWeb) {
      return getCurrentUrlImpl();
    } else {
      return '';
    }
  }
  
  /// Get query parameters from current URL (web only)
  static Map<String, String> getQueryParameters() {
    if (kIsWeb) {
      return getQueryParametersImpl();
    } else {
      return {};
    }
  }
}

// lib/utils/web_utils_stub.dart - Create this stub file
/// Stub implementation for non-web platforms
void redirectToUrlImpl(String url) {
  throw UnsupportedError('URL redirect is only supported on web');
}

String getCurrentUrlImpl() {
  return '';
}

Map<String, String> getQueryParametersImpl() {
  return {};
}

// lib/utils/web_utils_web.dart - Create this web implementation
import 'dart:html' as html;

/// Web implementation of utility functions
void redirectToUrlImpl(String url) {
  html.window.location.href = url;
}

String getCurrentUrlImpl() {
  return html.window.location.href;
}

Map<String, String> getQueryParametersImpl() {
  final uri = Uri.parse(html.window.location.href);
  return uri.queryParameters;
}