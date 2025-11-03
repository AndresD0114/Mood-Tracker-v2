import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../firebase/data/auth_repository.dart';

/// Lee los estados remotos del usuario autenticado y los mapea a {dateKey: estado}
class CalendarRemoteData {
  final AuthRepository _authRepo;
  final FirebaseFirestore _db;

  CalendarRemoteData({
    required AuthRepository authRepository,
    FirebaseFirestore? firestore,
  })  : _authRepo = authRepository,
        _db = firestore ?? FirebaseFirestore.instance;

  /// Retorna { "yyyy-MM-dd": "Feliz" }
  Future<Map<String, String>> fetchRemoteMoods() async {
    final uid = _authRepo.currentUid();
    if (uid == null) return {};

    final col = _db.collection('usuarios').doc(uid).collection('estados');

    final qs = await col.get();
    final Map<String, String> result = {};

    for (final doc in qs.docs) {
      final data = doc.data();
      final estado = data['estado']?.toString();
      if (estado == null) continue;

      // si usamos la convención nueva: doc.id == dateKey (yyyy-MM-dd)
      String dateKey = doc.id;

      // fallback para históricos (autoId): derivar desde fechaCliente (yyyy-MM-ddTHH:mm:ss)
      if (!_isDateKey(dateKey)) {
        final fechaCliente = data['fechaCliente']?.toString();
        if (fechaCliente != null && fechaCliente.length >= 10) {
          dateKey = fechaCliente.substring(0, 10);
        } else {
          // si no hay forma de derivar, ignoramos
          continue;
        }
      }

      result[dateKey] = estado;
    }

    return result;
  }

  bool _isDateKey(String s) {
    // formato simple yyyy-MM-dd
    final reg = RegExp(r'^\d{4}-\d{2}-\d{2}$');
    return reg.hasMatch(s);
  }
}
