  import 'package:firebase_auth/firebase_auth.dart';
  import 'auth_datasource.dart';

  /// Resultado tipado para capas superiores.
  class AuthResult {
    final bool ok;
    final String? message;
    final User? user;

    const AuthResult({required this.ok, this.message, this.user});

    factory AuthResult.success(User u, {String? msg}) =>
        AuthResult(ok: true, user: u, message: msg ?? "✅ Sesión iniciada correctamente");

    factory AuthResult.failure(String msg) => AuthResult(ok: false, message: msg);
  }

  class AuthRepository {
    final AuthRemoteDataSource _remote;

    AuthRepository(this._remote);

    Future<AuthResult> signIn(String email, String password) async {
      try {
        final u = await _remote.signIn(email: email.trim(), password: password);
        if (u == null) return AuthResult.failure("No se pudo iniciar sesión.");
        return AuthResult.success(u);
      } on FirebaseAuthException catch (e) {
        return AuthResult.failure(_map(e.code));
      } catch (_) {
        return AuthResult.failure("❌ Error inesperado. Revisá tu conexión.");
      }
    }

    Future<AuthResult> signUp(String email, String password) async {
      try {
        final u = await _remote.signUp(email: email.trim(), password: password);
        if (u == null) return AuthResult.failure("No se pudo crear la cuenta.");
        return AuthResult.success(u, msg: "✅ Cuenta creada");
      } on FirebaseAuthException catch (e) {
        return AuthResult.failure(_map(e.code));
      } catch (_) {
        return AuthResult.failure("❌ Error inesperado. Revisá tu conexión.");
      }
    }

    Future<void> signOut() => _remote.signOut();
    String? currentUid() => _remote.currentUser?.uid;
    Future<void> updateDisplayName(String name) => _remote.updateDisplayName(name);

    String _map(String code) {
      switch (code) {
        case 'user-not-found': return "❌ No existe una cuenta con ese correo.";
        case 'wrong-password': return "❌ Contraseña incorrecta.";
        case 'invalid-email': return "❌ Correo inválido.";
        case 'too-many-requests': return "❌ Demasiados intentos. Intenta más tarde.";
        case 'email-already-in-use': return "❌ Ese correo ya está en uso.";
        case 'weak-password': return "❌ La contraseña es muy débil.";
        default: return "❌ Error al autenticar ($code).";
      }
    }
  }
