import 'dart:async';

import 'package:dakit_api/dakit_api.dart';
import 'package:dakit_core/dakit_core.dart';
import 'package:test/test.dart';

void main() {
  final now = DateTime.utc(2026, 8, 20, 12);
  final config = OAuthConfig(
    clientId: '12345',
    redirectUri: Uri.parse('dakit://oauth/callback'),
  );

  AuthTokens token(String name, {bool expired = false}) => AuthTokens(
    accessToken: name,
    tokenType: 'Bearer',
    refreshToken: 'fixture-refresh',
    expiresAt: now.add(
      expired ? const Duration(hours: -1) : const Duration(hours: 1),
    ),
  );
  final storageTimeout = isA<DAKitException>()
      .having((e) => e.kind, 'kind', DAKitFailureKind.storage)
      .having((e) => e.code, 'code', 'oauth.storage.timeout');
  final changedSession = isA<DAKitException>().having(
    (e) => e.code,
    'code',
    'oauth.session.changed',
  );
  OAuthSession controlledSession(
    ControlledTokenStore store, {
    OAuthEndpoint? endpoint,
  }) => OAuthSession(
    config: config,
    store: store,
    tokenClient: OAuthTokenClient(
      endpoint: endpoint ?? FakeOAuthEndpoint([]),
      now: () => now,
    ),
    now: () => now,
    storeOperationTimeout: const Duration(milliseconds: 50),
  );

  test('issued save, logout and next save retain the new account', () async {
    final store = ControlledTokenStore(null)..writeGate = Completer<void>();
    final session = controlledSession(store);
    final oldSave = session.save(token('A'), expectedGeneration: 0);
    final oldResult = expectLater(oldSave, throwsA(changedSession));
    await store.writeStarted.future;
    final loggingOut = session.logout(revoke: false);
    expect(session.generation, 1);
    store.writeGate!.complete();
    await oldResult;
    await loggingOut;
    await session.save(token('B'), expectedGeneration: 1);
    expect(store.value?.accessToken, 'B');
    expect(store.events, ['write:A', 'clear', 'clear', 'write:B']);
  });

  test(
    'timed-out native write cannot overwrite or clear a newer account',
    () async {
      final store = ControlledTokenStore(null)..writeGate = Completer<void>();
      final session = controlledSession(store);
      final oldResult = expectLater(
        session.save(token('A')),
        throwsA(storageTimeout),
      );
      await store.writeStarted.future;
      await expectLater(session.logout(revoke: false), throwsA(storageTimeout));
      await oldResult;
      final newSave = session.save(token('B'), expectedGeneration: 1);
      store.writeGate!.complete();
      await newSave;
      expect(store.value?.accessToken, 'B');
      expect(store.events, ['write:A', 'clear', 'clear', 'write:B']);
    },
  );

  test('timed-out native logout clear stays ahead of a new save', () async {
    final store = ControlledTokenStore(token('A'))
      ..clearGate = Completer<void>();
    final session = controlledSession(store);
    await expectLater(session.logout(revoke: false), throwsA(storageTimeout));
    final newSave = session.save(token('B'));
    store.clearGate!.complete();
    await newSave;
    expect(store.value?.accessToken, 'B');
    expect(store.events, ['clear', 'write:B']);
  });

  test(
    'a timed-out queued save is skipped when native storage resumes',
    () async {
      final store = ControlledTokenStore(null)..writeGate = Completer<void>();
      final session = controlledSession(store);
      final first = expectLater(
        session.save(token('A')),
        throwsA(storageTimeout),
      );
      await store.writeStarted.future;
      await expectLater(session.save(token('B')), throwsA(storageTimeout));
      await first;
      store.writeGate!.complete();
      await session.save(token('C'));
      expect(store.value?.accessToken, 'C');
      expect(store.events, ['write:A', 'write:C']);
    },
  );

  test(
    'same-generation late save retains valid credentials after caller timeout',
    () async {
      final store = ControlledTokenStore(token('old'))
        ..writeGate = Completer<void>();
      final session = controlledSession(store);
      await expectLater(session.save(token('new')), throwsA(storageTimeout));
      store.writeGate!.complete();
      expect((await session.validTokens()).accessToken, 'new');
      expect(store.events, ['write:new']);
      expect(session.generation, 0);
    },
  );

  test('same-generation late refresh retains the rotated token after caller timeout', () async {
    final store = ControlledTokenStore(token('old', expired: true))
      ..writeGate = Completer<void>();
    final session = controlledSession(
      store,
      endpoint: FakeOAuthEndpoint([
        {
          'access_token': 'rotated',
          'token_type': 'Bearer',
          'refresh_token': 'rotated-refresh',
          'expires_in': 3600,
        },
      ]),
    );
    await expectLater(session.validTokens(), throwsA(storageTimeout));
    store.writeGate!.complete();
    final retained = await session.validTokens();
    expect(retained.accessToken, 'rotated');
    expect(retained.refreshToken, 'rotated-refresh');
    expect(store.events, ['write:rotated']);
    expect(session.generation, 0);
  });

  test(
    'validTokens waits for a mutation and cannot read its stale predecessor',
    () async {
      final store = ControlledTokenStore(token('old'))
        ..writeGate = Completer<void>();
      final session = controlledSession(store);
      final saving = session.save(token('new'));
      await store.writeStarted.future;
      final reading = session.validTokens();
      store.writeGate!.complete();
      await saving;
      expect((await reading).accessToken, 'new');
    },
  );

  test(
    'hung native read is storage failure without deleting credentials',
    () async {
      final store = ControlledTokenStore(token('existing'))
        ..readGate = Completer<void>();
      final session = controlledSession(store);
      await expectLater(session.validTokens(), throwsA(storageTimeout));
      expect(store.value?.accessToken, 'existing');
      expect(store.events, isEmpty);
      store.readGate!.complete();
      expect((await session.validTokens()).accessToken, 'existing');
    },
  );

  test(
    'storage write failure does not poison subsequent transactions',
    () async {
      final store = ControlledTokenStore(null)..failNextWrite = true;
      final session = controlledSession(store);
      await expectLater(session.save(token('failed')), throwsStateError);
      await session.save(token('replacement'));
      expect((await session.validTokens()).accessToken, 'replacement');
    },
  );

  test(
    'logout during issued refresh write does not deadlock or clear next login',
    () async {
      final store = ControlledTokenStore(token('old', expired: true))
        ..writeGate = Completer<void>();
      final session = controlledSession(
        store,
        endpoint: FakeOAuthEndpoint([
          {
            'access_token': 'refreshed',
            'token_type': 'Bearer',
            'expires_in': 3600,
          },
        ]),
      );
      final refreshing = expectLater(
        session.validTokens(),
        throwsA(changedSession),
      );
      await store.writeStarted.future;
      final loggingOut = session.logout(revoke: false);
      store.writeGate!.complete();
      await refreshing;
      await loggingOut;
      await session.save(token('replacement'));
      expect(store.value?.accessToken, 'replacement');
      expect(store.events, [
        'write:refreshed',
        'clear',
        'clear',
        'write:replacement',
      ]);
    },
  );

  test('public code exchange sends PKCE and no client secret', () async {
    final endpoint = FakeOAuthEndpoint(<Map<String, Object?>>[
      <String, Object?>{
        'access_token': 'access',
        'token_type': 'Bearer',
        'refresh_token': 'refresh',
        'expires_in': 3600,
        'scope': 'basic browse',
      },
    ]);
    final flow = PkceFlow();
    final pending = flow.start(config, now: now);
    final tokens = await OAuthTokenClient(endpoint: endpoint, now: () => now)
        .exchangeCode(
          config: config,
          pending: pending,
          callback: const AuthorizationCallback(code: 'authorization-code'),
        );

    expect(tokens.accessToken, 'access');
    expect(tokens.expiresAt, now.add(const Duration(hours: 1)));
    expect(endpoint.forms.single['code_verifier'], pending.codeVerifier);
    expect(endpoint.forms.single, isNot(contains('client_secret')));
  });

  test('concurrent expired-session reads share one refresh request', () async {
    final endpoint = FakeOAuthEndpoint(<Map<String, Object?>>[
      <String, Object?>{
        'access_token': 'new-access',
        'token_type': 'Bearer',
        'expires_in': 3600,
        'scope': 'basic',
      },
    ], delay: const Duration(milliseconds: 10));
    final store = MemoryTokenStore(
      AuthTokens(
        accessToken: 'old-access',
        tokenType: 'Bearer',
        refreshToken: 'old-refresh',
        expiresAt: now.subtract(const Duration(minutes: 1)),
      ),
    );
    final session = OAuthSession(
      config: config,
      store: store,
      tokenClient: OAuthTokenClient(endpoint: endpoint, now: () => now),
      now: () => now,
    );

    final results = await Future.wait(<Future<AuthTokens>>[
      session.validTokens(),
      session.validTokens(),
      session.validTokens(),
    ]);

    expect(endpoint.forms, hasLength(1));
    expect(results.map((tokens) => tokens.accessToken).toSet(), <String>{
      'new-access',
    });
    expect(results.first.refreshToken, 'old-refresh');
    expect(store.value?.accessToken, 'new-access');
  });

  test('refresh preserves scopes when the provider omits scope', () async {
    final endpoint = FakeOAuthEndpoint(<Map<String, Object?>>[
      <String, Object?>{
        'access_token': 'new-access',
        'token_type': 'Bearer',
        'expires_in': 3600,
      },
    ]);
    final store = MemoryTokenStore(
      AuthTokens(
        accessToken: 'old-access',
        tokenType: 'Bearer',
        refreshToken: 'old-refresh',
        expiresAt: now.subtract(const Duration(minutes: 1)),
        scopes: const <String>{'basic', 'browse', 'user'},
      ),
    );
    final session = OAuthSession(
      config: config,
      store: store,
      tokenClient: OAuthTokenClient(endpoint: endpoint, now: () => now),
      now: () => now,
    );

    final refreshed = await session.validTokens();

    expect(refreshed.scopes, const <String>{'basic', 'browse', 'user'});
  });

  test('invalid refresh clears tokens and notifies the host', () async {
    final store = MemoryTokenStore(
      AuthTokens(
        accessToken: 'old-access',
        tokenType: 'Bearer',
        refreshToken: 'invalid-refresh',
        expiresAt: now.subtract(const Duration(minutes: 1)),
      ),
    );
    final session = OAuthSession(
      config: config,
      store: store,
      tokenClient: OAuthTokenClient(
        endpoint: InvalidRefreshEndpoint(),
        now: () => now,
      ),
      now: () => now,
    );
    final invalidation = session.invalidations.first;

    await expectLater(
      session.validTokens(),
      throwsA(
        isA<DAKitException>().having(
          (error) => error.code,
          'code',
          'oauth.refresh.invalid',
        ),
      ),
    );

    expect((await invalidation).code, 'oauth.refresh.invalid');
    expect(store.value, isNull);
    expect(session.generation, 1);
    await expectLater(
      session.validTokens(),
      throwsA(
        isA<DAKitException>().having(
          (error) => error.code,
          'code',
          'oauth.session.missing',
        ),
      ),
    );
  });

  test('logout cannot be undone by an in-flight refresh', () async {
    final endpoint = ControlledOAuthEndpoint();
    final store = MemoryTokenStore(
      AuthTokens(
        accessToken: 'old-access',
        tokenType: 'Bearer',
        refreshToken: 'old-refresh',
        expiresAt: now.subtract(const Duration(minutes: 1)),
        scopes: const <String>{'basic', 'browse'},
      ),
    );
    final session = OAuthSession(
      config: config,
      store: store,
      tokenClient: OAuthTokenClient(endpoint: endpoint, now: () => now),
      now: () => now,
    );

    final refresh = session.validTokens();
    await endpoint.refreshStarted.future;
    final logout = session.logout();
    endpoint.releaseRefresh.complete();

    await expectLater(
      refresh,
      throwsA(
        isA<DAKitException>().having(
          (error) => error.code,
          'code',
          'oauth.session.changed',
        ),
      ),
    );
    await logout;

    expect(store.value, isNull);
    expect(endpoint.forms, hasLength(2));
    expect(endpoint.forms.last['token'], 'old-refresh');
  });

  test(
    'a token exchange started before logout cannot restore a session',
    () async {
      final endpoint = FakeOAuthEndpoint(const <Map<String, Object?>>[]);
      final store = MemoryTokenStore(null);
      final session = OAuthSession(
        config: config,
        store: store,
        tokenClient: OAuthTokenClient(endpoint: endpoint, now: () => now),
        now: () => now,
      );
      final generation = session.generation;

      await session.logout(revoke: false);

      await expectLater(
        session.save(
          AuthTokens(
            accessToken: 'late-access',
            tokenType: 'Bearer',
            expiresAt: now.add(const Duration(hours: 1)),
          ),
          expectedGeneration: generation,
        ),
        throwsA(
          isA<DAKitException>().having(
            (error) => error.code,
            'code',
            'oauth.session.changed',
          ),
        ),
      );
      expect(store.value, isNull);
    },
  );

  test('logout clears local tokens after successful revocation', () async {
    final endpoint = FakeOAuthEndpoint(<Map<String, Object?>>[
      <String, Object?>{'success': true},
    ]);
    final store = MemoryTokenStore(
      AuthTokens(
        accessToken: 'access',
        tokenType: 'Bearer',
        refreshToken: 'refresh',
        expiresAt: now.add(const Duration(hours: 1)),
      ),
    );
    final session = OAuthSession(
      config: config,
      store: store,
      tokenClient: OAuthTokenClient(endpoint: endpoint, now: () => now),
      now: () => now,
    );

    await session.logout();

    expect(store.value, isNull);
    expect(endpoint.forms.single['token'], 'refresh');
    expect(endpoint.forms.single['revoke_refresh_only'], 'true');
  });

  test('failed token deletion cannot poison the next authorization', () async {
    final store = FailingClearTokenStore(
      AuthTokens(
        accessToken: 'old-access',
        tokenType: 'Bearer',
        expiresAt: now.add(const Duration(hours: 1)),
      ),
    );
    final session = OAuthSession(
      config: config,
      store: store,
      tokenClient: OAuthTokenClient(
        endpoint: FakeOAuthEndpoint(const <Map<String, Object?>>[]),
        now: () => now,
      ),
      now: () => now,
    );

    await expectLater(session.logout(revoke: false), throwsStateError);
    final replacement = AuthTokens(
      accessToken: 'replacement',
      tokenType: 'Bearer',
      expiresAt: now.add(const Duration(hours: 2)),
    );
    await session.save(replacement);

    expect(store.value?.accessToken, 'replacement');
    expect((await session.validTokens()).accessToken, 'replacement');
  });
}

