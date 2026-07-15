import 'package:firebase_auth/firebase_auth.dart';
import 'backend_connector.dart';


class AuthManager{

  User? get currUser => FirebaseAuth.instance.currentUser;
  
  Future<String?> getIdToken() async {
    String? token = await FirebaseAuth.instance.currentUser?.getIdToken();
    return token;
  }

  Future<void> signUp(String email, String password, String username) async {
    try {
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    final user = credential.user;
    final String token = await user?.getIdToken() ?? "";
    await BackendService().addNewUser(token, username, email);

    } catch (_) {
        return;
    }
  }

  Future<void> logIn(String email, String password) async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password
      );
    } on FirebaseAuthException catch (_) {
      return;
    }
  }
    Future<void> logOut() async {
    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {
      return;
    }
  }

  Future<String> getUsername() async{
    final String token = await getIdToken() ?? "";

    final Map<String, dynamic> user = await BackendService().getUserDetails(token);
    return user["username"];
  }

  Future<void> updateUsername(String newName) async{
    try {
      final String token = await getIdToken() ?? "";
      await BackendService().updateUserDetails(token, newName: newName);

    } catch (_) {
      throw Exception("Failed to update username");
    }
  }
}