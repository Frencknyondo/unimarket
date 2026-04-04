import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_model.dart';

class AuthService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _usersCollection = 'unimarket_db';
  static const Duration _requestTimeout = Duration(seconds: 15);
  static const String _adminDocId = 'system_admin';
  static const String _adminEmail = 'admin@example.com';
  static const String _adminPassword = 'Admin Admin';

  Stream<List<User>> usersStream() {
    return _firestore
        .collection(_usersCollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => User.fromMap(doc.data()))
              .toList(),
        );
  }

  Future<void> ensureAdminAccount() async {
    try {
      final adminDoc = _firestore.collection(_usersCollection).doc(_adminDocId);
      final snapshot = await adminDoc.get().timeout(_requestTimeout);

      if (snapshot.exists) {
        final existingData = snapshot.data() ?? <String, dynamic>{};
        if (existingData['role'] == 'admin') {
          return;
        }
      }

      final adminUser = User(
        uid: _adminDocId,
        registrationNo: 'ADMIN-001',
        email: _adminEmail,
        fullName: 'System Admin',
        password: _adminPassword,
        role: 'admin',
        createdAt: DateTime.now(),
      );

      await adminDoc.set(adminUser.toMap()).timeout(_requestTimeout);
    } catch (_) {
      // Keep startup resilient; sign-in will show a clear message if database access fails.
    }
  }

  Future<Map<String, dynamic>> signUp({
    required String registrationNo,
    required String email,
    required String fullName,
    required String password,
  }) async {
    try {
      final normalizedRegistrationNo = registrationNo.trim().toUpperCase();
      final normalizedEmail = email.trim().toLowerCase();

      final existingRegistrationNo = await _firestore
          .collection(_usersCollection)
          .where('registrationNo', isEqualTo: normalizedRegistrationNo)
          .limit(1)
          .get()
          .timeout(_requestTimeout);

      if (existingRegistrationNo.docs.isNotEmpty) {
        return {
          'success': false,
          'message': 'Registration number already registered',
        };
      }

      final existingEmail = await _firestore
          .collection(_usersCollection)
          .where('email', isEqualTo: normalizedEmail)
          .limit(1)
          .get()
          .timeout(_requestTimeout);

      if (existingEmail.docs.isNotEmpty) {
        return {
          'success': false,
          'message': 'Email already registered',
        };
      }

      final userId = _firestore.collection(_usersCollection).doc().id;
      final user = User(
        uid: userId,
        registrationNo: normalizedRegistrationNo,
        email: normalizedEmail,
        fullName: fullName.trim(),
        password: password,
        role: 'student',
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .set(user.toMap())
          .timeout(_requestTimeout);

      return {
        'success': true,
        'message': 'Account created successfully',
        'user': user,
      };
    } on TimeoutException {
      return {
        'success': false,
        'message':
            'Request timed out. Check internet connection or Firestore rules.',
      };
    } on FirebaseException catch (e) {
      return {
        'success': false,
        'message': e.message ?? 'Firebase error occurred',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: ${e.toString()}',
      };
    }
  }

  Future<Map<String, dynamic>> createManagedUser({
    required String registrationNo,
    required String email,
    required String fullName,
    required String password,
    required String role,
  }) async {
    try {
      final normalizedRegistrationNo = registrationNo.trim().toUpperCase();
      final normalizedEmail = email.trim().toLowerCase();
      final normalizedRole = role.trim().toLowerCase();

      final existingRegistrationNo = await _firestore
          .collection(_usersCollection)
          .where('registrationNo', isEqualTo: normalizedRegistrationNo)
          .limit(1)
          .get()
          .timeout(_requestTimeout);

      if (existingRegistrationNo.docs.isNotEmpty) {
        return {
          'success': false,
          'message': 'Registration number already registered',
        };
      }

      final existingEmail = await _firestore
          .collection(_usersCollection)
          .where('email', isEqualTo: normalizedEmail)
          .limit(1)
          .get()
          .timeout(_requestTimeout);

      if (existingEmail.docs.isNotEmpty) {
        return {
          'success': false,
          'message': 'Email already registered',
        };
      }

      final userId = _firestore.collection(_usersCollection).doc().id;
      final user = User(
        uid: userId,
        registrationNo: normalizedRegistrationNo,
        email: normalizedEmail,
        fullName: fullName.trim(),
        password: password,
        role: normalizedRole,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .set(user.toMap())
          .timeout(_requestTimeout);

      return {
        'success': true,
        'message': 'Account saved successfully',
        'user': user,
      };
    } on TimeoutException {
      return {
        'success': false,
        'message':
            'Request timed out. Check internet connection or Firestore rules.',
      };
    } on FirebaseException catch (e) {
      return {
        'success': false,
        'message': e.message ?? 'Firebase error occurred',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: ${e.toString()}',
      };
    }
  }

  Future<Map<String, dynamic>> updateManagedUser({
    required String userId,
    required String registrationNo,
    required String email,
    required String fullName,
    required String password,
    required String role,
  }) async {
    try {
      final normalizedRegistrationNo = registrationNo.trim().toUpperCase();
      final normalizedEmail = email.trim().toLowerCase();
      final normalizedRole = role.trim().toLowerCase();

      final registrationMatches = await _firestore
          .collection(_usersCollection)
          .where('registrationNo', isEqualTo: normalizedRegistrationNo)
          .limit(2)
          .get()
          .timeout(_requestTimeout);

      final conflictingRegistration = registrationMatches.docs.any(
        (doc) => doc.id != userId,
      );

      if (conflictingRegistration) {
        return {
          'success': false,
          'message': 'Registration number already registered',
        };
      }

      final emailMatches = await _firestore
          .collection(_usersCollection)
          .where('email', isEqualTo: normalizedEmail)
          .limit(2)
          .get()
          .timeout(_requestTimeout);

      final conflictingEmail = emailMatches.docs.any((doc) => doc.id != userId);

      if (conflictingEmail) {
        return {
          'success': false,
          'message': 'Email already registered',
        };
      }

      final docRef = _firestore.collection(_usersCollection).doc(userId);
      final snapshot = await docRef.get().timeout(_requestTimeout);
      final existing = snapshot.data() ?? <String, dynamic>{};

      await docRef.update({
        'registrationNo': normalizedRegistrationNo,
        'email': normalizedEmail,
        'fullName': fullName.trim(),
        'password': password,
        'role': normalizedRole,
        'createdAt':
            existing['createdAt'] ?? DateTime.now().toIso8601String(),
      }).timeout(_requestTimeout);

      return {
        'success': true,
        'message': 'Account updated successfully',
      };
    } on TimeoutException {
      return {
        'success': false,
        'message':
            'Request timed out. Check internet connection or Firestore rules.',
      };
    } on FirebaseException catch (e) {
      return {
        'success': false,
        'message': e.message ?? 'Firebase error occurred',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: ${e.toString()}',
      };
    }
  }

  Future<Map<String, dynamic>> deleteManagedUser(String userId) async {
    try {
      if (userId == _adminDocId) {
        return {
          'success': false,
          'message': 'Default admin account cannot be deleted',
        };
      }

      await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .delete()
          .timeout(_requestTimeout);

      return {
        'success': true,
        'message': 'Account deleted successfully',
      };
    } on TimeoutException {
      return {
        'success': false,
        'message':
            'Request timed out. Check internet connection or Firestore rules.',
      };
    } on FirebaseException catch (e) {
      return {
        'success': false,
        'message': e.message ?? 'Firebase error occurred',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: ${e.toString()}',
      };
    }
  }

  Future<Map<String, dynamic>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final normalizedEmail = email.trim().toLowerCase();

      final querySnapshot = await _firestore
          .collection(_usersCollection)
          .where('email', isEqualTo: normalizedEmail)
          .limit(1)
          .get()
          .timeout(_requestTimeout);

      if (querySnapshot.docs.isEmpty) {
        return {
          'success': false,
          'message': 'Account not found',
        };
      }

      final user = User.fromMap(querySnapshot.docs.first.data());

      if (user.password != password) {
        return {
          'success': false,
          'message': 'Incorrect password',
        };
      }

      return {
        'success': true,
        'message': 'Sign in successful',
        'user': user,
      };
    } on TimeoutException {
      return {
        'success': false,
        'message':
            'Request timed out. Check internet connection or Firestore rules.',
      };
    } on FirebaseException catch (e) {
      return {
        'success': false,
        'message': e.message ?? 'Firebase error occurred',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: ${e.toString()}',
      };
    }
  }

  Future<User?> getUserByEmail(String email) async {
    try {
      final normalizedEmail = email.trim().toLowerCase();
      final querySnapshot = await _firestore
          .collection(_usersCollection)
          .where('email', isEqualTo: normalizedEmail)
          .limit(1)
          .get()
          .timeout(_requestTimeout);

      if (querySnapshot.docs.isEmpty) {
        return null;
      }

      return User.fromMap(querySnapshot.docs.first.data());
    } catch (_) {
      return null;
    }
  }
}
