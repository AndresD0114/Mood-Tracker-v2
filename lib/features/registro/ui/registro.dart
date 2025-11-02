import 'package:flutter/material.dart';

import '../../../firebase/data/auth_datasource.dart';
import '../../../firebase/data/auth_repository.dart';
import '../../../firebase/logic/auth_controller.dart';
import '../../../firebase/UsuarioMoodService.dart';

import '../../login/ui/login.dart';      // Pantalla de login
import '../../../main.dart';            // Para MainNavigation(initialIndex: 0)

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _obscure1 = true;
  bool _obscure2 = true;
  bool _loading = false;

  late final AuthController _authController;
  late final UsuarioMoodService _moodService;

  @override
  void initState() {
    super.initState();
    // Inyección sencilla de dependencias (podés mover esto a Provider/Riverpod)
    final ds = AuthRemoteDataSource();     // usa FirebaseAuth.instance por defecto
    final repo = AuthRepository(ds);
    _authController = AuthController(repo);
    _moodService = UsuarioMoodService(authRepository: repo);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
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

  Future<void> _doRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      // 1) Crear usuario (Auth)
      final res = await _authController.register(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text.trim(),
      );

      if (!mounted) return;

      if (!res.ok || res.user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res.message ?? "❌ No se pudo crear la cuenta."),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
        setState(() => _loading = false);
        return;
      }

      final uid = res.user!.uid;

      // 2) Guardar perfil en Firestore
      await _moodService.guardarPerfilUsuario(
        uid: uid,
        nombre: _nameCtrl.text.trim(),
        apellido: '',
        correo: _emailCtrl.text.trim(),
      );

      // 3) Actualizar displayName (sin que la UI toque FirebaseAuth)
      await _authController.updateDisplayName(_nameCtrl.text.trim());

      // 4) Feedback + navegar a MainNavigation con tab 0
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ Cuenta creada correctamente"),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MainNavigation(initialIndex: 0)),
        (_) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("❌ Error inesperado. Intentá de nuevo."),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
                Icon(Icons.person_add_alt_1, size: 60, color: Colors.white),
                SizedBox(height: 10),
                Text(
                  "Crear cuenta 💚",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  "Registrate para comenzar a usar la app",
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
                      // Nombre
                      TextFormField(
                        controller: _nameCtrl,
                        textCapitalization: TextCapitalization.words,
                        decoration: _inputDecoration(
                          label: "Nombre",
                          icon: Icons.person_outline,
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? "Ingresá tu nombre" : null,
                      ),
                      const SizedBox(height: 14),

                      // Correo
                      TextFormField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: _inputDecoration(
                          label: "Correo institucional",
                          icon: Icons.email_outlined,
                        ),
                        validator: (v) {
                          final value = v?.trim() ?? '';
                          if (value.isEmpty) return "Ingresá tu correo";
                          if (!RegExp(r'^[\w\.\-]+@[\w\.\-]+\.\w+$').hasMatch(value)) {
                            return "Correo no válido";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // Contraseña
                      TextFormField(
                        controller: _passCtrl,
                        obscureText: _obscure1,
                        decoration: _inputDecoration(
                          label: "Contraseña (mín. 6 caracteres)",
                          icon: Icons.lock_outline,
                          suffix: IconButton(
                            onPressed: () => setState(() => _obscure1 = !_obscure1),
                            icon: Icon(
                              _obscure1
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: Colors.green,
                            ),
                          ),
                        ),
                        validator: (v) =>
                            (v ?? '').length < 6 ? "Mínimo 6 caracteres" : null,
                      ),
                      const SizedBox(height: 14),

                      // Confirmación
                      TextFormField(
                        controller: _confirmCtrl,
                        obscureText: _obscure2,
                        decoration: _inputDecoration(
                          label: "Confirmar contraseña",
                          icon: Icons.verified_user_outlined,
                          suffix: IconButton(
                            onPressed: () => setState(() => _obscure2 = !_obscure2),
                            icon: Icon(
                              _obscure2
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: Colors.green,
                            ),
                          ),
                        ),
                        validator: (v) =>
                            v != _passCtrl.text ? "Las contraseñas no coinciden" : null,
                      ),

                      const SizedBox(height: 18),

                      // Botón principal
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _loading ? null : _doRegister,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: _loading ? Colors.grey : Colors.green,
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
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Icon(Icons.check_circle_outline, color: Colors.white),
                          label: Text(
                            _loading ? "Creando cuenta..." : "Registrarme",
                            style: const TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Volver al login
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("¿Ya tenés cuenta? "),
                          TextButton(
                            onPressed: _loading
                                ? null
                                : () {
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const LoginScreen(),
                                      ),
                                    );
                                  },
                            child: const Text(
                              "Iniciar sesión",
                              style: TextStyle(fontWeight: FontWeight.w700),
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
              "Al registrarte aceptás nuestras políticas de uso.",
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
