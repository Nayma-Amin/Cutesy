import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? get currentUser => FirebaseAuth.instance.currentUser;

  bool get isLoggedIn => FirebaseAuth.instance.currentUser != null;

  Future<String?> registerUser({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String address,
  }) async {
    try {
      QuerySnapshot phoneSnap = await _db
          .collection("users")
          .where("phone", isEqualTo: phone)
          .get();

      if (phoneSnap.docs.isNotEmpty) {
        return "This phone number is already registered.";
      }

      UserCredential cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      String uid = cred.user!.uid;

      await _db.collection("users").doc(uid).set({
        "uid": uid,
        "name": name,
        "email": email,
        "phone": phone,
        "address": address,
        "role": "user",
        "createdAt": FieldValue.serverTimestamp(),
      });

      return null;
    } on FirebaseAuthException catch (e) {
      try {
        await _auth.currentUser?.delete();
      } catch (_) {}
      return e.message;
    } catch (e) {
      try {
        await _auth.currentUser?.delete();
      } catch (_) {}
      return "Something went wrong. Please try again.";
    }
  }

  Future<String?> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);

      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return "Something went wrong";
    }
  }

  Future<String?> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> getUsername() async {
    String uid = FirebaseAuth.instance.currentUser!.uid;
    DocumentSnapshot snap = await FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .get();
    return snap["name"];
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
