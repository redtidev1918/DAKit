import 'package:dakit_core/dakit_core.dart';
import 'package:dio/dio.dart';

import 'web_session_options.dart';

/// Fetches a fresh DeviantArt CSRF token from the home page using the exact
/// Cookie header that will accompany the private web request.
///
/// DeviantArt ties each CSRF token to the browser session that rendered the
/// page. A token persisted from an older context (for example after an app
/// update) returns HTTP 400 `csrf: invalid` even when the Cookie header is
/// otherwise valid, so the fix is to scrape the token and the cookies together.
final class WebCsrfFetcher {
  const WebCsrfFetcher(this._dio);

  final Dio _dio;

  static final Uri _home = Uri.parse('https://www.deviantart.com/');
  static final RegExp _csrfPattern = RegExp(
    r"window\.__CSRF_TOKEN__ = '([^']*)'",
  );

  Future<String> fetch({required String cookieHeader}) async {
    final response = await _dio.get<String>(
      _home.toString(),
      options: Options(
        responseType: ResponseType.plain,
        headers: <String, dynamic>{
          'Accept': 'text/html,application/xhtml+xml',
          if (cookieHeader.isNotEmpty) 'Cookie': cookieHeader,
          'User-Agent': webUserAgent,
        },
        validateStatus: (_) => true,
      ),
    );
    final status = response.statusCode ?? 0;
    if (status >= 400) {
      throw DAKitException(
        kind: DAKitFailureKind.upstream,
        code: 'web.home.blocked',
        message: 'DeviantArt rejected the home page (status $status).',
        retryable: true,
      );
    }
    final csrf = _csrfPattern.firstMatch(response.data ?? '')?.group(1);
    if (csrf == null || csrf.isEmpty) {
      throw const DAKitException(
        kind: DAKitFailureKind.upstream,
        code: 'web.csrf.unavailable',
        message: 'Could not read the DeviantArt CSRF token from the home page.',
        retryable: true,
      );
    }
    return csrf;
  }
}