final class FakeOAuthEndpoint implements OAuthEndpoint {
  FakeOAuthEndpoint(this.responses, {this.delay = Duration.zero});

  final List<Map<String, Object?>> responses;
  final Duration delay;
  final List<Map<String, String>> forms = <Map<String, String>>[];

  @override
  Future<Map<String, Object?>> postForm(
    Uri endpoint,
    Map<String, String> form,
  ) async {
    forms.add(Map<String, String>.unmodifiable(form));
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    return responses.removeAt(0);
  }
}

final class ControlledOAuthEndpoint implements OAuthEndpoint {
  final Completer<void> refreshStarted = Completer<void>();
  final Completer<void> releaseRefresh = Completer<void>();
  final List<Map<String, String>> forms = <Map<String, String>>[];

  @override
  Future<Map<String, Object?>> postForm(
    Uri endpoint,
    Map<String, String> form,
  ) async {
    forms.add(Map<String, String>.unmodifiable(form));
    if (form['grant_type'] == 'refresh_token') {
      refreshStarted.complete();
      await releaseRefresh.future;
      return <String, Object?>{
        'access_token': 'new-access',
        'token_type': 'Bearer',
        'expires_in': 3600,
      };
    }
    return <String, Object?>{'success': true};
  }
}

final class InvalidRefreshEndpoint implements OAuthEndpoint {
  @override
  Future<Map<String, Object?>> postForm(
    Uri endpoint,
    Map<String, String> form,
  ) => throw const DAKitException(
    kind: DAKitFailureKind.authentication,
    code: 'oauth.refresh.invalid',
    message: 'The refresh token is invalid.',
  );
}

