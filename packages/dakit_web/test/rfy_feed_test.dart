import 'dart:convert';
import 'dart:typed_data';

import 'package:dakit_web/dakit_web.dart';
import 'package:dio/dio.dart';
import 'package:test/test.dart';

class _StubAdapter implements HttpClientAdapter {
  _StubAdapter(this._handler);

  final ResponseBody Function(RequestOptions options) _handler;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => _handler(options);
}

ResponseBody _html(String body) => ResponseBody.fromString(
  body,
  200,
  headers: <String, List<String>>{
    Headers.contentTypeHeader: <String>['text/html'],
  },
);

ResponseBody _json(Object body, {int status = 200}) =>
    ResponseBody.fromBytes(
      utf8.encode(jsonEncode(body)),
      status,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>['application/json'],
      },
    );

void main() {
  test('parses a personalized rfy/deviations payload', () {
    final page = RfyFeedFetcher.parseJson(<String, Object?>{
      'nextCursor': 'abc123',
      'deviations': <Object?>[_deviation(10, 'Work 10')],
    });

    expect(page.hasMore, isTrue);
    expect(page.nextCursor, 'abc123');
    expect(page.items.map((artwork) => artwork.id), <String>['10']);
    expect(page.items.first.title, 'Work 10');
    expect(page.items.first.author.username, 'ArtistOne');
    expect(page.items.first.media, isNotEmpty);
  });

  test('hasMore is false when nextCursor is absent', () {
    final page = RfyFeedFetcher.parseJson(<String, Object?>{
      'deviations': <Object?>[_deviation(20, 'Work 20')],
    });

    expect(page.hasMore, isFalse);
    expect(page.nextCursor, isNull);
  });

  test('throws FormatException when deviations are missing', () {
    expect(
      () => RfyFeedFetcher.parseJson(<String, Object?>{'nextCursor': 'x'}),
      throwsFormatException,
    );
  });

  test('uses the update time for feed ordering when present', () {
    final page = RfyFeedFetcher.parseJson(<String, Object?>{
      'deviations': <Object?>[
        <String, Object?>{
          ..._deviation(30, 'Edited work'),
          'publishedTime': '2026-08-01T10:00:00-0700',
          'updatedTime': '2026-08-25T15:30:00-0700',
        },
      ],
    });

    // The model's single timestamp carries the latest activity time so feed
    // ordering reflects edits; the init payload still exposes both dates to
    // the detail page.
    expect(
      page.items.single.publishedAt?.toUtc(),
      DateTime.parse('2026-08-25T22:30:00Z'),
    );
  });

  test('falls back to publish time when no update time exists', () {
    final page = RfyFeedFetcher.parseJson(<String, Object?>{
      'deviations': <Object?>[_deviation(40, 'Fresh work')],
    });

    expect(
      page.items.single.publishedAt?.toUtc(),
      DateTime.parse('2026-08-20T19:00:00Z'),
    );
  });

  test('refreshes a stale CSRF with the matching cookie session on 400', () async {
    var endpointCalls = 0;
    final dio = Dio()..httpClientAdapter = _StubAdapter((options) {
      if (options.uri.host == 'www.deviantart.com' &&
          options.uri.path == '/') {
        return _html("<script>window.__CSRF_TOKEN__ = 'fresh-token'</script>");
      }
      endpointCalls += 1;
      if (endpointCalls == 1) {
        return _json(<String, Object?>{
          'error': 'invalid_request',
          'errorDetails': <String, Object?>{'csrf': 'invalid'},
          'status': 'error',
        }, status: 400);
      }
      return _json(<String, Object?>{
        'hasMore': true,
        'nextCursor': 'abc123',
        'deviations': <Object?>[_deviation(9, 'Fresh work')],
      });
    });

    final page = await RfyFeedFetcher(dio).fetch(
      cookieHeader: 'userinfo=abc; csrf=old',
      csrfToken: 'stale-token',
    );

    expect(page.items.single.title, 'Fresh work');
    expect(endpointCalls, 2);
  });
}

Map<String, Object?> _deviation(int id, String title) => <String, Object?>{
  'deviationId': id,
  'title': title,
  'type': 'image',
  'url': 'https://www.deviantart.com/artistone/art/work-$id',
  'author': <String, Object?>{
    'userId': 1,
    'username': 'ArtistOne',
    'usericon': 'https://a.deviantart.net/avatar.png',
  },
  'publishedTime': '2026-08-20T12:00:00-0700',
  'isMature': false,
  'isDownloadable': false,
  'isFavourited': false,
  'isMultiMedia': false,
  'media': <String, Object?>{
    'baseUri': 'https://images.example.test/work-$id.jpg',
    'prettyName': 'work_$id',
    'token': <String>[],
    'types': <Object?>[
      <String, Object?>{
        't': '300W',
        'c': '/v1/fit/w_300,h_300/work-$id.jpg',
        'w': 300,
        'h': 200,
      },
    ],
  },
};
