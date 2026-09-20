import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class NativeIdentityCancelled implements Exception {
  const NativeIdentityCancelled();
}

class GoogleIdentityCredential {
  const GoogleIdentityCredential(this.idToken);
  final String idToken;
}

class AppleIdentityCredential {
  const AppleIdentityCredential({
    required this.identityToken,
    required this.rawNonce,
    this.givenName,
    this.familyName,
  });
  final String identityToken;
  final String rawNonce;
  final String? givenName;
  final String? familyName;
}

class NativeIdentityService {
  NativeIdentityService({GoogleSignIn? google})
      : _google = google ?? GoogleSignIn(
          clientId: const String.fromEnvironment('SOUL_GOOGLE_IOS_CLIENT_ID').trim().isEmpty
              ? null
              : const String.fromEnvironment('SOUL_GOOGLE_IOS_CLIENT_ID'),
          serverClientId: const String.fromEnvironment('SOUL_GOOGLE_SERVER_CLIENT_ID').trim().isEmpty
              ? null
              : const String.fromEnvironment('SOUL_GOOGLE_SERVER_CLIENT_ID'),
        );

  final GoogleSignIn _google;

  Future<GoogleIdentityCredential> google() async {
    final account = await _google.signIn();
    if (account == null) throw const NativeIdentityCancelled();
    final token = (await account.authentication).idToken;
    if (token == null || token.isEmpty) {
      throw StateError('Google did not return an identity token.');
    }
    return GoogleIdentityCredential(token);
  }

  Future<AppleIdentityCredential> apple() async {
    if (kIsWeb || (defaultTargetPlatform != TargetPlatform.iOS &&
        defaultTargetPlatform != TargetPlatform.macOS)) {
      throw UnsupportedError('Apple sign-in is available on supported Apple devices.');
    }
    final rawNonce = _nonce();
    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: const [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
      nonce: sha256.convert(utf8.encode(rawNonce)).toString(),
    );
    final token = credential.identityToken;
    if (token == null || token.isEmpty) {
      throw StateError('Apple did not return an identity token.');
    }
    return AppleIdentityCredential(
      identityToken: token,
      rawNonce: rawNonce,
      givenName: credential.givenName,
      familyName: credential.familyName,
    );
  }

  String _nonce() {
    const alphabet = '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(32, (_) => alphabet[random.nextInt(alphabet.length)]).join();
  }
}
