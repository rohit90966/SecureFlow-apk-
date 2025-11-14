import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'encryption_service.dart';

class FirebaseService with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

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
      print('───────────────────────────────────────────────');
      print('🔥 FIREBASE: createBackup() START');
      print('───────────────────────────────────────────────');

      print('1️⃣ Checking current user...');
      final user = _auth.currentUser;
      if (user == null) {
        print('❌ No current user in Firebase Auth');
        throw Exception('User not logged in');
      }
      print('✅ Current user: ${user.uid}');
      print('   Email: ${user.email}');

      print('2️⃣ Preparing complete backup data...');
      // Encrypt sensitive identifiers and provide hash for querying
      final encryptedUserId = EncryptionService.encrypt(user.uid);
      final encryptedEmail =
          user.email != null ? EncryptionService.encrypt(user.email!) : null;
      final userKey = EncryptionService.hash(user.uid);

      // Ensure backup data has all required fields (encrypted variants)
      final completeBackupData = {
        ...backupData,
        'userId_enc': encryptedUserId,
        'email_enc': encryptedEmail,
        'userKey': userKey,
        'backupTimestamp': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'encryptionVersion': 2,
      };

      print('📦 Backup data keys: ${completeBackupData.keys.toList()}');
      print('📊 Password count in backup: ${backupData['totalPasswords']}');
      if (backupData['passwords'] != null) {
        final pwds = backupData['passwords'] as List;
        print('📝 Passwords array length: ${pwds.length}');
        if (pwds.isNotEmpty) {
          print('   First password keys: ${(pwds[0] as Map).keys.toList()}');
        }
      }

      print('3️⃣ Writing to Firestore...');
      final backupPath = 'users/${user.uid}/backups/latest_backup';
      print('📍 Backup path: $backupPath');

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('backups')
          .doc('latest_backup')
          .set(completeBackupData, SetOptions(merge: true));

      print('✅ Backup document written successfully');

      print('4️⃣ Updating user document...');
      await _firestore.collection('users').doc(user.uid).set({
        'lastBackup': FieldValue.serverTimestamp(),
        'backupPasswordCount': backupData['totalPasswords'] ?? 0,
        'updatedAt': FieldValue.serverTimestamp(),
        'userId_enc': encryptedUserId,
        'email_enc': encryptedEmail,
        'userKey': userKey,
        'encryptionVersion': 2,
      }, SetOptions(merge: true));

      print('✅ User document updated');

      print('───────────────────────────────────────────────');
      print('✅ FIREBASE: createBackup() SUCCESS');
      print('───────────────────────────────────────────────');
    } catch (e, stackTrace) {
      print('───────────────────────────────────────────────');
      print('❌ FIREBASE: createBackup() FAILED');
      print('Error: $e');
      print('Stack trace: $stackTrace');
      print('───────────────────────────────────────────────');
      throw Exception('Backup creation failed: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>?> getBackupInfo() async {
    try {
      print('───────────────────────────────────────────────');
      print('🔍 FIREBASE: getBackupInfo() START');
      print('───────────────────────────────────────────────');

      final user = _auth.currentUser;
      if (user == null) {
        print('❌ No current user');
        return null;
      }
      print('✅ Current user: ${user.uid}');

      final backupPath = 'users/${user.uid}/backups/latest_backup';
      print('📍 Checking path: $backupPath');

      final backupDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('backups')
          .doc('latest_backup')
          .get();

      print('📄 Document exists: ${backupDoc.exists}');

      if (backupDoc.exists) {
        final data = backupDoc.data() as Map<String, dynamic>?;
        final passwordsArray = data?['passwords'] as List?;
        final passwordCount = passwordsArray?.length ?? 0;
        final totalField = data?['totalPasswords'] ?? 0;

        print('✅ Backup document found!');
        print('📦 Data keys: ${data?.keys.toList() ?? []}');
        print('📊 Passwords array length: $passwordCount');
        print('📊 totalPasswords field: $totalField');

        if (passwordsArray != null && passwordsArray.isNotEmpty) {
          print(
              '📝 First password keys: ${(passwordsArray[0] as Map).keys.toList()}');
        }

        print('───────────────────────────────────────────────');
        print('✅ FIREBASE: getBackupInfo() SUCCESS');
        print('───────────────────────────────────────────────');
        return data;
      } else {
        print('⚠️ No backup document found at path: $backupPath');
        print('───────────────────────────────────────────────');
        print('⚠️ FIREBASE: getBackupInfo() - NO BACKUP');
        print('───────────────────────────────────────────────');
        return null;
      }
    } catch (e, stackTrace) {
      print('───────────────────────────────────────────────');
      print('❌ FIREBASE: getBackupInfo() FAILED');
      print('Error: $e');
      print('Stack trace: $stackTrace');
      print('───────────────────────────────────────────────');
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
        'message': 'Registration successful',
        'user': userCredential.user,
      };
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Registration failed';

      if (e.code == 'weak-password') {
        errorMessage = 'The password provided is too weak.';
      } else if (e.code == 'email-already-in-use') {
        try {
          final loginResult = await loginUser(email, password);
          if (loginResult['success'] == true) {
            return {
              'success': true,
              'message': 'Account already exists. Logged in successfully.',
              'user': loginResult['user'],
            };
          }
        } catch (loginError) {
          errorMessage = 'An account already exists for that email.';
        }
      } else if (e.code == 'invalid-email') {
        errorMessage = 'The email address is not valid.';
      }

      return {
        'success': false,
        'message': errorMessage,
        'errorCode': e.code,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'An unexpected error occurred during registration.',
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
        'user': userCredential.user,
      };
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Login failed';

      if (e.code == 'user-not-found') {
        errorMessage = 'No user found for that email.';
      } else if (e.code == 'wrong-password') {
        errorMessage = 'Wrong password provided for that user.';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'The email address is not valid.';
      } else if (e.code == 'user-disabled') {
        errorMessage = 'This user has been disabled.';
      }

      return {
        'success': false,
        'message': errorMessage,
        'errorCode': e.code,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'An unexpected error occurred during login.',
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
      print('🔥 FirebaseService: Starting save operation...');

      final user = _auth.currentUser;
      if (user == null) {
        print('❌ FirebaseService: User not logged in');
        return false;
      }

      // Generate document ID
      final documentId = passwordData['documentId'] ??
          passwordData['id'] ??
          DateTime.now().millisecondsSinceEpoch.toString();

      // Encrypt identity fields and add hashed scope key
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

      print('📝 FirebaseService: Saving document $documentId');

      // Save to main passwords collection
      await _firestore
          .collection('passwords')
          .doc(documentId)
          .set(passwordWithId);
      await _updatePasswordCount(user.uid, 1);

      print('✅ FirebaseService: Document saved successfully');
      return true;
    } catch (e) {
      print('❌ FirebaseService: Error saving password: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getPasswords() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('❌ FirebaseService: User not logged in for getPasswords');
        return [];
      }

      print('🔍 FirebaseService: Fetching passwords for user: ${user.uid}');

      final userKey = EncryptionService.hash(user.uid);
      var query = _firestore
          .collection('passwords')
          .where('userKey', isEqualTo: userKey)
          .orderBy('createdAt', descending: true);

      var querySnapshot = await query.get();

      // Fallback to legacy schema that used plaintext userId if no docs
      if (querySnapshot.docs.isEmpty) {
        query = _firestore
            .collection('passwords')
            .where('userId', isEqualTo: user.uid)
            .orderBy('createdAt', descending: true);
        querySnapshot = await query.get();
      }

      final passwords = querySnapshot.docs.map((doc) {
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

      print(
          '✅ FirebaseService: Retrieved ${passwords.length} passwords from Firebase');
      return passwords;
    } catch (e) {
      print('❌ FirebaseService: Error getting passwords: $e');
      return [];
    }
  }

  Future<bool> updatePassword(
      String passwordId, Map<String, dynamic> updates) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return false;
      }

      final doc =
          await _firestore.collection('passwords').doc(passwordId).get();
      if (!doc.exists) {
        return false;
      }

      final data = doc.data();
      final userKey = EncryptionService.hash(user.uid);
      if (data == null || data['userKey'] != userKey) {
        return false;
      }

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
      print('🔥 FirebaseService: Starting deletion for: $passwordId');

      final user = _auth.currentUser;
      if (user == null) {
        print('❌ FirebaseService: User not logged in');
        return false;
      }

      print('👤 FirebaseService: User ID: ${user.uid}');
      print('🔍 FirebaseService: Checking document: $passwordId');

      // First, verify the document exists and belongs to the user
      final doc =
          await _firestore.collection('passwords').doc(passwordId).get();

      if (!doc.exists) {
        print('❌ FirebaseService: Document does not exist: $passwordId');
        return false;
      }

      // Check if the document has the required userId field
      final data = doc.data();
      if (data == null) {
        print('❌ FirebaseService: Document has no data');
        return false;
      }

      final docUserId = data['userId'];
      if (docUserId == null) {
        print('❌ FirebaseService: Document missing userId field');
        print('📊 Available fields: ${data.keys}');
        return false;
      }

      if (docUserId != user.uid) {
        print('❌ FirebaseService: User ID mismatch');
        print('   Document userId: $docUserId');
        print('   Current user: ${user.uid}');
        return false;
      }

      // All checks passed - delete the document
      print('✅ FirebaseService: All checks passed, deleting document...');
      await _firestore.collection('passwords').doc(passwordId).delete();

      print('✅ FirebaseService: Document deleted successfully');

      // Update password count
      await _updatePasswordCount(user.uid, -1);

      print('🎉 FirebaseService: Deletion completed successfully');
      return true;
    } on FirebaseException catch (e) {
      print('❌ FirebaseService: Firebase error - ${e.code}: ${e.message}');
      return false;
    } catch (e) {
      print('💥 FirebaseService: Unexpected error: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> getPasswordById(String passwordId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return null;
      }

      final doc =
          await _firestore.collection('passwords').doc(passwordId).get();

      if (!doc.exists) {
        return null;
      }

      final data = doc.data();
      final userKey = EncryptionService.hash(user.uid);
      if (data == null || data['userKey'] != userKey) {
        return null;
      }

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
    } catch (e) {
      return null;
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

  Future<int> getPasswordCount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return 0;

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final data = userDoc.data();
      return data?['passwordCount'] ?? 0;
    } catch (e) {
      return 0;
    }
  }

  String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }

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
