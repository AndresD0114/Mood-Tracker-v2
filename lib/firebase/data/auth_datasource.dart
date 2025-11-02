import 'package:firebase_auth/firebase_auth.dart';

/// Fuente de datos remota para autenticación.
/// ÚNICO lugar que toca directamente FirebaseAuth.
class AuthRemoteDataSource {
  final FirebaseAuth _fa;

  AuthRemoteDataSource({FirebaseAuth? firebaseAuth})
      : _fa = firebaseAuth ?? FirebaseAuth.instance;

  Future<User?> signIn({required String email, required String password}) async {
    final cred = await _fa.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return cred.user;
  }

  Future<User?> signUp({required String email, required String password}) async {
    final cred = await _fa.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    return cred.user;
  }

  Future<void> signOut() => _fa.signOut();

  Future<void> updateDisplayName(String name) async {
    final u = _fa.currentUser;
    if (u != null) await u.updateDisplayName(name);
  }

  User? get currentUser => _fa.currentUser;
}
