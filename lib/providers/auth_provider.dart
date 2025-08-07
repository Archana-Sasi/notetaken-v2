import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'profile',
    ],
    clientId: '290531614395-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx.apps.googleusercontent.com', // Add your client ID here
  );
  User? _user;

  User? get user => _user;

  AuthProvider() {
    _initAuthListener();
  }

  void _initAuthListener() {
    _auth.authStateChanges().listen((User? user) {
      _user = user;
      notifyListeners();
    });
  }

  // Google Sign-In
  Future<String?> signInWithGoogle() async {
    try {
      print("Starting Google Sign-In process...");
      
      // First, ensure any existing Google Sign-In is cleared
      await _googleSignIn.signOut();
      print("Cleared existing Google Sign-In");
      
      // Trigger the Google Sign-In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      print("Google Sign-In result: ${googleUser?.email ?? 'null'}");
      
      if (googleUser == null) {
        print("Google Sign-In was canceled by user");
        return "Google Sign-In was canceled";
      }

      try {
        // Get the authentication details
        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        print("Got Google authentication tokens");
        
        if (googleAuth.accessToken == null || googleAuth.idToken == null) {
          print("Failed to get Google authentication tokens");
          return "Failed to get Google authentication tokens";
        }

        // Create a new credential
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        print("Created Firebase credential");

        // Sign in to Firebase with the Google credential
        final UserCredential userCredential = await _auth.signInWithCredential(credential);
        print("Firebase sign-in result: ${userCredential.user?.email ?? 'null'}");
        
        if (userCredential.user == null) {
          print("Failed to sign in with Google - no user returned");
          return "Failed to sign in with Google";
        }

        // Update the user state
        _user = userCredential.user;
        notifyListeners();
        print("Successfully signed in with Google");
        
        return null; // Success
      } catch (e) {
        print("Error during Google authentication: $e");
        await _googleSignIn.signOut();
        if (e is FirebaseAuthException) {
          print("Firebase Auth Exception: ${e.code} - ${e.message}");
          switch (e.code) {
            case 'account-exists-with-different-credential':
              return 'An account already exists with the same email address but different sign-in credentials.';
            case 'invalid-credential':
              return 'The credential is invalid or has expired.';
            case 'operation-not-allowed':
              return 'Google Sign-In is not enabled. Please contact support.';
            case 'user-disabled':
              return 'This user account has been disabled.';
            case 'user-not-found':
              return 'No user found with this email.';
            case 'wrong-password':
              return 'Invalid password.';
            case 'invalid-verification-code':
              return 'Invalid verification code.';
            case 'invalid-verification-id':
              return 'Invalid verification ID.';
            default:
              return 'An error occurred during Google Sign-In: ${e.message}';
          }
        }
        return "Error during Google authentication: ${e.toString()}";
      }
    } catch (e) {
      print("Error during Google Sign-In: $e");
      return "Error during Google Sign-In: ${e.toString()}";
    }
  }

  // Email & Password Signup
  Future<String?> signUpWithEmail(String email, String password) async {
    try {
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      _user = credential.user;
      notifyListeners();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  // Email & Password Sign-in
  Future<String?> signInWithEmail(String email, String password) async {
    try {
      UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      _user = credential.user;
      notifyListeners();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  // Sign Out
  Future<void> signOut() async {
    try {
      // First sign out from Firebase
      await _auth.signOut();
      
      // Then sign out from Google
      if (await _googleSignIn.isSignedIn()) {
        await Future.wait([
          _googleSignIn.signOut(),
          _googleSignIn.disconnect(),
        ]);
      }
      
      // Clear the user state
      _user = null;
      notifyListeners();
    } catch (e) {
      print("Error during sign out: ${e.toString()}");
      rethrow;
    }
  }

  // Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }
}
