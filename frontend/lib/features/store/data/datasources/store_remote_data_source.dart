import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_error.dart';
import '../../../../core/providers/health_check_provider.dart'
    show apiClientProvider;

class StoreRemoteDataSource {
  StoreRemoteDataSource(this._client);

  final ApiClient _client;

  Map<String, String> _bearer(String accessToken) => {
    'Authorization': 'Bearer $accessToken',
  };

  Map<String, dynamic> _decode(dynamic response) =>
      jsonDecode(response.body as String) as Map<String, dynamic>;

  Future<Map<String, dynamic>> listCategories() async {
    final response = await _client.get('/store/categories');
    if (response.statusCode != 200) throw apiExceptionFromResponse(response);
    return _decode(response);
  }

  Future<Map<String, dynamic>> listProducts(Map<String, String> query) async {
    final queryString = Uri(queryParameters: query).query;
    final response = await _client.get('/store/products?$queryString');
    if (response.statusCode != 200) throw apiExceptionFromResponse(response);
    return _decode(response);
  }

  Future<Map<String, dynamic>> getProductBySlug(String slug) async {
    final response = await _client.get(
      '/store/products/${Uri.encodeComponent(slug)}',
    );
    if (response.statusCode != 200) throw apiExceptionFromResponse(response);
    return _decode(response);
  }

  Future<Map<String, dynamic>> listShippingZones() async {
    final response = await _client.get('/store/shipping-zones');
    if (response.statusCode != 200) throw apiExceptionFromResponse(response);
    return _decode(response);
  }

  /// Checkout. [accessToken] is optional on purpose — the endpoint is behind
  /// the backend's optional auth guard, so a guest posts the same body with
  /// no Authorization header and gets a guest order.
  Future<Map<String, dynamic>> placeOrder(
    Map<String, dynamic> body, {
    String? accessToken,
  }) async {
    final response = await _client.post(
      '/store/orders',
      body: body,
      headers: accessToken == null ? null : _bearer(accessToken),
    );
    if (response.statusCode != 201 && response.statusCode != 200) {
      throw apiExceptionFromResponse(response);
    }
    return _decode(response);
  }

  /// Prices a code against the cart's subtotal without consuming it. The
  /// subtotal sent here is only a quote input — checkout re-prices
  /// everything server-side before a piastre is committed.
  Future<Map<String, dynamic>> previewCoupon({
    required String code,
    required int subtotalMinor,
  }) async {
    final response = await _client.post(
      '/store/coupons/preview',
      body: {'code': code, 'subtotalMinor': subtotalMinor},
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw apiExceptionFromResponse(response);
    }
    return _decode(response);
  }

  /// A POST rather than a GET because the email is the credential here, and
  /// a query string lands in access logs and browser history.
  Future<Map<String, dynamic>> trackOrder({
    required String orderNumber,
    required String email,
  }) async {
    final response = await _client.post(
      '/store/orders/track',
      body: {'orderNumber': orderNumber, 'email': email},
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw apiExceptionFromResponse(response);
    }
    return _decode(response);
  }

  Future<Map<String, dynamic>> listMyOrders(
    String accessToken, {
    int page = 1,
  }) async {
    final response = await _client.get(
      '/store/orders/mine?page=$page',
      headers: _bearer(accessToken),
    );
    if (response.statusCode != 200) throw apiExceptionFromResponse(response);
    return _decode(response);
  }
}

final storeRemoteDataSourceProvider = Provider<StoreRemoteDataSource>(
  (ref) => StoreRemoteDataSource(ref.watch(apiClientProvider)),
);
