import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../helper/shared_preferences.dart';
import '../model/add_product_request_model.dart';
import '../model/login_session_model.dart';
import '../model/product_search_listing_response_model.dart';
import '../model/product_search_logs_model.dart';
import '../model/product_update_request_model.dart';
import '../model/product_update_response_model.dart';
import '../model/update_product_listing_request_model.dart';
import '../model/update_product_listing_response_model.dart';

class ApiService {
  // Base URL for API endpoints
  final String baseUrl = "http://13.49.224.44:8080/api/registration";
  final String baseUrlProduct = "http://13.49.224.44:8080/api";

  // Admin credentials - in a real app, these should be stored securely
  // or managed through a proper backend system
  final int defaultPageSize = 10;
  final String loginAPI="/login";
  final String registerAPI="/register";
  final String userUpdateAPI="/update-status";
  final String searchUserListingAPI="/search";
  final String getProductListingAPI="/product/list";  //baseUrlProduct
  final String searchProductListingAPI="/product/list";  //baseUrlProduct
  final String updateProductAPI="/product/update";   //baseUrlProduct
  final String updateProductListingAPI="/product/update";   //baseUrlProduct
  final String downloadExcelAPI="/product/download";   //baseUrlProduct
  final String addProductAPI="/product/add";   //baseUrlProduct
  final String deleteProductAPI="/product/delete/";   //baseUrlProduct
  final String bulkProductAPI="/product/upload";   //baseUrlProduct
  final String sendOTPAPI="/send-otp";
  final String resetPasswordAPI="/reset-password";
  final String searchLogsAPI="/product/search-logs";  //baseUrlProduct
  final String loginSessionAPI="/login-sessions";

