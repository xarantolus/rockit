import 'dart:convert';

import 'package:http/http.dart' as http;

class APIClient {
  static final _httpClient = http.Client();

  Future<String> fetch(Uri url) async {
    var response = await _httpClient.get(url);

    // We need to decode utf8, else text like "äöü" will be decoded wrong
    return utf8.decode(response.bodyBytes);
  }
}
