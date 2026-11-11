import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'firebase_config.dart';

class AuthUser {
  const AuthUser({required this.id, this.displayName});

  final String id;
  final String? displayName;
}

abstract interface class UserAuthService {
  Stream<AuthUser?> get authStateChanges;

  Future<void> signInWithGoogle();

  Future<void> signOut();

  Future<String?> getIdToken();
}

class AuthServiceException implements Exception {
  const AuthServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}

class FirebaseUserAuthService implements UserAuthService {
  FirebaseUserAuthService({
    FirebaseAuth? auth,
    GoogleSignIn? googleSignIn,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn.instance,
        _googleSignInReady = (googleSignIn ?? GoogleSignIn.instance).initialize(
          serverClientId: PricegentFirebaseConfig.googleServerClientId,
        );

  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;
  final Future<void> _googleSignInReady;

  @override
  Stream<AuthUser?> get authStateChanges => _auth.authStateChanges().map(
        (user) => user == null
            ? null
            : AuthUser(id: user.uid, displayName: user.displayName),
      );

  @override
  Future<void> signInWithGoogle() async {
    try {
      await _googleSignInReady;
      final googleUser = await _googleSignIn.authenticate();
      final idToken = googleUser.authentication.idToken;
      if (idToken == null) {
        throw const AuthServiceException(
          'Google did not return an ID token. Check the Firebase OAuth setup.',
        );
      }

      final credential = GoogleAuthProvider.credential(idToken: idToken);
      await _auth.signInWithCredential(credential);
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) return;
      throw AuthServiceException(
        error.description ?? 'Google sign-in could not be completed.',
      );
    } on FirebaseAuthException catch (error) {
      throw AuthServiceException(
        error.message ?? 'Firebase could not sign you in.',
      );
    } on PlatformException catch (error) {
      throw AuthServiceException(
        error.message ?? 'Google sign-in could not be completed.',
      );
    }
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
  }

  @override
  Future<String?> getIdToken() =>
      _auth.currentUser?.getIdToken() ?? Future<String?>.value();
}
