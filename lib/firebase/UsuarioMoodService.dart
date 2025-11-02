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
}
