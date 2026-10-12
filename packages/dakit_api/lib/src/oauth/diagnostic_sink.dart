import 'package:dakit_core/dakit_core.dart';

/// Diagnostics are observers, never part of the OAuth transaction contract.
void recordOAuthDiagnostic(DiagnosticSink sink, DiagnosticEvent event) {
  try {
    sink.add(event);
  } on Object {
    // A host's unavailable log sink must not abort authorization or hide the
    // original protocol/storage error. Do not recurse into that failing sink.
  }
}
