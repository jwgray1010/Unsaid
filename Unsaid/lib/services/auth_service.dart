import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
// TODO: Re-enable when google_sign_in is added back to pubspec.yaml
// import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

/// Authentication service for managing user authentication
/// Supports anonymous authentication for beta testing and optional email/password
class AuthService extends ChangeNotifier {
  static AuthService? _instance;
  static AuthService get instance => _instance ??= AuthService._();
  AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  // TODO: Re-enable when google_sign_in is added back to pubspec.yaml
  /*
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: kIsWeb ? '831572355430-213f5564649c8b135240a7.apps.googleusercontent.com' : null,
  );
  */
  User? _user;

  /// Current authenticated user
  User? get user => _user;

  /// Whether user is authenticated
  bool get isAuthenticated => _user != null;

  /// Whether user is anonymous
  bool get isAnonymous => _user?.isAnonymous ?? false;

  /// Initialize Firebase and listen to auth state changes
  Future<void> initialize() async {
    try {
      await Firebase.initializeApp();

      // Listen to authentication state changes
      _auth.authStateChanges().listen((User? user) {
        _user = user;
        notifyListeners();

        if (kDebugMode) {
          if (user != null) {
            print(
              'User authenticated: ${user.uid} (anonymous: ${user.isAnonymous})',
            );
          } else {
            print(' User signed out');
          }
        }
      });

      // Check if user is already signed in
      _user = _auth.currentUser;

      if (kDebugMode) {
        print(
          '🔐 AuthService initialized. Current user: ${_user?.uid ?? 'None'}',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print(' Error initializing AuthService: $e');
      }
      rethrow;
    }
  }

  /// Sign in with Google
  /// TODO: Re-enable when google_sign_in is added back to pubspec.yaml
  Future<UserCredential?> signInWithGoogle() async {
    if (kDebugMode) {
      print(
          '⚠️ Google Sign-In temporarily disabled - google_sign_in package not available');
    }
    return null;

    /* TODO: Re-enable when google_sign_in is added back
    try {
      if (kIsWeb) {
        // Web-specific Google Sign-In implementation
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        
        // Use Firebase's built-in popup for web
        final UserCredential result = await _auth.signInWithPopup(googleProvider);
        _user = result.user;

        if (kDebugMode) {
          print(' Google sign-in successful (web): ${_user?.uid}');
          print('   User: ${_user?.displayName} (${_user?.email})');
        }

        return result;
      } else {
        // Mobile implementation
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
        
        if (googleUser == null) {
          // User canceled the sign-in
          if (kDebugMode) {
            print(' Google sign-in canceled by user');
          }
          return null;
        }

        // Obtain the auth details from the request
        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

        // Create a new credential
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        // Sign in to Firebase with the Google credential
        final UserCredential result = await _auth.signInWithCredential(credential);
        _user = result.user;

        if (kDebugMode) {
          print(' Google sign-in successful (mobile): ${_user?.uid}');
          print('   User: ${_user?.displayName} (${_user?.email})');
        }

        return result;
      }
    } catch (e) {
      if (kDebugMode) {
        print(' Google sign-in failed: $e');
      }
      return null;
    }
    */
  }

  /// Sign in with Apple
  Future<UserCredential?> signInWithApple() async {
    try {
      // Check if Apple Sign In is available on this device
      if (!await SignInWithApple.isAvailable()) {
        if (kDebugMode) {
          print(' Apple Sign In not available on this device');
        }
        return null;
      }

      // Request credential for the currently signed in Apple account
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      // Create an `OAuthCredential` from the credential returned by Apple
      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      // Sign in to Firebase with the Apple credential
      final UserCredential result =
          await _auth.signInWithCredential(oauthCredential);
      _user = result.user;

      // Update display name if available and not already set
      if (_user != null &&
          (_user!.displayName == null || _user!.displayName!.isEmpty) &&
          appleCredential.givenName != null) {
        final displayName =
            '${appleCredential.givenName} ${appleCredential.familyName ?? ''}'
                .trim();
        await _user!.updateDisplayName(displayName);
        await _user!.reload();
        _user = _auth.currentUser;
      }

      if (kDebugMode) {
        print(' Apple sign-in successful: ${_user?.uid}');
        print('   User: ${_user?.displayName} (${_user?.email})');
      }

      return result;
    } on SignInWithAppleAuthorizationException catch (e) {
      if (kDebugMode) {
        print(' Apple sign-in authorization failed: ${e.code} - ${e.message}');
      }
      return null;
    } on TypeError catch (e) {
      if (kDebugMode) {
        print(' Apple sign-in type error (plugin compatibility issue): $e');
        print(' This may be due to a plugin version compatibility issue');
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print(' Apple sign-in failed: $e');
      }
      return null;
    }
  }

  /// Sign in anonymously for beta testing
  Future<UserCredential?> signInAnonymously() async {
    try {
      final UserCredential result = await _auth.signInAnonymously();
      _user = result.user;

      if (kDebugMode) {
        print(' Anonymous sign-in successful: ${_user?.uid}');
      }

      return result;
    } catch (e) {
      if (kDebugMode) {
        print(' Anonymous sign-in failed: $e');
      }
      return null;
    }
  }

  /// Sign in with email and password
  Future<UserCredential?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      _user = result.user;

      if (kDebugMode) {
        print(' Email sign-in successful: ${_user?.uid}');
      }

      return result;
    } catch (e) {
      if (kDebugMode) {
        print(' Email sign-in failed: $e');
      }
      return null;
    }
  }

  /// Create account with email and password
  Future<UserCredential?> createUserWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      _user = result.user;

      if (kDebugMode) {
        print(' Account created successfully: ${_user?.uid}');
      }

      return result;
    } catch (e) {
      if (kDebugMode) {
        print(' Account creation failed: $e');
      }
      return null;
    }
  }

  /// Convert anonymous account to permanent account
  Future<UserCredential?> linkAnonymousWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      if (_user == null || !_user!.isAnonymous) {
        if (kDebugMode) {
          print(' Cannot link: user is not anonymous');
        }
        return null;
      }

      final credential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );
      final UserCredential result = await _user!.linkWithCredential(credential);
      _user = result.user;

      if (kDebugMode) {
        print(' Anonymous account linked successfully: ${_user?.uid}');
      }

      return result;
    } catch (e) {
      if (kDebugMode) {
        print(' Account linking failed: $e');
      }
      return null;
    }
  }

  /// Send password reset email
  Future<bool> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);

      if (kDebugMode) {
        print(' Password reset email sent to: $email');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print(' Password reset failed: $e');
      }
      return false;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      // TODO: Re-enable when google_sign_in is added back
      /*
      // Sign out from Google if signed in
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }
      */

      // Sign out from Firebase
      await _auth.signOut();
      _user = null;

      if (kDebugMode) {
        print(' User signed out successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print(' Sign out failed: $e');
      }
    }
  }

  /// Delete user account
  Future<bool> deleteAccount() async {
    try {
      if (_user == null) return false;

      await _user!.delete();
      _user = null;

      if (kDebugMode) {
        print(' Account deleted successfully');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print(' Account deletion failed: $e');
      }
      return false;
    }
  }

  /// Get ID token for backend communication
  Future<String?> getIdToken() async {
    try {
      if (_user == null) return null;
      return await _user!.getIdToken();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to get ID token: $e');
      }
      return null;
    }
  }

  /// Refresh ID token
  Future<String?> refreshIdToken() async {
    try {
      if (_user == null) return null;
      return await _user!.getIdToken(true);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to refresh ID token: $e');
      }
      return null;
    }
  }

  /// Get current user info
  Map<String, dynamic> getUserInfo() {
    if (_user == null) return {};

    // Determine the sign-in provider
    String provider = 'unknown';
    if (_user!.isAnonymous) {
      provider = 'anonymous';
    } else if (_user!.providerData.isNotEmpty) {
      final providerId = _user!.providerData.first.providerId;
      switch (providerId) {
        case 'google.com':
          provider = 'google';
          break;
        case 'apple.com':
          provider = 'apple';
          break;
        case 'password':
          provider = 'email';
          break;
        default:
          provider = providerId;
      }
    }

    return {
      'uid': _user!.uid,
      'email': _user!.email,
      'displayName': _user!.displayName,
      'photoURL': _user!.photoURL,
      'isAnonymous': _user!.isAnonymous,
      'provider': provider,
      'creationTime': _user!.metadata.creationTime?.toIso8601String(),
      'lastSignInTime': _user!.metadata.lastSignInTime?.toIso8601String(),
      'emailVerified': _user!.emailVerified,
    };
  }
}
