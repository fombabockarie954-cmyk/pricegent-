import 'dart:async';
import 'dart:convert';

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

class ApiLearningService implements LearningService {
  ApiLearningService({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        _ownsClient = client == null,
        _baseUrl = baseUrl ?? _defaultApiBaseUrl;

  final http.Client _client;
  final bool _ownsClient;
  final String _baseUrl;

  static const _configuredApiBaseUrl = String.fromEnvironment(
    'PRICEGENT_API_BASE_URL',
  );
  static const _defaultApiBaseUrl = _configuredApiBaseUrl != ''
      ? _configuredApiBaseUrl
      : '';

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
            headers: const {'content-type': 'application/json'},
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
            headers: const {'content-type': 'application/json'},
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
