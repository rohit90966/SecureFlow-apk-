import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'encryption_service.dart';

class FirebaseService with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  User? _currentUser;
  String? _userEmail;
  bool _isLoggedIn = false;

  User? get currentUser => _currentUser;
  String? get userEmail => _userEmail;
  bool get isLoggedIn => _isLoggedIn;

  FirebaseService() {
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  void _onAuthStateChanged(User? user) {
    _currentUser = user;
    _userEmail = user?.email;
    _isLoggedIn = user != null;
    notifyListeners();
  }

  Future<void> checkAuthState() async {
    try {
      _currentUser = _auth.currentUser;
      _userEmail = _currentUser?.email;
      _isLoggedIn = _currentUser != null;
      notifyListeners();
    } catch (e) {
      _isLoggedIn = false;
      notifyListeners();
    }
  }

  Future<void> createBackup(Map<String, dynamic> backupData) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      final encryptedUserId = EncryptionService.encrypt(user.uid);
      final encryptedEmail =
          user.email != null ? EncryptionService.encrypt(user.email!) : null;
      final userKey = EncryptionService.hash(user.uid);

      final completeBackupData = {
        ...backupData,
        'userId_enc': encryptedUserId,
        'email_enc': encryptedEmail,
        'userKey': userKey,
        'backupTimestamp': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'encryptionVersion': 2,
      };

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('backups')
          .doc('latest_backup')
          .set(completeBackupData, SetOptions(merge: true));

      await _firestore.collection('users').doc(user.uid).set({
        'lastBackup': FieldValue.serverTimestamp(),
        'backupPasswordCount': backupData['totalPasswords'] ?? 0,
        'updatedAt': FieldValue.serverTimestamp(),
        'userId_enc': encryptedUserId,
        'email_enc': encryptedEmail,
        'userKey': userKey,
        'encryptionVersion': 2,
      }, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Backup creation failed: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>?> getBackupInfo() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final backupDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('backups')
          .doc('latest_backup')
          .get();

      if (backupDoc.exists) return backupDoc.data();
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>> registerUser(
      String email, String password) async {
    try {
      final UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'email_enc': EncryptionService.encrypt(email),
        'userKey': EncryptionService.hash(userCredential.user!.uid),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'passwordCount': 0,
        'backupEnabled': true,
        'lastBackup': null,
        'backupPasswordCount': 0,
        'encryptionVersion': 2,
      });

      return {
        'success': true,
        'message': 'Registration successful',
        'user': userCredential.user
      };
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Registration failed';
      if (e.code == 'weak-password')
        errorMessage = 'The password provided is too weak.';
      else if (e.code == 'email-already-in-use')
        errorMessage = 'An account already exists for that email.';
      else if (e.code == 'invalid-email')
        errorMessage = 'The email address is not valid.';

      return {'success': false, 'message': errorMessage, 'errorCode': e.code};
    } catch (e) {
      return {
        'success': false,
        'message': 'An unexpected error occurred during registration.'
      };
    }
  }

  Future<Map<String, dynamic>> loginUser(String email, String password) async {
    try {
      final UserCredential userCredential =
          await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final userDoc = await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();
      if (!userDoc.exists) {
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'email_enc': EncryptionService.encrypt(email),
          'userKey': EncryptionService.hash(userCredential.user!.uid),
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'passwordCount': 0,
          'backupEnabled': true,
          'lastBackup': null,
          'backupPasswordCount': 0,
          'encryptionVersion': 2,
        });
      }

      return {
        'success': true,
        'message': 'Login successful',
        'user': userCredential.user
      };
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Login failed';
      if (e.code == 'user-not-found')
        errorMessage = 'No user found for that email.';
      else if (e.code == 'wrong-password')
        errorMessage = 'Wrong password provided for that user.';
      else if (e.code == 'invalid-email')
        errorMessage = 'The email address is not valid.';
      else if (e.code == 'user-disabled')
        errorMessage = 'This user has been disabled.';

      return {'success': false, 'message': errorMessage, 'errorCode': e.code};
    } catch (e) {
      return {
        'success': false,
        'message': 'An unexpected error occurred during login.'
      };
    }
  }

  Future<void> logout() async {
    try {
      await _secureStorage.delete(key: 'user_session');
      await _auth.signOut();
      _currentUser = null;
      _userEmail = null;
      _isLoggedIn = false;
      notifyListeners();
    } catch (e) {
      throw e;
    }
  }

  Future<bool> savePassword(Map<String, dynamic> passwordData) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final documentId = passwordData['documentId'] ??
          passwordData['id'] ??
          DateTime.now().millisecondsSinceEpoch.toString();
      final encryptedUserId = EncryptionService.encrypt(user.uid);
      final userKey = EncryptionService.hash(user.uid);

      final Map<String, dynamic> passwordWithId = {
        ...passwordData,
        'id': documentId,
        'userId_enc': encryptedUserId,
        'userKey': userKey,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'encryptionVersion': 2,
      };

      await _firestore
          .collection('passwords')
          .doc(documentId)
          .set(passwordWithId);
      await _updatePasswordCount(user.uid, 1);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getPasswords() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final userKey = EncryptionService.hash(user.uid);
      var query = _firestore
          .collection('passwords')
          .where('userKey', isEqualTo: userKey)
          .orderBy('createdAt', descending: true);
      var querySnapshot = await query.get();

      if (querySnapshot.docs.isEmpty) {
        query = _firestore
            .collection('passwords')
            .where('userId', isEqualTo: user.uid)
            .orderBy('createdAt', descending: true);
        querySnapshot = await query.get();
      }

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'documentId': doc.id,
          ...data,
          'created_date':
              (data['createdAt'] as Timestamp?)?.toDate().toString() ??
                  DateTime.now().toString(),
          'updated_date':
              (data['updatedAt'] as Timestamp?)?.toDate().toString() ??
                  DateTime.now().toString(),
        };
      }).toList();
    } catch (e) {
      return [];
    }
  }

  Future<bool> updatePassword(
      String passwordId, Map<String, dynamic> updates) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final doc =
          await _firestore.collection('passwords').doc(passwordId).get();
      if (!doc.exists) return false;

      final data = doc.data();
      final userKey = EncryptionService.hash(user.uid);
      if (data == null || data['userKey'] != userKey) return false;

      await _firestore.collection('passwords').doc(passwordId).update({
        ...updates,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deletePassword(String passwordId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final doc =
          await _firestore.collection('passwords').doc(passwordId).get();
      if (!doc.exists) return false;

      final data = doc.data();
      final expectedUserKey = EncryptionService.hash(user.uid);
      final docUserKey = data?['userKey'];
      if (docUserKey != expectedUserKey) return false;

      await _firestore.collection('passwords').doc(passwordId).delete();
      await _updatePasswordCount(user.uid, -1);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> _updatePasswordCount(String userId, int change) async {
    try {
      final userDoc = _firestore.collection('users').doc(userId);
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(userDoc);
        if (snapshot.exists) {
          final data = snapshot.data();
          if (data != null) {
            final currentCount = data['passwordCount'] ?? 0;
            transaction
                .update(userDoc, {'passwordCount': currentCount + change});
          }
        }
      });
    } catch (e) {
      // Silent fail
    }
  }

  String? getCurrentUserId() => _auth.currentUser?.uid;

  Future<bool> verifyCurrentUser() async {
    try {
      await _auth.currentUser?.reload();
      _currentUser = _auth.currentUser;
      _isLoggedIn = _currentUser != null;
      _userEmail = _currentUser?.email;
      notifyListeners();
      return _isLoggedIn;
    } catch (e) {
      _isLoggedIn = false;
      notifyListeners();
      return false;
    }
  }
}
