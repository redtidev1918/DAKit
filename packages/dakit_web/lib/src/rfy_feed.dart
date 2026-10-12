import 'package:dakit_core/dakit_core.dart';
import 'package:dio/dio.dart';

import 'web_csrf.dart';
import 'web_deviation_mapper.dart';
import 'web_session_options.dart';

/// Fetches the web `rfy/deviations` personalized recommendation feed.
///
/// The official OAuth API does not expose this stream; it is the private web
/// endpoint behind deviantart.com's home page, authenticated with the embedded
/// WebView's Cookie header and the page's `csrf_token` query parameter.
final class RfyFeedFetcher {
  const RfyFeedFetcher(this._dio);

  final Dio _dio;

  static final Uri _endpoint = Uri.parse(
    'https://www.deviantart.com/_puppy/dabrowse/networkbar/rfy/deviations',
  );

  /// Fetches a page with an optional caller-owned cancellation token.
  ///
  /// Set [retryInvalidCsrf] to false when the host owns session recovery and
  /// physical request tracing. This then performs exactly one RFY request and
  /// never fetches the home page or replaces the supplied CSRF token.
  /// The default retains one refresh retry for an explicit CSRF rejection.
  Future<Page<Artwork>> fetch({
    required String cookieHeader,
    required String csrfToken,
    String? cursor,
    CancelToken? cancelToken,
    bool retryInvalidCsrf = true,
  }) async {
    try {
      return await _fetchOnce(csrfToken, cookieHeader, cursor, cancelToken);
    } on DioException catch (error) {
      // The persisted token can belong to an older browser context after an
      // app update; DeviantArt then answers 400 with `csrf: invalid`. Scrape a
      // fresh token from the home page with the exact Cookie header we send.
      if (!retryInvalidCsrf || !_isInvalidCsrf(error)) rethrow;
      if (cancelToken?.cancelError case final error?) throw error;
      final matchingCsrf = await WebCsrfFetcher(_dio)
          .fetch(cookieHeader: cookieHeader, cancelToken: cancelToken);
      if (matchingCsrf.isEmpty || matchingCsrf == csrfToken) rethrow;
      if (cancelToken?.cancelError case final error?) throw error;
      return await _fetchOnce(matchingCsrf, cookieHeader, cursor, cancelToken);
    }
  }

  static bool _isInvalidCsrf(DioException error) {
    if (error.response?.statusCode != 400) return false;
    final data = error.response?.data;
    if (data is! Map) return false;
    final details = data['errorDetails'];
    return details is Map && details['csrf'] == 'invalid';
  }

  Future<Page<Artwork>> _fetchOnce(
    String csrfToken,
    String cookieHeader,
    String? cursor,
    CancelToken? cancelToken,
  ) async {
    final response = await _dio.get<Object?>(
      _endpoint.toString(),
      queryParameters: <String, dynamic>{
        'csrf_token': csrfToken,
        if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
      },
      options: webSessionOptions(cookieHeader),
      cancelToken: cancelToken,
    );
    return parseJson(response.data);
  }

  /// Parses one `rfy/deviations` response payload into a [Page] of artworks.
  static Page<Artwork> parseJson(Object? data) {
    if (data is! Map) {
      throw const FormatException('Unexpected rfy response shape.');
    }
    final rawDeviations = data['deviations'];
    if (rawDeviations is! List) {
      throw const FormatException('Missing deviations list.');
    }
    final items = <Artwork>[
      for (final raw in rawDeviations)
        if (raw is Map) WebDeviationMapper.mapDeviation(raw),
    ];
    final nextCursor = data['nextCursor'] as String?;
    return Page<Artwork>(
      items: items,
      hasMore: nextCursor != null && nextCursor.isNotEmpty,
      nextCursor: nextCursor,
    );
  }
}
