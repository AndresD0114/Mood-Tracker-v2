import 'package:flutter/material.dart';
import '../../../firebase/data/auth_datasource.dart';
import '../../../firebase/data/auth_repository.dart';
import '../../../firebase/logic/auth_controller.dart';
import '../../../session_manager.dart';
import '../../../main.dart';
import '../../registro/ui/registro.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  late final AuthController _auth;

  bool _obscure = true;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final ds = AuthRemoteDataSource();
    final repo = AuthRepository(ds);
    _auth = AuthController(repo);
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.green),
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade300, width: 2),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(14)),
        borderSide: BorderSide(color: Colors.green, width: 2),
      ),
      errorBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(14)),
        borderSide: BorderSide(color: Colors.red, width: 2),
      ),
      focusedErrorBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(14)),
        borderSide: BorderSide(color: Colors.red, width: 2),
      ),
    );
  }

  Future<void> _doLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    final res = await _auth.login(
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text,
    );

    if (!mounted) return;

    if (res.ok && res.user != null) {
      await SessionManager.saveSession(res.user!.uid, res.user!.email ?? '');
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(res.message ?? (res.ok ? "✅ Sesión iniciada" : "❌ Error")),
        backgroundColor: res.ok ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );

    if (res.ok) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainNavigation(initialIndex: 0)),
      );
    }

    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Column(
        children: [
          // 🌈 Banner superior
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 60, bottom: 30),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green, Colors.lightGreen],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(25)),
            ),
            child: const Column(
              children: [
                Icon(Icons.lock_outline, size: 60, color: Colors.white),
                SizedBox(height: 10),
                Text(
                  "Inicia sesión 💚",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  "Accede para registrar tu estado de ánimo",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),

          // 📄 Tarjeta con formulario
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 12,
                      offset: Offset(0, 6),
                    ),
                  ],
                  border: Border.all(color: Colors.grey, width: 0.2),
                ),
                padding: const EdgeInsets.all(18),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Correo
                      TextFormField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: _inputDecoration(
                          label: "Correo",
                          icon: Icons.email_outlined,
                        ),
                        validator: (v) {
                          final value = v?.trim() ?? '';
                          if (value.isEmpty) return "Ingresa tu correo";
                          if (!RegExp(r"^[\w\.\-]+@[\w\.\-]+\.\w+$").hasMatch(value)) {
                            return "Correo no válido";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // Contraseña
                      TextFormField(
                        controller: _passCtrl,
                        obscureText: _obscure,
                        decoration: _inputDecoration(
                          label: "Contraseña",
                          icon: Icons.lock_outline,
                          suffix: IconButton(
                            onPressed: () => setState(() => _obscure = !_obscure),
                            icon: Icon(
                              _obscure
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: Colors.green,
                            ),
                          ),
                        ),
                        validator: (v) {
                          if ((v ?? '').length < 6) {
                            return "Mínimo 6 caracteres";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 18),

                      // 🟩 Botón principal
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _loading ? null : _doLogin,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor:
                                _loading ? Colors.grey : Colors.green,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            elevation: 5,
                          ),
                          icon: _loading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                    valueColor:
                                        AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Icon(Icons.login, color: Colors.white),
                          label: Text(
                            _loading ? "Ingresando..." : "Ingresar",
                            style: const TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),

                      // 👇 NUEVO BLOQUE: enlace a registro
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("¿No tienes cuenta? "),
                          TextButton(
                            onPressed: _loading
                                ? null
                                : () {
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const RegisterScreen(),
                                      ),
                                    );
                                  },
                            child: const Text(
                              "Regístrate aquí 💚",
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Colors.green,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 📝 Aviso legal
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              "Al continuar aceptás nuestras políticas de uso.",
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
