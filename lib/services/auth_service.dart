import 'dart:developer' as developer;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // 現在のユーザーを取得
  User? get currentUser => _auth.currentUser;

  // 認証状態の変更をストリームで監視
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // メールアドレスとパスワードでサインアップ
  Future<UserCredential?> signUpWithEmail(
    String email,
    String password,
    String displayName,
  ) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // ユーザー情報をFirestoreに保存
      if (userCredential.user != null) {
        UserModel userModel = UserModel(
          id: userCredential.user!.uid,
          email: email,
          displayName: displayName,
          createdAt: DateTime.now(),
        );

        await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .set(userModel.toFirestore());

        // 表示名を設定
        await userCredential.user!.updateDisplayName(displayName);
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      developer.log('サインアップエラー', error: e.message, name: 'AuthService');
      rethrow;
    }
  }

  // メールアドレスとパスワードでサインイン
  Future<UserCredential?> signInWithEmail(
    String email,
    String password,
  ) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential;
    } on FirebaseAuthException catch (e) {
      developer.log('サインインエラー', error: e.message, name: 'AuthService');
      rethrow;
    }
  }

  // Googleでサインイン
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Google Sign-Inフローを開始
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // ユーザーがサインインをキャンセルした
        return null;
      }

      // Google認証の詳細を取得
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Firebase認証用のクレデンシャルを作成
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Firebaseにサインイン
      UserCredential userCredential = await _auth.signInWithCredential(credential);

      // 新規ユーザーの場合、Firestoreにユーザー情報を保存
      if (userCredential.additionalUserInfo?.isNewUser ?? false) {
        if (userCredential.user != null) {
          UserModel userModel = UserModel(
            id: userCredential.user!.uid,
            email: userCredential.user!.email ?? '',
            displayName: userCredential.user!.displayName ?? 'ゲスト',
            photoUrl: userCredential.user!.photoURL,
            createdAt: DateTime.now(),
          );

          await _firestore
              .collection('users')
              .doc(userCredential.user!.uid)
              .set(userModel.toFirestore());
        }
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      developer.log('Google サインインエラー', error: e.message, name: 'AuthService');
      rethrow;
    } catch (e) {
      developer.log('Google サインインエラー', error: e, name: 'AuthService');
      rethrow;
    }
  }

  // サインアウト
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // Firestoreからユーザー情報を取得
  Future<UserModel?> getUserData(String userId) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      developer.log('ユーザーデータ取得エラー', error: e, name: 'AuthService');
      return null;
    }
  }

  // プロフィールを更新
  Future<void> updateProfile({
    required String userId,
    required String displayName,
    String? photoUrl,
  }) async {
    try {
      // Firestoreのユーザー情報を更新
      await _firestore.collection('users').doc(userId).update({
        'displayName': displayName,
        if (photoUrl != null) 'photoUrl': photoUrl,
      });

      // Firebase Authの表示名も更新
      User? user = _auth.currentUser;
      if (user != null) {
        await user.updateDisplayName(displayName);
        if (photoUrl != null) {
          await user.updatePhotoURL(photoUrl);
        }
        await user.reload();
      }
    } catch (e) {
      developer.log('プロフィール更新エラー', error: e, name: 'AuthService');
      rethrow;
    }
  }
}
