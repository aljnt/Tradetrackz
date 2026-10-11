import 'package:shared_preferences/shared_preferences.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/user_model.dart';

class AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepository({required this.remoteDataSource});

  Future<UserModel> login(String email, String password) async {
    final user = await remoteDataSource.login(email, password);
    await _saveToken(user.token);
    return user;
  }

  Future<UserModel> register(String username, String email, String password) async {
    final user = await remoteDataSource.register(username, email, password);
    await _saveToken(user.token);
    return user;
  }

  Future<UserModel> socialLogin(String provider) async {
    final user = await remoteDataSource.socialLogin(provider);
    await _saveToken(user.token);
    return user;
  }

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt_token', token);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
  }
}