final class MemoryTokenStore implements TokenStore {
  MemoryTokenStore(this.value);

  AuthTokens? value;

  @override
  Future<void> clear() async => value = null;

  @override
  Future<AuthTokens?> read() async => value;

  @override
  Future<void> write(AuthTokens tokens) async => value = tokens;
}

final class FailingClearTokenStore extends MemoryTokenStore {
  FailingClearTokenStore(super.value);

  @override
  Future<void> clear() => throw StateError('keychain denied deletion');
}

final class ControlledTokenStore extends MemoryTokenStore {
  ControlledTokenStore(super.value);
  Completer<void>? writeGate;
  Completer<void>? clearGate;
  Completer<void>? readGate;
  final writeStarted = Completer<void>();
  final events = <String>[];
  bool failNextWrite = false;

  @override
  Future<AuthTokens?> read() async {
    await readGate?.future;
    return value;
  }

  @override
  Future<void> write(AuthTokens tokens) async {
    if (!writeStarted.isCompleted) writeStarted.complete();
    await writeGate?.future;
    if (failNextWrite) {
      failNextWrite = false;
      throw StateError('synthetic write failure');
    }
    value = tokens;
    events.add('write:${tokens.accessToken}');
  }

  @override
  Future<void> clear() async {
    await clearGate?.future;
    value = null;
    events.add('clear');
  }
}
