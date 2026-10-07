import 'package:firebase_auth/firebase_auth.dart';

const adminEmails = <String>{
  'payefatou97@gmail.com',
  'adamambacke19@gmail.com',
};

bool isSakinaAdminEmail(String? email) {
  return email != null && adminEmails.contains(email.trim().toLowerCase());
}

bool isSakinaAdmin(User? user) {
  return isSakinaAdminEmail(user?.email) && (user?.emailVerified ?? false);
}
