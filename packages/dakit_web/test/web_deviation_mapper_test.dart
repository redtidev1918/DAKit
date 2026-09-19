import 'package:dakit_core/dakit_core.dart';
import 'package:dakit_web/dakit_web.dart';
import 'package:test/test.dart';

void main() {
  test('maps ids, author, media, and timestamp from a website deviation', () {
    final artwork = WebDeviationMapper.mapDeviation(<String, Object?>{
      'deviationId': 819241297,
      'title': 'Work',
      'url': 'https://www.deviantart.com/artist/art/Work-819241297',
      'author': <String, Object?>{
        'userId': 42,
        'username': 'ArtistOne',
        'usericon': 'https://img.example.test/icon.png',
      },
      'media': <String, Object?>{
        'baseUri': 'https://img.example.test/artwork.jpg',
        'prettyName': 'artwork',
        'token': <String>['tok'],
        'types': <Object?>[
          <String, Object?>{
            't': 'fullview',
            'c': 'v1/fill/w_1280/<prettyName>',
            'w': 1280,
            'r': 0,
          },
        ],
      },
      'publishedTime': '2026-08-01T10:00:00-0700',
      'isDownloadable': true,
    });

    expect(artwork.id, '819241297');
    expect(artwork.title, 'Work');
    expect(artwork.author.username, 'ArtistOne');
    expect(artwork.pageUri.host, 'www.deviantart.com');
    expect(artwork.media, isNotEmpty);
    expect(
      artwork.media
          .firstWhere((m) => m.role == MediaRole.preview)
          .uri
          .toString(),
      'https://img.example.test/artwork.jpgv1/fill/w_1280/artwork?token=tok',
    );
    expect(
      artwork.media
          .firstWhere((m) => m.role == MediaRole.original)
          .uri
          .toString(),
      'https://img.example.test/artwork.jpg?token=tok',
    );
    expect(
      artwork.publishedAt?.toUtc(),
      DateTime.parse('2026-08-01T17:00:00Z'),
    );
  });

  test('falls back to the URL slug when deviationId is absent', () {
    final artwork = WebDeviationMapper.mapDeviation(<String, Object?>{
      'title': 'Journal',
      'url': 'https://www.deviantart.com/artist/journal/Journal-12345',
      'media': <String, Object?>{},
    });
    expect(artwork.id, '12345');
  });
}
