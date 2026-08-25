class LoginResponse {
  final String token;
  final String? refreshToken;
  final Map<String, dynamic> user;

  const LoginResponse({
    required this.token,
    this.refreshToken,
    required this.user,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    print('🔄 Parsing LoginResponse from: $json');

    // Check if the response has the expected structure
    if (json['success'] == false) {
      throw Exception(json['message'] ?? 'Login failed');
    }

    // Support both shapes:
    //   Shape A (nested): { "data": { "token": "...", "user": {...} } }
    //   Shape B (flat):   { "token": "...", "user": {...} }
    final data = (json['data'] is Map<String, dynamic>)
        ? json['data'] as Map<String, dynamic>
        : json;

    // Check for accessToken or token
    final token =
        data['accessToken'] as String? ?? data['token'] as String? ?? '';

    if (token.isEmpty) {
      print('❌ No token found in response');
      print('📋 Response keys: ${data.keys.toList()}');
      throw Exception('No token in response');
    }

    // "user" may live at data['user'] or be the whole data map itself
    final userData = (data['user'] is Map<String, dynamic>)
        ? data['user'] as Map<String, dynamic>
        : data;

    // Ensure user has required fields
    if (!userData.containsKey('_id') && !userData.containsKey('id')) {
      print('❌ No user ID found in response');
      print('📋 User data: $userData');
    }

    return LoginResponse(
      token: token,
      refreshToken: data['refreshToken'] as String?,
      user: userData,
    );
  }
}
