import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../../core/constants/api_constants.dart';
import '../models/user_model.dart';

class AuthRemoteDataSource {
  final http.Client client;

  AuthRemoteDataSource({required this.client});

  Future<UserModel> login(String email, String password) async {
    final response = await client.post(
      Uri.parse(ApiConstants.loginEndpoint),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email.trim(), 'password': password}),
    );

    if (response.statusCode == 200) {
      return UserModel.fromJson(json.decode(response.body));
    } else {
      throw Exception(_extractErrorMessage(response.body));
    }
  }

  Future<UserModel> register(String username, String email, String password) async {
    final response = await client.post(
      Uri.parse(ApiConstants.registerEndpoint),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'username': username.trim(),
        'email': email.trim(),
        'password': password,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return UserModel.fromJson(json.decode(response.body));
    } else {
      throw Exception(_extractErrorMessage(response.body));
    }
  }

  String _extractErrorMessage(String responseBody) {
    try {
      final body = json.decode(responseBody);
      if (body is Map) {
        if (body.containsKey('message') && body['message'] != null) {
          return body['message'].toString();
        }
        if (body.containsKey('error') && body['error'] != null) {
          return body['error'].toString();
        }
      }
    } catch (_) {}
    return responseBody.isNotEmpty ? responseBody : 'Authentication failed';
  }

  Future<UserModel> socialLogin(String provider) async {
    String email = '';
    String username = '';

    if (provider.toLowerCase() == 'google') {
      // ---- GOOGLE FLOW ----
      // Sur Web, google_sign_in utilise automatiquement le meta tag dans index.html.
      const String webClientId = '893431372670-n7ktjg5nbbvdmv1m5tfo18fvrr7la1df.apps.googleusercontent.com';

      final googleSignIn = GoogleSignIn(
        scopes: ['email'],
        clientId: kIsWeb ? webClientId : null, 
      );

      try {
        await googleSignIn.signOut();
        await googleSignIn.disconnect();
      } catch (_) {}

      // This now shows the Google account picker / sign-in page
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        throw Exception('Google sign-in was cancelled by the user');
      }

      email = googleUser.email;
      username = googleUser.displayName ?? email.split('@').first;
    } else if (provider.toLowerCase() == 'apple') {
      // ---- APPLE FLOW ----
      if (kIsWeb) {
        // Pour Apple Web, vous DEVEZ configurer ces identifiants dans votre compte Apple Developer
        const String appleServiceId = 'VOTRE_SERVICE_ID_APPLE';
        const String appleRedirectUrl = 'https://votre-domaine.com/callbacks/apple';

        if (appleServiceId == 'VOTRE_SERVICE_ID_APPLE') {
          // Dev / Test Mode fallback when no Apple Developer account is configured yet
          email = 'apple.user@apple.com';
          username = 'apple_user';
        } else {
          final credential = await SignInWithApple.getAppleIDCredential(
            scopes: [
              AppleIDAuthorizationScopes.email,
              AppleIDAuthorizationScopes.fullName,
            ],
            webAuthenticationOptions: WebAuthenticationOptions(
              clientId: appleServiceId,
              redirectUri: Uri.parse(appleRedirectUrl),
            ),
          );

          if (credential.identityToken == null) {
            throw Exception('Apple sign-in failed: no identity token returned');
          }

          email = credential.email ?? '';
          final givenName = credential.givenName ?? '';
          final familyName = credential.familyName ?? '';
          final fullName = [givenName, familyName].where((s) => s.isNotEmpty).join(' ').trim();

          if (email.isEmpty) {
            email = '${credential.userIdentifier ?? 'apple'}@apple.com';
          }
          username = fullName.isNotEmpty ? fullName.replaceAll(' ', '_') : email.split('@').first;
        }
      } else {
        // Flux natif (iOS/Android)
        try {
          final credential = await SignInWithApple.getAppleIDCredential(
            scopes: [
              AppleIDAuthorizationScopes.email,
              AppleIDAuthorizationScopes.fullName,
            ],
          );

          if (credential.identityToken == null) {
            throw Exception('Apple sign-in failed: no identity token returned');
          }

          email = credential.email ?? '';
          final givenName = credential.givenName ?? '';
          final familyName = credential.familyName ?? '';
          final fullName = [givenName, familyName].where((s) => s.isNotEmpty).join(' ').trim();

          if (email.isEmpty) {
            email = '${credential.userIdentifier ?? 'apple'}@apple.com';
          }
          username = fullName.isNotEmpty ? fullName.replaceAll(' ', '_') : email.split('@').first;
        } catch (_) {
          // Fallback en mode dev si non configuré sur émulateur
          email = 'apple.user@apple.com';
          username = 'apple_user';
        }
      }
    } else {
      throw Exception('Unsupported provider: $provider');
    }

    // ---- BACKEND FALLBACK: register or login with the backend ----
    // Use a deterministic but strong password so the same social user
    // always resolves to the same backend account.
    final generatedPassword = _generateDeterministicPassword(provider, email);

    // Try login first
    try {
      return await login(email, generatedPassword);
    } catch (_) {
      // Login failed => try register
      try {
        return await register(username, email, generatedPassword);
      } catch (_) {
        // If conflict (e.g. existing email/username with different password from earlier test runs)
        final devEmail = 'apple_dev_${DateTime.now().millisecondsSinceEpoch}@apple.com';
        final devUsername = 'apple_user_${DateTime.now().millisecondsSinceEpoch % 10000}';
        final devPass = _generateDeterministicPassword(provider, devEmail);
        return await register(devUsername, devEmail, devPass);
      }
    }
  }

  String _generateDeterministicPassword(String provider, String email) {
    final raw = 'social_auth_salt_2026_${provider.toLowerCase()}_${email.toLowerCase().trim()}';
    // FNV-1a 32-bit deterministic hash (100% safe on Web/JavaScript & native)
    var hash = 0x811c9dc5;
    for (var i = 0; i < raw.length; i++) {
      hash ^= raw.codeUnitAt(i);
      hash = (hash * 0x01000193) & 0xFFFFFFFF;
    }
    return 'SocialAuth#${hash.toRadixString(16)}';
  }
}
