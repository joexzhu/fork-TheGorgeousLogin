import 'dart:convert';
import 'package:http/http.dart' as http;

class HttpService {
  factory HttpService() {
    return _instance;
  }

  HttpService._internal();

  final JsonDecoder _decoder = const JsonDecoder();
  final JsonEncoder _encoder = const JsonEncoder();

  Map<String, String> headers = {'content-type': 'application/json'};
  Map<String, String> cookies = <String, String>{};

  static final HttpService _instance = HttpService._internal();

  void _updateCookie(http.Response response) {
    final String allSetCookie = response.headers['set-cookie'];

    if (allSetCookie != null) {
      final List<String> setCookies = allSetCookie.split(',');

      for (final String setCookie in setCookies) {
        final List<String> cookies = setCookie.split(';');
        cookies.forEach((String cookie) {
          _setCookie(cookie);
        });
      }

      headers['cookie'] = _generateCookieHeader();
    }
  }

/*   void _setCookie1(String rawCookie) {
    if (rawCookie.isNotEmpty) {
      final List<String> keyValue = rawCookie
          .split('=')
          .where((String s) => s.isNotEmpty)
          .toList(growable: false);
      if (keyValue.length == 2) {
        final String key = keyValue[0].trim();
        final String value = keyValue[1];

        // ignore keys that aren't cookies
        if (key.toLowerCase() == 'path' || key == 'expires') return;

        cookies[key] = value;
      }
    }
  }
 */
  void _setCookie(String rawCookie) {
    if (rawCookie.isNotEmpty) {
      final int idx = rawCookie.indexOf('=');
      if (idx >= 0) {
        final String key = rawCookie.substring(0, idx).trim();
        final String value = rawCookie.substring(idx + 1).trim();
        final String lowercaseKey = key.toLowerCase();
        if (lowercaseKey == 'path' ||
            lowercaseKey == 'expires' ||
            lowercaseKey == 'domain' ||
            lowercaseKey == 'SameSite') return;
        cookies[key] = value;
      }
    }
  }

  String _generateCookieHeader() {
    String cookieString = '';

    cookies.keys.forEach((String key) {
      if (cookieString.isNotEmpty) cookieString += ';';
      cookieString += key + '=' + cookies[key];
    });

    return cookieString;
  }

  Future<dynamic> get(String url) {
    return http
        .get(Uri.parse(url), headers: headers)
        .then<dynamic>((http.Response response) {
      final String res = response.body;
      final int statusCode = response.statusCode;

      _updateCookie(response);

      if (statusCode < 200 || statusCode > 400 || json == null) {
        throw Exception('Error while fetching data');
      }
      return _decoder.convert(res);
    });
  }

  Future<dynamic> post(String url, {Object body, Encoding encoding}) {
    return http
        .post(Uri.parse(url),
            body: _encoder.convert(body), headers: headers, encoding: encoding)
        .then<dynamic>((http.Response response) {
      final String res = response.body;
      final int statusCode = response.statusCode;

      _updateCookie(response);

      if (statusCode < 200 || statusCode > 400 || json == null) {
        throw Exception('Error while fetching data');
      }
      return _decoder.convert(res);
    });
  }
}
