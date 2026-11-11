import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'study_report.dart';

abstract interface class LearningService {
  Future<StudyReport> processStudy({
    required String title,
    required String source,
  });

  Future<Uint8List> generateCrossSectionImage({
    required String title,
    required String source,
  });

  void close();
}

class LearningServiceException implements Exception {
  const LearningServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}

typedef IdTokenProvider = Future<String?> Function();

class ApiLearningService implements LearningService {
  ApiLearningService({
    http.Client? client,
    String? baseUrl,
    IdTokenProvider? tokenProvider,
  })  : _client = client ?? http.Client(),
        _ownsClient = client == null,
        _baseUrl = baseUrl ?? _defaultApiBaseUrl,
        _tokenProvider = tokenProvider ?? _firebaseIdToken;

  final http.Client _client;
  final bool _ownsClient;
  final String _baseUrl;
  final IdTokenProvider _tokenProvider;

  static const _configuredApiBaseUrl = String.fromEnvironment(
    'PRICEGENT_API_BASE_URL',
  );
  static const _defaultApiBaseUrl =
      _configuredApiBaseUrl != '' ? _configuredApiBaseUrl : '';

  static Future<String?> _firebaseIdToken() async =>
      FirebaseAuth.instance.currentUser?.getIdToken();

  Future<Map<String, String>> _authorizedHeaders() async {
    final String? idToken;
    try {
      idToken = await _tokenProvider();
    } on FirebaseAuthException {
      throw const LearningServiceException(
        'Your sign-in session expired. Sign in again and retry.',
      );
    }
    if (idToken == null || idToken.isEmpty) {
      throw const LearningServiceException(
        'Sign in with Google before using the learning service.',
      );
    }
    return {
      'content-type': 'application/json',
      'authorization': 'Bearer $idToken',
    };
  }

  @override
  void close() {
    if (_ownsClient) _client.close();
  }

  @override
  Future<StudyReport> processStudy({
    required String title,
    required String source,
  }) async {
    final Uri endpoint;
    try {
      endpoint = Uri.parse('$_baseUrl/v1/studies/process');
      if (!endpoint.hasScheme || endpoint.host.isEmpty) {
        throw const FormatException('The API URL is incomplete.');
      }
    } on FormatException {
      throw const LearningServiceException(
        'The learning service address is missing or invalid. Configure PRICEGENT_API_BASE_URL and try again.',
      );
    }

    try {
      final response = await _client
          .post(
            endpoint,
            headers: await _authorizedHeaders(),
            body: jsonEncode({'title': title, 'source': source}),
          )
          .timeout(const Duration(seconds: 65));

      final body = jsonDecode(response.body);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final detail = body is Map<String, dynamic> ? body['detail'] : null;
        throw LearningServiceException(
          detail is String
              ? detail
              : 'Pricegent could not process this material. Please try again.',
        );
      }
      if (body is! Map<String, dynamic>) {
        throw const LearningServiceException(
          'The learning service returned an unexpected response. Please try again.',
        );
      }
      return StudyReport.fromJson(body);
    } on TimeoutException {
      throw const LearningServiceException(
        'The study is taking too long. Check your connection and try again.',
      );
    } on http.ClientException {
      throw const LearningServiceException(
        'Pricegent could not reach its learning service. Check your connection and PRICEGENT_API_BASE_URL, then try again.',
      );
    } on FormatException {
      throw const LearningServiceException(
        'The learning service returned unreadable data. Please try again.',
      );
    } on TypeError {
      throw const LearningServiceException(
        'The learning service returned an unexpected study guide. Please try again.',
      );
    }
  }

  @override
  Future<Uint8List> generateCrossSectionImage({
    required String title,
    required String source,
  }) async {
    final Uri endpoint;
    try {
      endpoint = Uri.parse('$_baseUrl/v1/studies/illustrate');
      if (!endpoint.hasScheme || endpoint.host.isEmpty) {
        throw const FormatException('The API URL is incomplete.');
      }
    } on FormatException {
      throw const LearningServiceException(
        'The learning service address is missing or invalid. Configure PRICEGENT_API_BASE_URL and try again.',
      );
    }

    try {
      final response = await _client
          .post(
            endpoint,
            headers: await _authorizedHeaders(),
            body: jsonEncode({'title': title, 'source': source}),
          )
          .timeout(const Duration(seconds: 125));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final responseText = utf8.decode(response.bodyBytes);
        final body = jsonDecode(responseText);
        final detail = body is Map<String, dynamic> ? body['detail'] : null;
        throw LearningServiceException(
          detail is String
              ? detail
              : 'Pricegent could not generate this illustration. Please try again.',
        );
      }
      if (!response.headers['content-type'].toString().startsWith('image/')) {
        throw const LearningServiceException(
          'The learning service returned an unexpected illustration. Please try again.',
        );
      }
      if (response.bodyBytes.isEmpty) {
        throw const LearningServiceException(
          'The learning service returned an empty illustration. Please try again.',
        );
      }
      return response.bodyBytes;
    } on TimeoutException {
      throw const LearningServiceException(
        'The illustration is taking too long. Check your connection and try again.',
      );
    } on http.ClientException {
      throw const LearningServiceException(
        'Pricegent could not reach its learning service. Check your connection and PRICEGENT_API_BASE_URL, then try again.',
      );
    } on FormatException {
      throw const LearningServiceException(
        'The learning service returned unreadable illustration data. Please try again.',
      );
    }
  }
}
