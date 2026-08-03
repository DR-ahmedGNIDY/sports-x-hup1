import 'dart:convert';

import 'package:http/http.dart' as http;

import '../errors/app_exception.dart';

/// Parses a NestJS error response body — `{ statusCode, message, error }`,
/// where `message` may be a single string or an array of validation
/// messages from class-validator — into a single readable [AppException].
AppException apiExceptionFromResponse(http.Response response) {
  try {
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final message = body['message'];
    final text = message is List ? message.join(', ') : message.toString();
    return AppException(text, statusCode: response.statusCode);
  } catch (_) {
    return AppException(
      'Something went wrong. Please try again.',
      statusCode: response.statusCode,
    );
  }
}