  /// Authenticate a regular user through API
  Future<Map<String, dynamic>?> userLogin({
    required String email,
    required String password,
  }) async {
    final url = Uri.parse('$baseUrl$loginAPI');

    try {
      debugPrint("Sending login request to $url with body: ${jsonEncode({
        "email": email,
        "password": password,
      })}");

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "email": email,
          "password": password,
        }),
      );

      debugPrint("login/Response: ${response.body}");

      final Map<String, dynamic> data = jsonDecode(response.body);
      final bool success = data['success'] ?? false;
      final String message = data['message'] ?? "Login failed.";
      final Map<String, dynamic>? userData = data['data'];

      if (response.statusCode == 200 && success && userData != null) {
        final String status = userData['status']?.toString().toLowerCase() ?? 'pending';
        final String role = userData['role']?.toString().toLowerCase() ?? 'user';

        // Save to shared preferences
        await SharedPreferenceHelper.setLoggedIn(true);
        await SharedPreferenceHelper.setUserEmail(email);
        await SharedPreferenceHelper.setUserType(role);
        await SharedPreferenceHelper.setUserStatus(status);

        return {
          'success': true,
          'message': message,
          'data': userData,
          'status': status,
          'role': role,
        };
      } else {
        // Always return server message
        return {
          'success': false,
          'message': message,
        };
      }
    } catch (e) {
      debugPrint('Unexpected error in login API: $e');
      return {
        "success": false,
        "message": "An error occurred. Please try again.",
      };
    }
  }

  /// Register a new user
  Future<Map<String, dynamic>> registerUser({
    required String name,
    required String mobileNumber,
    required String email,
    required String organisationName,
    required String password,
  }) async {
    final url = Uri.parse('$baseUrl${registerAPI}');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "name": name,
          "mobileNumber": mobileNumber,
          "email": email,
          "organisationName": organisationName,
          "password": password,
        }),
      );

      debugPrint("register/Response: ${response.body}");

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {"success": true, "message": responseData['message'] ?? 'Registration successful'};
      } else {
        return {"success": false, "message": responseData['message'] ?? 'Registration failed'};
      }
    } on TimeoutException catch (e) {
      debugPrint('TimeoutException in registration API: $e');
      throw TimeoutException('Request timed out');
    } catch (e) {
      debugPrint('Unexpected error in registration API: $e');
      return {"success": false, "message": "Unexpected error occurred"};
    }
  }

  /// Fetch users with pagination and status filtering
  Future<Map<String, dynamic>> getUsers({
    int page = 0,
    int size = 10,
    String? search = '',
    String? status,
    // bool excludeAdmin = true, // New parameter
  }) async {
    final Map<String, String> queryParams = {
      'page': page.toString(),
      'size': size.toString(),
      'search': search ?? '',
      // 'excludeAdmin': excludeAdmin.toString(), // Add this parameter
    };

    // Map status to backend status values
    if (status != null && status.isNotEmpty) {
      switch (status.toLowerCase()) {
        case 'pending':
          queryParams['status'] = 'Pending';
          break;
        case 'approved':
          queryParams['status'] = 'Active';
          break;
        case 'rejected':
          queryParams['status'] = 'Reject';
          break;
      }
    }

    final url = Uri.parse('$baseUrl${searchUserListingAPI}').replace(queryParameters: queryParams);

    try {
      final response = await http.get(url, headers: {'Content-Type': 'application/json'});

      debugPrint("getUsers/Response\t${response.body.toString()}");

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        debugPrint('Error fetching users: ${response.body}');
        throw Exception('Failed to load users: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error in getUsers: $e');
      return {'content': [], 'totalPages': 0, 'last': true};
    }
  }

  ///Logout regular user
  Future<void> logoutUser({required String userEmail}) async {
    final url = Uri.parse('$baseUrl/logout').replace(queryParameters: {
      'email': userEmail,
    });

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      debugPrint('Logout API response: Logout ${response.statusCode} - ${response.body}');
    } catch (e) {
      debugPrint('Logout API failed: $e');
    }
  }

  /// Fetch products with pagination and optional search query
  // Future<List<ProductListingResponseModel>> fetchProductList({
  //   int page = 0,
  //   int limit = 10,
  //   String? search,
  // }) async {
  //   final uri = Uri.parse('$baseUrlProduct$getProductListingAPI').replace(queryParameters: {
  //     'page': '$page',
  //     'limit': '$limit',
  //     if (search != null && search.isNotEmpty) 'search': search,
  //   });
  //
  //   try {
  //     final response = await http.get(
  //       uri,
  //       headers: {'Content-Type': 'application/json'},
  //     );
  //
  //     debugPrint("fetchProductList/Response => ${response.body}");
  //
  //     if (response.statusCode == 200) {
  //       final data = json.decode(response.body);
  //
  //       // ✅ Expecting a pure list
  //       if (data is List) {
  //         return data
  //             .map((item) => ProductListingResponseModel.fromJson(item))
  //             .toList();
  //       } else {
  //         throw Exception("Unexpected response format: Expected a JSON array.");
  //       }
  //     } else {
  //       throw Exception("API Error: ${response.statusCode} - ${response.reasonPhrase}");
  //     }
  //   } catch (e) {
  //     debugPrint("fetchProductList Exception: $e");
  //     return [];
  //   }
  // }

  /// Fetch products with pagination and optional advanced search query
  Future<Map<String, dynamic>> fetchProductListWithPagination({
    required int index,
    required int limit,
    required String search,
  }) async {
    final url = Uri.parse(
      "${baseUrlProduct}${searchProductListingAPI}?index=$index&limit=$limit&search=$search",
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonMap = jsonDecode(response.body);

      // Parse the model
      final model = ProductSearchListingResponseModel.fromJson(jsonMap);

      return {
        'products': model.products ?? [],
        'hasMore': ((model.totalCount ?? 0) > ((index + 1) * limit)),
        'totalCount': model.totalCount ?? 0, // Add totalCount to the response
      };
    } else {
      throw Exception('Failed to load products');
    }
  }



  /*/// Fetch products with pagination and search parameters
  Future<Map<String, dynamic>> fetchProductList({
    int index = 0,
    int limit = 10,
    String searchQuery = "",
  }) async {
    // Build the URL with query parameters
    final url = Uri.parse('$baseUrl$getProductListingAPI?index=$index&limit=$limit&search=${Uri.encodeComponent(searchQuery)}');

    try {
      debugPrint("Fetching products from: $url");

      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      debugPrint("fetchProductList/Response status: ${response.statusCode}");
      debugPrint("fetchProductList/Response => ${response.body}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Handle both scenarios - array response or paginated object response
        if (data is List) {
          // If API returns a plain array
          final List<ProductListingResponseModel> products =
          data.map((item) => ProductListingResponseModel.fromJson(item)).toList();

          return {
            'products': products,
            'totalCount': products.length,
            'hasMore': false, // Can't determine this with plain array
          };
        } else if (data is Map) {
          // If API returns a paginated object with metadata
          // Assuming structure like: { content: [...], totalElements: 100, totalPages: 10, ... }
          final List<ProductListingResponseModel> products =
          (data['content'] as List? ?? []).map((item) => ProductListingResponseModel.fromJson(item)).toList();

          return {
            'products': products,
            'totalCount': data['totalElements'] ?? 0,
            'currentPage': data['number'] ?? index,
            'totalPages': data['totalPages'] ?? 1,
            'hasMore': (data['number'] ?? 0) < (data['totalPages'] ?? 1) - 1,
          };
        }

        throw Exception('Unexpected response format');
      } else {
        debugPrint('Error fetching product list: ${response.body}');
        throw Exception('Failed to load product list: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Exception in fetchProductList: $e');
      throw Exception('Failed to fetch products: $e');
    }
  }*/

  ///Add product
  Future<Map<String, dynamic>?> addProduct({
    required String medicineName,
    required String genericName,
    required String manufacturedBy,
    required String indication,
    required AddProductRequestModel requestModel,
  }) async {
    final url = Uri.parse('$baseUrlProduct$addProductAPI');

    try {
      // Option 1: Use the requestModel directly
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestModel.toJson()), // Assuming requestModel has a toJson method
      );

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      debugPrint("addProduct/Response: ${response.body}");

      // Check if response body is empty or not valid JSON
      if (response.statusCode == 200) {
        return {"success": true, "message": responseData['message'] ?? 'Product added successful !'};
      } else {
        return {"success": false, "message": responseData['message'] ?? 'Product adding failed !'};
      }
    } catch (e) {
      debugPrint('Unexpected error in addProduct API: $e');
      return {'success': false, 'message': 'API connection error: $e'};
    }
  }

  ///Update product
  Future<ProductUpdateResponseModel?> updateProduct(ProductUpdateRequestModel requestModel) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrlProduct$updateProductAPI'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(requestModel.toJson()),
      );

      if (response.statusCode == 200) {
        return ProductUpdateResponseModel.fromJson(jsonDecode(response.body));
      } else {
        debugPrint('Failed to update product. Status code: ${response.statusCode}');
        debugPrint('Response body: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Exception when updating product: $e');
      return null;
    }
  }

  ///Delete product API
  Future<Map<String, dynamic>> deleteProduct(String productId) async {
    try {
      // Print the URL for debugging
      final url = '$baseUrlProduct$deleteProductAPI$productId';
      print('Delete URL: $url');

      final response = await http.delete(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );

      print('Delete response status: ${response.statusCode}');
      print('Delete response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 204) {
        // Try to parse as JSON first
        try {
          return jsonDecode(response.body);
        } catch (e) {
          // If response is not valid JSON, return a success response with the text message
          print('Response is not JSON: ${e.toString()}');
          return {
            'success': true,
            'message': response.body.isNotEmpty ? response.body : 'Product deleted successfully'
          };
        }
      } else {
        print('Failed to delete product. Status code: ${response.statusCode}');
        print('Response body: ${response.body}');

        // Try to parse error message if available
        String errorMessage;
        try {
          final errorBody = jsonDecode(response.body);
          errorMessage = errorBody['message'] ?? 'Unknown error occurred';
        } catch (e) {
          errorMessage = 'Failed to delete product. Status code: ${response.statusCode}';
        }

        return {
          'success': false,
          'message': errorMessage
        };
      }
    } catch (e) {
      print('Error deleting product: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  ///Send OTP
  Future<Map<String, dynamic>?> sendOTP({
    required String email,
  }) async {
    final url = Uri.parse('$baseUrl$sendOTPAPI');

    try {
      debugPrint("Sending OTP request to $url with body: ${jsonEncode({
        "email": email,
      })}");

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "email": email,
        }),
      );

      debugPrint("sendOTP/Response: ${response.body}");

      final Map<String, dynamic> data = jsonDecode(response.body);
      final bool success = data['success'] ?? false;
      final String message = data['message'] ?? "OTP send failed.";

      if (response.statusCode == 200 && success) {
        return {
          'success': true,
          'message': message,
        };
      } else {
        // Always return server message
        return {
          'success': false,
          'message': message,
        };
      }
    } catch (e) {
      debugPrint('Unexpected error in sendOTP API: $e');
      return {
        "success": false,
        "message": "An error occurred. Please try again.",
      };
    }
  }

  ///Bulk product upload
  Future<String?> uploadBulkProductList(File excelFile) async {
    final url = Uri.parse('$baseUrlProduct$bulkProductAPI');

    try {
      final request = http.MultipartRequest('POST', url);

      // Add the Excel file (adjust 'file' if backend uses another field name)
      request.files.add(await http.MultipartFile.fromPath('file', excelFile.path));

      // Optional headers (don't manually set Content-Type)
      request.headers.addAll({
        "Accept": "application/json",
      });

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('Upload response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final data = response.body;
        return data;
      } else {
        return "Failed to upload products: ${response.body}";
      }
    } catch (e) {
      return "Error uploading products: $e";
    }
  }

  ///Product update listing
  Future<UpdateProductListingResponseModel?> updateProductListing(
      UpdateProductListingRequestModel requestModel) async {
    final url = Uri.parse("$baseUrlProduct$updateProductListingAPI");

    try {
      final body = jsonEncode(requestModel.toJson());
      print("PUT $url");
      print("Request body:/UpdateProduct $body");

      final response = await http.put(
        url,
        headers: {"Content-Type": "application/json"},
        body: body,
      );

      print("Response status:/UpdateProduct ${response.statusCode}");
      print("Response body:/UpdateProduct ${response.body}");

      // Added detailed logging for debugging
      print("DEBUGGING: Full response body structure:");
      try {
        final decoded = jsonDecode(response.body);
        print(const JsonEncoder.withIndent('  ').convert(decoded));

        // Print each key-value pair for easier debugging
        decoded.forEach((key, value) {
          print("Key: $key, Value type: ${value.runtimeType}, Value: $value");
        });
      } catch (e) {
        print("Failed to decode response for debugging: $e");
      }

      if (response.statusCode == 200) {
        final Map<String, dynamic> json = jsonDecode(response.body);

        // Check if the API uses a different success indicator
        final bool isSuccess = json['success'] == true ||
            json['status'] == 'success' ||
            json['code'] == 200 ||
            json['status'] == 1 ||
            (json['data'] != null && json['error'] == null);

        if (isSuccess) {
          print("Success detected in response");
          if (json['data'] != null) {
            return UpdateProductListingResponseModel.fromJson(json['data']);
          } else if (json['result'] != null) {
            // Some APIs use 'result' instead of 'data'
            return UpdateProductListingResponseModel.fromJson(json['result']);
          } else {
            print("Success without data:/UpdateProduct ${json['message'] ?? 'No data'}");
            // Create a dummy response with status 1 to indicate success
            return UpdateProductListingResponseModel(status: 1);
          }
        } else {
          // Check for different error formats
          String errorMsg = json['error'] ??
              json['message'] ??
              json['errorMessage'] ??
              json['errorMsg'] ??
              'Unknown API error';

          print("API error:/UpdateProduct $errorMsg");

          // Return a model with status 0 to indicate failure with error message
          return UpdateProductListingResponseModel(
              status: 0,
              medicineName: errorMsg
          );
        }
      } else {
        print("HTTP error:/UpdateProduct ${response.statusCode}: ${response.reasonPhrase}");
        // Return a model with status 0 to indicate HTTP error
        return UpdateProductListingResponseModel(
            status: 0,
            medicineName: "HTTP error ${response.statusCode}: ${response.reasonPhrase}"
        );
      }
    } catch (e) {
      print("Exception in updateProductListing: $e");
      // Return a model with status 0 to indicate exception
      return UpdateProductListingResponseModel(
          status: 0,
          medicineName: "Exception: $e"
      );
    }
  }

  ///Login session report API
  Future<LoginSessionModel> fetchLoginSessions() async {
    final url = Uri.parse("$baseUrl$loginSessionAPI");
    final response = await http.get(url);

    print("RAW SESSION RESPONSE: ${response.body}");

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);

      if (json['sessions'] != null) {
        return LoginSessionModel.fromJson(json);
      } else if (json['data'] != null) {
        return LoginSessionModel.fromJson(json['data']); // if sessions are nested in "data"
      } else {
        throw Exception("No session data found");
      }
    } else {
      throw Exception("Failed to load sessions");
    }
  }

  ///Product searching logs API
  Future<List<ProductSearchLogs>> fetchSearchLogs() async {
    final url = Uri.parse("$baseUrlProduct$searchLogsAPI");

    final response = await http.get(url);
    if (response.statusCode == 200) {
      print("productSearchLogs/ADMIN\t${response}");
      final List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList.map((e) => ProductSearchLogs.fromJson(e)).toList();
    } else {
      throw Exception("Failed to load search logs");
    }
  }


  // Helper method to map backend status to frontend display status
  String _mapStatusToFrontend(String backendStatus) {
    switch (backendStatus) {
      case 'PENDING':
        return 'Pending';
      case 'ACTIVE':
        return 'Approved';
      case 'REJECTED':
        return 'Rejected';
      default:
        return 'Pending';
    }
  }
}