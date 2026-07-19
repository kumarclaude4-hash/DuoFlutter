import 'package:http/http.dart' as http;
import 'dart:convert';
import '../core/constants.dart';

class PushServer {
  static Future<String> mintToken(String uid, String secret) async {
    final response = await http.post(
      Uri.parse('${AppConstants.pushServerUrl}/mintToken'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'uid': uid, 'secret': secret}),
    ).timeout(const Duration(seconds: 30));
    if (response.statusCode != 200) {
      throw Exception('mintToken failed: ${response.statusCode}');
    }
    final data = jsonDecode(response.body);
    return data['token'] as String;
  }

  static Future<String> createChat(String myUid, String partnerUid, String idToken) async {
    final response = await http.post(
      Uri.parse('${AppConstants.pushServerUrl}/createChat'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
      body: jsonEncode({'myUid': myUid, 'partnerUid': partnerUid}),
    ).timeout(const Duration(seconds: 30));
    if (response.statusCode != 200) throw Exception('createChat failed');
    final data = jsonDecode(response.body);
    return data['chatId'] as String;
  }

  static Future<void> migrateUid(String oldUid, String newUid, String idToken) async {
    await http.post(
      Uri.parse('${AppConstants.pushServerUrl}/migrateUid'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
      body: jsonEncode({'oldUid': oldUid, 'newUid': newUid}),
    ).timeout(const Duration(seconds: 30));
  }

  static Future<Map<String, dynamic>> turnCredentials(String idToken) async {
    final response = await http.post(
      Uri.parse('${AppConstants.pushServerUrl}/turnCredentials'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
      body: jsonEncode({}),
    ).timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) throw Exception('turnCredentials failed');
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> b2PresignedPut(
      String key, String contentType, String idToken) async {
    final response = await http.post(
      Uri.parse('${AppConstants.pushServerUrl}/b2PresignedPut'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
      body: jsonEncode({'key': key, 'contentType': contentType}),
    ).timeout(const Duration(seconds: 30));
    if (response.statusCode != 200) throw Exception('b2PresignedPut failed');
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  static Future<String> b2PresignedGet(String key, String idToken) async {
    final response = await http.post(
      Uri.parse('${AppConstants.pushServerUrl}/b2PresignedGet'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
      body: jsonEncode({'key': key}),
    ).timeout(const Duration(seconds: 30));
    if (response.statusCode != 200) throw Exception('b2PresignedGet failed');
    final data = jsonDecode(response.body);
    return data['url'] as String;
  }

  static Future<void> b2Delete(String key, String idToken) async {
    await http.post(
      Uri.parse('${AppConstants.pushServerUrl}/b2Delete'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
      body: jsonEncode({'key': key}),
    ).timeout(const Duration(seconds: 30));
  }

  static Future<Map<String, dynamic>?> linkPreview(String url, String idToken) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.pushServerUrl}/linkPreview'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode({'url': url}),
      ).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return null;
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  static Future<void> removeGroupMember(
      String groupId, String memberUid, String idToken) async {
    await http.post(
      Uri.parse('${AppConstants.pushServerUrl}/removeGroupMember'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
      body: jsonEncode({'groupId': groupId, 'memberUid': memberUid}),
    ).timeout(const Duration(seconds: 30));
  }
}
