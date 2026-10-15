import 'dart:convert';

import 'package:dakit_web/dakit_web.dart';
import 'package:test/test.dart';

/// Captured from a real dadeviation/init tiptap description (2026-10-14),
/// reduced to the paragraphs that carry text plus the inline nodes.
/// Account name and numeric id already replaced.
String get capturedMarkup => jsonEncode(<String, Object?>{
  'version': '1',
  'document': <String, Object?>{
    'type': 'doc',
    'content': <Object?>[
      <String, Object?>{
        'type': 'paragraph',
        'content': <Object?>[
          <String, Object?>{'type': 'text', 'text': 'A commission drawn by '},
          <String, Object?>{
            'type': 'da-mention',
            'attrs': <String, Object?>{
              'user': <String, Object?>{
                'username': 'ExampleArtist',
                'userId': 123456789,
                'type': 'regular',
              },
            },
          },
          <String, Object?>{'type': 'text', 'text': ' '},
          <String, Object?>{
            'type': 'da-emote',
            'attrs': <String, Object?>{
              'data-type': 'user',
              'title': 'ExampleArtist',
              'url': 'https://www.deviantart.com/ExampleArtist',
            },
          },
          <String, Object?>{
            'type': 'text',
            'text': ' please support her work and commissions.',
          },
        ],
      },
      <String, Object?>{'type': 'paragraph'},
      <String, Object?>{
        'type': 'paragraph',
        'content': <Object?>[
          <String, Object?>{
            'type': 'text',
            'text': 'Zelena the Unpopful Hedgehog is own by me. ',
          },
        ],
      },
    ],
  },
  'features': <Object?>[],
});

void main() {
  group('tiptapToPlainText', () {
    test('keeps the mention name from a da-mention inline node', () {
      final text = tiptapToPlainText(capturedMarkup);
      expect(
        text,
        contains('A commission drawn by @ExampleArtist'),
        reason: 'the mention is real readable content, not decoration',
      );
    });

    test('does not leave a hole where an inline node was dropped', () {
      final text = tiptapToPlainText(capturedMarkup);
      expect(
        text,
        isNot(contains('drawn by  please')),
        reason: 'dropping a node must not leave doubled whitespace',
      );
    });

    test('agrees with the HTML rendering about visible text', () {
      final plain = tiptapToPlainText(capturedMarkup);
      final html = tiptapToHtml(capturedMarkup);
      expect(html.contains('@ExampleArtist'), isTrue);
      expect(
        plain.contains('@ExampleArtist'),
        html.contains('@ExampleArtist'),
        reason: 'both walkers should surface the same visible text',
      );
    });

    test('keeps a space between da-emote and following text', () {
      final text = tiptapToPlainText(capturedMarkup);
      expect(text, contains('please support her work and commissions.'));
    });

    test('still separates paragraphs', () {
      final text = tiptapToPlainText(capturedMarkup);
      expect(
        text,
        contains('commissions.\n\nZelena'),
        reason: 'block handling already works and must not regress',
      );
    });

    test('keeps a literature da-deviation label', () {
      const doc =
          '{"document":{"type":"doc","content":['
          '{"type":"da-deviation","attrs":{"deviation":'
          '{"url":"https://x.test/j","title":"A story"}}},'
          '{"type":"paragraph","content":['
          '{"type":"text","text":"after"}]}]}}';
      final text = tiptapToPlainText(doc);
      expect(text, contains('A story'));
      expect(text, contains('after'));
    });

    test('separates a blockquote from the next paragraph', () {
      const doc =
          '{"document":{"type":"doc","content":['
          '{"type":"blockquote","content":['
          '{"type":"paragraph","content":['
          '{"type":"text","text":"Q"}]}]},'
          '{"type":"paragraph","content":['
          '{"type":"text","text":"Next"}]}]}}';
      expect(tiptapToPlainText(doc), 'Q\n\nNext');
    });
  });
}
