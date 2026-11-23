
class SocialUrlUtilities {
  /// Validates if the URL is a valid Twitter / X video URL
  static bool isValidTwitterUrl(String sampleUrl) {
    final clean = sampleUrl.trim().toLowerCase();
    return clean.contains('x.com') || clean.contains('twitter.com');
  }

  /// Normalizes Twitter URL to a consistent format
  /// Example: https://x.com/i/status/2058352870957977860
  static String getTwitterUrl(String sampleUrl) {
    String clean = sampleUrl
        .replaceAll(RegExp(r'[\u200E\u200F\u202A-\u202E\u2028\r]'), '') // Remove RTL & junk
        .trim();

    final uri = Uri.tryParse(clean);
    if (uri == null) return clean;

    // Handle different Twitter share formats
    final path = uri.path.toLowerCase();

    // Extract status ID
    final statusMatch = RegExp(r'/status/(\d+)').firstMatch(path);
    if (statusMatch != null) {
      final statusId = statusMatch.group(1);
      return 'https://x.com/i/status/$statusId';
    }

    // Handle /i/status/ID directly
    if (path.contains('/i/status/')) {
      return 'https://x.com${uri.path}';
    }

    // Fallback: Try to extract numeric status ID from anywhere
    final idMatch = RegExp(r'(\d{15,20})').firstMatch(clean);
    if (idMatch != null) {
      return 'https://x.com/i/status/${idMatch.group(1)}';
    }

    // Last resort - return cleaned original
    return clean.replaceFirst('twitter.com', 'x.com');
  }

  /// Optional: Basic validation for video post
  static bool isLikelyVideoPost(String url) {
    final clean = url.toLowerCase();
    return clean.contains('/status/') && RegExp(r'\d{15,20}').hasMatch(clean);
  }
}