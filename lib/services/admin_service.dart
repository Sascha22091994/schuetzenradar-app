import 'package:cloud_firestore/cloud_firestore.dart';

class AdminService {

  //--------------------------------------------------
  // ✅ STATUS
  //--------------------------------------------------
  static bool isAdmin = false;

  //--------------------------------------------------
  // ✅ LOGIN (GLOBAL ADMIN)
  //--------------------------------------------------
  static Future<bool> login(String inputPassword) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('admin')
          .doc('main')
          .get();

      if (!doc.exists) return false;

      final data = doc.data()!;

      final storedPassword = data['password'];

      if (inputPassword == storedPassword) {
        isAdmin = true;
        return true;
      }

      return false;

    } catch (e) {
      return false;
    }
  }

  //--------------------------------------------------
  // ✅ LOGOUT
  //--------------------------------------------------
  static void logout() {
    isAdmin = false;
  }

  //--------------------------------------------------
  // ✅ CHECK
  //--------------------------------------------------
  static bool check() {
    return isAdmin;
  }

  //--------------------------------------------------
  // ✅ OPTIONAL: ADMIN STATUS REFRESH (falls später nötig)
  //--------------------------------------------------
  static Future<bool> refreshAdmin() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('admin')
          .doc('main')
          .get();

      return doc.exists;

    } catch (e) {
      return false;
    }
  }
}