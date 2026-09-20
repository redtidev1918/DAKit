enum MediaKind {
  image,
  video,
  animation,
  archive,
  document,
  literature,
  unknown,
}

enum MediaRole { preview, original, attachment }

enum MediaAvailability {
  available,
  loginRequired,
  purchaseRequired,
  restricted,
  unavailable,
  missing,
}

final class MediaAsset {
  const MediaAsset({
    required this.id,
    required this.kind,
    required this.role,
    required this.availability,
    this.uri,
    this.mimeType,
    this.filename,
    this.byteLength,
    this.width,
    this.height,
    this.duration,
    this.availabilityReason,
  });

  final String id;
  final MediaKind kind;
  final MediaRole role;
  final MediaAvailability availability;
  final Uri? uri;
  final String? mimeType;
  final String? filename;
  final int? byteLength;
  final int? width;
  final int? height;
  final Duration? duration;

  /// A human-readable reason the asset is not [MediaAvailability.available].
  ///
  /// For example, when the official download endpoint declines a request this
  /// carries the provider's `error_description` (e.g. "Deviation not
  /// downloadable" versus "Free download limit reached"), so hosts can show a
  /// more useful message than the generic [availability] alone.
  ///
  /// `null` when the asset is available or no reason was supplied.
  final String? availabilityReason;

  bool get canTransfer =>
      availability == MediaAvailability.available && uri != null;
}

/// Builds the shared [MediaAsset.id] scheme used by official and web adapters.
///
/// IDs are scoped by the owning artwork and role. [variant] distinguishes
/// multiple assets with the same role (for example thumbnails or video
/// qualities). Keeping this in `dakit_core` prevents adapters from inventing
/// provider-specific one-off formats.
String mediaAssetId(String artworkId, MediaRole role, {String? variant}) {
  final normalizedArtworkId = artworkId.trim();
  final normalizedVariant = variant?.trim();
  if (normalizedArtworkId.isEmpty) {
    throw ArgumentError.value(artworkId, 'artworkId', 'must not be empty');
  }
  if (normalizedVariant != null && normalizedVariant.isEmpty) {
    throw ArgumentError.value(variant, 'variant', 'must not be empty');
  }
  final roleSegment = switch (role) {
    MediaRole.preview => 'preview',
    MediaRole.original => 'original',
    MediaRole.attachment => 'attachment',
  };
  return normalizedVariant == null
      ? '$normalizedArtworkId:$roleSegment'
      : '$normalizedArtworkId:$roleSegment:$normalizedVariant';
}
