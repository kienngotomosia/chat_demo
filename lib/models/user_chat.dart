import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_chat_demo/constants/constants.dart';

class UserChat {
  String id;
  String photoUrl;
  String nickname;
  String aboutMe;
  String pushToken;

  UserChat(
      {required this.id,
      required this.photoUrl,
      required this.nickname,
      required this.aboutMe,
      required this.pushToken});

  Map<String, String> toJson() {
    return {
      FirestoreConstants.id: id,
      FirestoreConstants.nickname: nickname,
      FirestoreConstants.aboutMe: aboutMe,
      FirestoreConstants.photoUrl: photoUrl,
      FirestoreConstants.pushToken: pushToken,
    };
  }

  factory UserChat.fromDocument(DocumentSnapshot doc) {
    String aboutMe = "";
    String photoUrl = "";
    String id = "";
    String nickname = "";
    String pushToken = "";
    try {
      aboutMe = doc.get(FirestoreConstants.aboutMe);
    } catch (e) {}
    try {
      photoUrl = doc.get(FirestoreConstants.photoUrl);
    } catch (e) {}
    try {
      id = doc.get(FirestoreConstants.id);
    } catch (e) {}
    try {
      nickname = doc.get(FirestoreConstants.nickname);
    } catch (e) {}
    try {
      pushToken = doc.get(FirestoreConstants.pushToken);
    } catch (e) {}
    return UserChat(
      id: id,
      photoUrl: photoUrl,
      nickname: nickname,
      aboutMe: aboutMe,
      pushToken: pushToken,
    );
  }
}
