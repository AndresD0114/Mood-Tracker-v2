import 'package:cloud_firestore/cloud_firestore.dart';
import 'data/auth_repository.dart';

/// Servicio de dominio para estados de ánimo (Firestore).
class UsuarioMoodService {
  final AuthRepository _authRepo;
  final FirebaseFirestore _db;

  UsuarioMoodService({
    required AuthRepository authRepository,
    FirebaseFirestore? firestore,
  })  : _authRepo = authRepository,
        _db = firestore ?? FirebaseFirestore.instance;

  /// Crea/actualiza el perfil base del usuario en `usuarios/{uid}`.
  Future<void> guardarPerfilUsuario({
    required String uid,
    required String nombre,
    required String apellido,
    required String correo,
  }) async {
    await _db.collection('usuarios').doc(uid).set({
      'uid': uid,
      'nombre': nombre,
      'apellido': apellido,
      'correo': correo,
      'fecha_creacion': FieldValue.serverTimestamp(),
      'fecha_actualizacion': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// ✅ Upsert por fecha: docId = dateKey "yyyy-MM-dd"
  /// Campos mínimos:
  /// - estado: String ("Feliz", "Triste", etc.)
  /// - createdAt/updatedAt: server timestamps
  /// - fechaCliente: ISO local del dispositivo (referencia para UI)
  /// Extra opcional: p.ej. {'nota': '...'}
  Future<void> upsertEstadoPorFecha({
    required String dateKey,
    required String estado,
    DateTime? fechaLocal,
    Map<String, dynamic>? extra,
  }) async {
    final uid = _authRepo.currentUid();
    if (uid == null) {
      throw StateError('No hay usuario autenticado.');
    }

    final userDoc = _db.collection('usuarios').doc(uid);
    final estadoDoc = userDoc.collection('estados').doc(dateKey);

    // Asegura doc de usuario
    await userDoc.set({
      'uid': uid,
      'fecha_actualizacion': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await _db.runTransaction((tx) async {
      final snap = await tx.get(estadoDoc);
      final nowLocal = fechaLocal ?? DateTime.now();

      final base = <String, dynamic>{
        'uid': uid,
        'estado': estado,
        'fechaCliente': nowLocal.toIso8601String(),
        'updatedAt': FieldValue.serverTimestamp(),
        if (extra != null) ...extra,
      };

      if (snap.exists) {
        final existing = snap.data() as Map<String, dynamic>? ?? {};
        final createdAt = existing['createdAt'];
        final toWrite = {
          if (createdAt != null) 'createdAt': createdAt,
          ...base,
        };
        tx.set(estadoDoc, toWrite, SetOptions(merge: true));
      } else {
        tx.set(estadoDoc, {
          'createdAt': FieldValue.serverTimestamp(),
          ...base,
        });
      }
    });
  }

  /// 🔎 Trae el estado de un día específico por dateKey (yyyy-MM-dd).
  /// Retorna {"estado": "...", "nota": "..."} o null si no existe.
  Future<Map<String, dynamic>?> getEstadoPorFecha(String dateKey) async {
    final uid = _authRepo.currentUid();
    if (uid == null) return null;

    final docRef = _db
        .collection('usuarios')
        .doc(uid)
        .collection('estados')
        .doc(dateKey);

    final snap = await docRef.get();
    if (!snap.exists) return null;

    final data = snap.data();
    if (data == null) return null;

    final estado = data['estado']?.toString();
    if (estado == null) return null;

    final nota = data['nota']?.toString();
    return {
      'estado': estado,
      if (nota != null) 'nota': nota,
    };
  }

  /// 📥 Útil para el calendario: retorna { "yyyy-MM-dd": "Feliz" }
  /// Si tenés registros históricos con autoId, intenta derivar el dateKey desde 'fechaCliente'.
  Future<Map<String, String>> fetchEstadosComoMapa() async {
    final uid = _authRepo.currentUid();
    if (uid == null) return {};

    final col = _db.collection('usuarios').doc(uid).collection('estados');
    final qs = await col.get();

    final Map<String, String> result = {};
    for (final doc in qs.docs) {
      final data = doc.data();
      final estado = data['estado']?.toString();
      if (estado == null) continue;

      // Por convención nueva: doc.id es yyyy-MM-dd
      String dateKey = doc.id;

      // Fallback: si no cumple formato, derivar desde fechaCliente (yyyy-MM-ddTHH:mm:ss)
      if (!_isDateKey(dateKey)) {
        final fechaCliente = data['fechaCliente']?.toString();
        if (fechaCliente != null && fechaCliente.length >= 10) {
          dateKey = fechaCliente.substring(0, 10);
        } else {
          continue; // no se puede mapear de forma segura
        }
      }

      result[dateKey] = estado;
    }

    return result;
  }

  /// Stream del historial de estados (descendente por createdAt)
  Stream<QuerySnapshot<Map<String, dynamic>>> estadosStream({
    String? uid,
    int? limit,
  }) {
    final effectiveUid = uid ?? _authRepo.currentUid();
    if (effectiveUid == null) {
      return const Stream<QuerySnapshot<Map<String, dynamic>>>.empty();
    }

    Query<Map<String, dynamic>> q = _db
        .collection('usuarios')
        .doc(effectiveUid)
        .collection('estados')
        .orderBy('createdAt', descending: true);

    if (limit != null) q = q.limit(limit);
    return q.snapshots(includeMetadataChanges: true);
  }

  /// Elimina un estado por ID (dateKey si usás la convención nueva).
  Future<void> eliminarEstado(String estadoId, {String? uid}) async {
    final effectiveUid = uid ?? _authRepo.currentUid();
    if (effectiveUid == null) return;

    await _db
        .collection('usuarios')
        .doc(effectiveUid)
        .collection('estados')
        .doc(estadoId)
        .delete();
  }

  String? get uidActual => _authRepo.currentUid();

  // --- Helpers ---

  bool _isDateKey(String s) {
    // formato yyyy-MM-dd
    final reg = RegExp(r'^\d{4}-\d{2}-\d{2}$');
    return reg.hasMatch(s);
  }
}
