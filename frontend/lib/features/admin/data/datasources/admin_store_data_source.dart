import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_error.dart';
import '../../../../core/providers/health_check_provider.dart'
    show apiClientProvider;

/// The merchant-facing half of the store API — everything under
/// `/admin/store`. Separate from [AdminRemoteDataSource] because it is a
/// different surface with its own resources; the two only share the fact
/// that both need an admin token.
class AdminStoreDataSource {
  AdminStoreDataSource(this._client);

  final ApiClient _client;

  Map<String, String> _bearer(String token) => {'Authorization': 'Bearer $token'};

  Map<String, dynamic> _ok(http.Response response) {
    // 200 for reads and updates, 201 for creates — the API uses Nest's
    // defaults rather than normalising them, so both are accepted here.
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw apiExceptionFromResponse(response);
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  // ---------------------------------------------------------------- products

  Future<Map<String, dynamic>> listProducts(
    String token, {
    int page = 1,
    String? search,
  }) async {
    final query = Uri(
      queryParameters: <String, String>{'page': '$page', 'search': ?search},
    ).query;
    return _ok(
      await _client.get('/admin/store/products?$query', headers: _bearer(token)),
    );
  }

  Future<Map<String, dynamic>> createProduct(
    String token,
    Map<String, dynamic> body,
  ) async =>
      _ok(await _client.post('/admin/store/products', body: body, headers: _bearer(token)));

  Future<Map<String, dynamic>> updateProduct(
    String token,
    String id,
    Map<String, dynamic> body,
  ) async => _ok(
    await _client.patch('/admin/store/products/$id', body: body, headers: _bearer(token)),
  );

  Future<Map<String, dynamic>> deactivateProduct(String token, String id) async =>
      _ok(await _client.delete('/admin/store/products/$id', headers: _bearer(token)));

  /// Multipart — the image goes to Cloudinary server-side before the product
  /// can reference it, so this cannot be part of the JSON body above.
  Future<Map<String, dynamic>> addProductImage(
    String token,
    String id,
    List<int> bytes,
    String filename,
  ) async => _ok(
    await _client.postMultipart(
      '/admin/store/products/$id/images',
      fileField: 'file',
      fileBytes: bytes,
      filename: filename,
      headers: _bearer(token),
    ),
  );

  Future<Map<String, dynamic>> removeProductImage(
    String token,
    String id,
    String publicId,
  ) async => _ok(
    await _client.delete(
      // The publicId is a Cloudinary path with slashes in it, so it has to
      // be encoded or it would be read as extra route segments.
      '/admin/store/products/$id/images/${Uri.encodeComponent(publicId)}',
      headers: _bearer(token),
    ),
  );

  // -------------------------------------------------------------- categories

  Future<Map<String, dynamic>> listCategories(String token) async =>
      _ok(await _client.get('/admin/store/categories', headers: _bearer(token)));

  Future<Map<String, dynamic>> createCategory(
    String token,
    Map<String, dynamic> body,
  ) async => _ok(
    await _client.post('/admin/store/categories', body: body, headers: _bearer(token)),
  );

  Future<Map<String, dynamic>> updateCategory(
    String token,
    String id,
    Map<String, dynamic> body,
  ) async => _ok(
    await _client.patch('/admin/store/categories/$id', body: body, headers: _bearer(token)),
  );

  Future<Map<String, dynamic>> setCategoryImage(
    String token,
    String id,
    List<int> bytes,
    String filename,
  ) async => _ok(
    await _client.postMultipart(
      '/admin/store/categories/$id/image',
      fileField: 'file',
      fileBytes: bytes,
      filename: filename,
      headers: _bearer(token),
    ),
  );

  // ------------------------------------------------------------------ orders

  Future<Map<String, dynamic>> listOrders(
    String token, {
    int page = 1,
    String? status,
  }) async {
    final query = Uri(
      queryParameters: <String, String>{'page': '$page', 'status': ?status},
    ).query;
    return _ok(
      await _client.get('/admin/store/orders?$query', headers: _bearer(token)),
    );
  }

  Future<Map<String, dynamic>> setOrderStatus(
    String token,
    String id,
    String status,
  ) async => _ok(
    await _client.patch(
      '/admin/store/orders/$id/status',
      body: {'status': status},
      headers: _bearer(token),
    ),
  );

  // ---------------------------------------------------------------- shipping

  Future<Map<String, dynamic>> listShippingZones(String token) async => _ok(
    await _client.get('/admin/store/shipping-zones', headers: _bearer(token)),
  );

  Future<Map<String, dynamic>> updateShippingZone(
    String token,
    String id,
    Map<String, dynamic> body,
  ) async => _ok(
    await _client.patch(
      '/admin/store/shipping-zones/$id',
      body: body,
      headers: _bearer(token),
    ),
  );
}

final adminStoreDataSourceProvider = Provider<AdminStoreDataSource>(
  (ref) => AdminStoreDataSource(ref.watch(apiClientProvider)),
);
