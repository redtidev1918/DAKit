import 'package:dakit_core/dakit_core.dart';
import 'package:test/test.dart';

void main() {
  test('builds one shared media asset id scheme', () {
    expect(
      mediaAssetId('art-1', MediaRole.preview, variant: 'poster'),
      'art-1:preview:poster',
    );
    expect(mediaAssetId(' art-1 ', MediaRole.original), 'art-1:original');
    expect(() => mediaAssetId('', MediaRole.original), throwsArgumentError);
    expect(
      () => mediaAssetId('art-1', MediaRole.preview, variant: ' '),
      throwsArgumentError,
    );
  });
}
