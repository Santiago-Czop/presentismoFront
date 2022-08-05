import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class Server {
  static Future<String> obtenerIp() async {
    final Map<String, dynamic> queryParams = {'format': 'json'};
    final response = await http.get(
      Uri.https('api.ipify.org', '/', queryParams),
      headers: {
        HttpHeaders.contentTypeHeader: 'application/json',
      },
    );

    switch (response.statusCode) {
      case HttpStatus.ok:
        return jsonDecode(response.body)['ip'];
      default:
        return '';
    }
  }

  static Future<bool> darPresente(int legajo, String ip) async {
    final Map<String, dynamic> queryParams = {'ip': ip};

    final response = await http.post(
      Uri.http('listapresente.herokuapp.com', '/presente/$legajo', queryParams),
      headers: {
        HttpHeaders.acceptHeader: 'application/json',
      },
    );

    switch (response.statusCode) {
      case HttpStatus.ok:
        return true;
      default:
        return false;
    }
  }
}
