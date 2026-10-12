import 'dart:async';

import 'package:dakit_flutter/dakit_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final failTokenClear in [false, true]) {
    test(
      'logout proceeds past stalled PKCE cleanup; token failure=$failTokenClear',
      () async {
        final tokens = _Tokens(failTokenClear);
        final client = DAKitOAuthClient(
          config: OAuthConfig(
            clientId: 'fixture',
            redirectUri: Uri.parse('dakit://oauth/callback'),
          ),
          tokenStore: tokens,
          pendingStore: _Pending(),
          callbacks: _Callbacks(),
          launcher: _Launcher(),
          endpoint: _Endpoint(),
          recoveryLookupTimeout: const Duration(milliseconds: 10),
        );
        final operation = client
            .logout(revoke: false)
            .timeout(const Duration(seconds: 1));
        if (failTokenClear) {
          await expectLater(operation, throwsA(isA<StateError>()));
        } else {
          await operation;
        }
        expect(tokens.clearCount, 1);
        expect(client.session.generation, 1);
      },
    );
  }
}

final class _Tokens implements TokenStore {
  _Tokens(this.failClear);
  final bool failClear;
  int clearCount = 0;
  @override
  Future<AuthTokens?> read() async => null;
  @override
  Future<void> write(AuthTokens tokens) async {}
  @override
  Future<void> clear() async {
    clearCount++;
    if (failClear) throw StateError('token storage unavailable');
  }
}

final class _Pending implements PendingAuthorizationStore {
  @override
  Future<PendingAuthorization?> read() async => null;
  @override
  Future<void> write(PendingAuthorization pending) async {}
  @override
  Future<void> clear() => Completer<void>().future;
}

final class _Callbacks implements CallbackUriSource {
  @override
  Stream<Uri> get uris => const Stream.empty();
}

final class _Launcher implements ExternalUriLauncher {
  @override
  Future<void> launch(Uri uri) async {}
}

final class _Endpoint implements OAuthEndpoint {
  @override
  Future<Map<String, Object?>> postForm(
    Uri endpoint,
    Map<String, String> form,
  ) async => throw StateError('No request expected');
}
