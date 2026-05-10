import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class FunctionsApi {
  static const String _cloudUrl =
      'https://us-central1-pi-iii-d8570.cloudfunctions.net/api';
  static const String _emulatorUrl =
      'http://127.0.0.1:5001/pi-iii-d8570/us-central1/api';

  static String get baseUrl {
    const override = String.fromEnvironment('FUNCTIONS_BASE_URL');
    if (override.isNotEmpty) {
      return override;
    }

    if (kReleaseMode) {
      return _cloudUrl;
    }

    return _emulatorUrl;
  }

  static Future<void> creditWallet(double amount) async {
    await _post('/wallet/credit', {'amount': amount});
  }

  static Future<void> createBuyOffer({
    required String startupId,
    required double quantidade,
    required double precoUnitario,
  }) async {
    await _post('/orders/create-offer', {
      'startupId': startupId,
      'quantidade': quantidade,
      'precoUnitario': precoUnitario,
      'tipo': 'compra',
    });
  }

  static Future<void> sellTokens({
    required String startupId,
    required double quantidade,
    required double precoUnitario,
  }) async {
    await _post('/orders/sell', {
      'startupId': startupId,
      'quantidade': quantidade,
      'precoUnitario': precoUnitario,
    });
  }

  static Future<void> buyOffer({
    required String offerId,
    required double quantidade,
  }) async {
    await _post('/orders/buy', {'offerId': offerId, 'quantidade': quantidade});
  }

  static Future<void> acceptBuyOffer({
    required String offerId,
    required double quantidade,
  }) async {
    await _post('/orders/accept-buy', {
      'offerId': offerId,
      'quantidade': quantidade,
    });
  }

  static Future<String> getAutoResponse(String question) async {
    final data = await _postForResponse('/qa/auto-response', {
      'question': question,
    });
    return data['answer']?.toString() ?? '';
  }

  static Future<void> _post(String path, Map<String, dynamic> body) async {
    await _postForResponse(path, body);
  }

  static Future<Map<String, dynamic>> _postForResponse(
    String path,
    Map<String, dynamic> body,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('user-not-authenticated');
    }

    final token = await user.getIdToken();
    final response = await http.post(
      Uri.parse('$baseUrl$path'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      String error = 'request-failed';
      try {
        final data = jsonDecode(response.body) as Map<String, dynamic>?;
        error = data?['error']?.toString() ?? error;
      } catch (_) {
        if (response.body.isNotEmpty) {
          error = response.body;
        }
      }
      throw Exception(error);
    }

    if (response.body.isEmpty) {
      return <String, dynamic>{};
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>?;
    return data ?? <String, dynamic>{};
  }
}
