import '../data/auth_repository.dart';

class AuthController {
  final AuthRepository _repo;

  AuthController(this._repo);

  Future<AuthResult> login({
    required String email,
    required String password,
  }) =>
      _repo.signIn(email, password);

  Future<AuthResult> register({
    required String email,
    required String password,
  }) =>
      _repo.signUp(email, password);

  Future<void> logout() => _repo.signOut();
  String? uid() => _repo.currentUid();
  Future<void> updateDisplayName(String name) => _repo.updateDisplayName(name);
}
