import 'package:dakit_api/dakit_api.dart';
import 'package:test/test.dart';

void main() {
  const redactor = Redactor();

  test('redacts sensitive fields case-insensitively', () {
    final result = redactor.fields(<String, Object?>{
      'Authorization': 'Bearer secret',
      'refresh_token': 'secret',
      'status': 200,
    });

    expect(result['Authorization'], '<redacted>');
    expect(result['refresh_token'], '<redacted>');
    expect(result['status'], 200);
  });

  test('redacts authorization callback query values', () {
    final result = redactor.uri(
      Uri.parse('dakit://oauth/callback?code=secret&state=public-state'),
    );

    expect(result.queryParameters['code'], '<redacted>');
    expect(result.queryParameters['state'], '<redacted>');
  });

  for (final depth in [0, 1, 2]) {
    test('redacts nested query assignments at encoding depth $depth', () {
      var inner =
          'https://example.test/auth?keep=one&StAtE=nonce-fixture&code=code-fixture&access_token=access-fixture&refresh_token=refresh-fixture&client_secret=client-fixture&cookie=cookie-fixture&code_verifier=verifier-fixture&tail=two';
      for (var i = 0; i < depth; i++) {
        inner = Uri.encodeComponent(inner);
      }
      final redacted = redactor.text('navigation referer=$inner status=200');
      for (final secret in [
        'nonce',
        'code',
        'access',
        'refresh',
        'client',
        'cookie',
        'verifier',
      ]) {
        expect(redacted, isNot(contains('$secret-fixture')));
      }
      var restored = redacted.substring(
        'navigation referer='.length,
        redacted.indexOf(' status='),
      );
      for (var i = 0; i < depth; i++) {
        restored = Uri.decodeComponent(restored);
      }
      final parsed = Uri.parse(restored);
      expect(parsed.queryParameters['keep'], 'one');
      expect(parsed.queryParameters['tail'], 'two');
      expect(parsed.queryParameters['StAtE'], '<redacted>');
      expect(redacted, endsWith(' status=200'));
    });
  }

  test(
    'URI redaction preserves nested URLs and repeated ordinary parameters',
    () {
      final result = redactor.uri(
        Uri.parse(
          'https://example.test/?tag=a&tag=b&referer=https%3A%2F%2Fexample.test%2Fauth%3Fstate%3Dnonce-fixture%26next%3Dok',
        ),
      );
      expect(result.queryParametersAll['tag'], ['a', 'b']);
      final nested = Uri.parse(result.queryParameters['referer']!);
      expect(nested.queryParameters['state'], '<redacted>');
      expect(nested.queryParameters['next'], 'ok');
      expect(result.toString(), isNot(contains('nonce-fixture')));
    },
  );

  test(
    'redacts encoded string fields while retaining malformed percent text',
    () {
      final result = redactor.fields({
        'referer': 'return%26STATE%3dnonce-fixture%26keep%3Dok',
        'detail': 'bad escape %zz',
      });
      expect(result['referer'], 'return%26STATE%3d%3Credacted%3E%26keep%3Dok');
      expect(result['detail'], 'bad escape %zz');
    },
  );

  test('encoded cookie assignments redact the entire multi-cookie value', () {
    final result = redactor.text(
      'referer=return%26COOKIE%3Dauth%3Dfirst-secret%3Bauth_secure%3Dsecond-secret%26keep%3Dok',
    );
    expect(result, isNot(contains('first-secret')));
    expect(result, isNot(contains('second-secret')));
    expect(result, endsWith('%26keep%3Dok'));
  });
}
