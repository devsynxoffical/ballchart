import 'lib/core/services/api_service.dart';

void main() async {
  final apiService = ApiService();
  
  print('Testing API connection...');
  
  try {
    // Test basic connection
    final response = await apiService.get('/auth/admin/overview');
    print('✅ API Connection successful!');
    print('Response type: ${response.runtimeType}');
    print('Response keys: ${response.keys.toList()}');
  } catch (e) {
    print('❌ API Connection failed!');
    print('Error: $e');
    
    // Check if token exists
    final token = await apiService.getToken();
    if (token == null) {
      print('❌ No authentication token found');
    } else {
      print('✅ Token found: ${token.substring(0, 20)}...');
    }
  }
}
