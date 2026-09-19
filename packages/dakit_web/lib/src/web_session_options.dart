import 'package:dio/dio.dart';

/// A desktop-Chrome user agent sent to DeviantArt's private web endpoints so
/// the requests look like a normal browser (the default Dart UA is rejected by
/// some endpoints). Shared by every web-session fetcher (DRY).
const String webUserAgent =
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) '
    'AppleWebKit/537.36 Chrome/126.0 Safari/537.36';

/// Dio options for DeviantArt's private web endpoints: a JSON response type,
/// an anonymous hidden-browser Cookie header, and a browser-like user agent.
Options webSessionOptions(String cookieHeader) => Options(
  responseType: ResponseType.json,
  headers: <String, dynamic>{
    'Accept': 'application/json',
    'Cookie': cookieHeader,
    'User-Agent': webUserAgent,
  },
);

/// Dio options for a DeviantArt HTML page fetched with the hidden browser's
/// cookies. This is intentionally separate from [webSessionOptions]: forcing
/// JSON for an artwork page makes dio try to decode the HTML response.
Options webPageOptions(String cookieHeader) => Options(
  responseType: ResponseType.plain,
  headers: <String, dynamic>{
    'Accept': 'text/html,application/xhtml+xml',
    if (cookieHeader.isNotEmpty) 'Cookie': cookieHeader,
    'User-Agent': webUserAgent,
  },
);
