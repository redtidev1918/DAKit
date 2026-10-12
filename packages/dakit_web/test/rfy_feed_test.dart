import 'dart:async';
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

class _AsyncAdapter implements HttpClientAdapter {
  _AsyncAdapter(this.handler);

  final Future<ResponseBody> Function(RequestOptions options) handler;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) => Future.any([
    handler(options),
    if (cancelFuture != null)
      cancelFuture.then<ResponseBody>(
        (_) => throw DioException(
          requestOptions: options,
          type: DioExceptionType.cancel,
        ),
      ),
  ]);
}

ResponseBody _html(String body) => ResponseBody.fromString(
  body,
  200,
  headers: <String, List<String>>{
    Headers.contentTypeHeader: <String>['text/html'],
  },
);

ResponseBody _json(Object body, {int status = 200}) => ResponseBody.fromBytes(
  utf8.encode(jsonEncode(body)),
  status,
  headers: <String, List<String>>{
    Headers.contentTypeHeader: <String>['application/json'],
  },
);

void main() {
  final cancelled = isA<DioException>().having(
    (error) => error.type,
    'type',
    DioExceptionType.cancel,
  );

  test(
    'single-attempt mode never refreshes an explicitly rejected CSRF',
    () async {
      final paths = <String>[];
      final dio = Dio()
        ..httpClientAdapter = _StubAdapter((options) {
          paths.add(options.uri.path);
          return _json({
            'errorDetails': {'csrf': 'invalid'},
          }, status: 400);
        });
      await expectLater(
        RfyFeedFetcher(dio).fetch(
          cookieHeader: 'auth=fixture',
          csrfToken: 'old',
          retryInvalidCsrf: false,
        ),
        throwsA(isA<DioException>()),
      );
      expect(paths, ['/_puppy/dabrowse/networkbar/rfy/deviations']);
    },
  );

  test('a generic HTTP 400 does not trigger a CSRF refresh', () async {
    var calls = 0;
    final dio = Dio()
      ..httpClientAdapter = _StubAdapter((_) {
        calls++;
        return _json({'error': 'invalid_cursor'}, status: 400);
      });
    await expectLater(
      RfyFeedFetcher(dio).fetch(cookieHeader: 'auth=fixture', csrfToken: 'old'),
      throwsA(isA<DioException>()),
    );
    expect(calls, 1);
  });

  test('cancellation before dispatch makes no physical request', () async {
    var calls = 0;
    final dio = Dio()
      ..httpClientAdapter = _StubAdapter((_) {
        calls++;
        return _json({'deviations': <Object?>[]});
      });
    final token = CancelToken()..cancel('owner superseded');
    await expectLater(
      RfyFeedFetcher(dio).fetch(
        cookieHeader: 'auth=fixture',
        csrfToken: 'old',
        cancelToken: token,
      ),
      throwsA(cancelled),
    );
    expect(calls, 0);
  });

  for (final cancelDuringHome in [false, true]) {
    test(
      'cancellation during ${cancelDuringHome ? 'CSRF refresh' : 'RFY'} stops subsequent requests',
      () async {
        final entered = Completer<void>();
        final pending = Completer<ResponseBody>();
        final paths = <String>[];
        final token = CancelToken();
        final dio = Dio()
          ..httpClientAdapter = _AsyncAdapter((options) {
            paths.add(options.uri.path);
            if (cancelDuringHome && paths.length == 1) {
              return Future.value(
                _json({
                  'errorDetails': {'csrf': 'invalid'},
                }, status: 400),
              );
            }
            entered.complete();
            return pending.future;
          });
        final request = RfyFeedFetcher(dio).fetch(
          cookieHeader: 'auth=fixture',
          csrfToken: 'old',
          cancelToken: token,
          retryInvalidCsrf: cancelDuringHome,
        );
        final result = expectLater(request, throwsA(cancelled));
        await entered.future;
        token.cancel('owner superseded');
        await result;
        pending.complete(_html("window.__CSRF_TOKEN__ = 'fresh-token'"));
        await Future<void>.delayed(Duration.zero);
        expect(paths, [
          '/_puppy/dabrowse/networkbar/rfy/deviations',
          if (cancelDuringHome) '/',
        ]);
      },
    );
  }

  test('retains opaque generic-fallback cursor without session inference', () {
    final cursor = base64Url.encode(
      utf8.encode(jsonEncode({'vespa_content_group': 2})),
    );
    final page = RfyFeedFetcher.parseJson({
      'deviations': <Object?>[],
      'nextCursor': cursor,
    });
    expect(page.nextCursor, cursor);
    expect(page.hasMore, isTrue);
  });
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

  test(
    'refreshes a stale CSRF with the matching cookie session on 400',
    () async {
      var endpointCalls = 0;
      final dio = Dio()
        ..httpClientAdapter = _StubAdapter((options) {
          if (options.uri.host == 'www.deviantart.com' &&
              options.uri.path == '/') {
            return _html(
              "<script>window.__CSRF_TOKEN__ = 'fresh-token'</script>",
            );
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

      final page = await RfyFeedFetcher(
        dio,
      ).fetch(cookieHeader: 'userinfo=abc; csrf=old', csrfToken: 'stale-token');

      expect(page.items.single.title, 'Fresh work');
      expect(endpointCalls, 2);
    },
  );
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
