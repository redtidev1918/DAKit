import 'package:dakit_core/dakit_core.dart';
import 'package:dio/dio.dart';

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

  Future<Page<Artwork>> fetch({
    required String cookieHeader,
    required String csrfToken,
    String? cursor,
  }) async {
    final response = await _dio.get<Object?>(
      _endpoint.toString(),
      queryParameters: <String, dynamic>{
        'csrf_token': csrfToken,
        if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
      },
      options: webSessionOptions(cookieHeader),
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
