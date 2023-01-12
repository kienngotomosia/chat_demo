import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:flutter_chat_demo/constants/constants.dart';
import 'package:flutter_chat_demo/dio/end_point.dart';
import 'package:flutter_chat_demo/models/message_chat.dart';

class DioClient {
  DioClient()
      : _dio = Dio(BaseOptions(
          baseUrl: Endpoints.channel,
          connectTimeout: Endpoints.connectionTimeout,
          receiveTimeout: Endpoints.receiveTimeout,
          headers: {
            "Authorization": Endpoints.apiKey,
          },
        ));

  final Dio _dio;

  Future<bool> sendMessageToFirebase(MessageChat messageChat) async {
    var senderDoc = await FirebaseFirestore.instance
        .collection(FirestoreConstants.pathUserCollection)
        .doc(messageChat.idTo)
        .get();
    String senderName = senderDoc.data()!['nickname'];
    var receiverDoc = await FirebaseFirestore.instance
        .collection(FirestoreConstants.pathUserCollection)
        .doc(messageChat.idTo)
        .get();
    String token = receiverDoc.data()!['pushToken'];
    print(">>>>> $token");
    var response = await _dio.post("", data: {
      "registration_ids": [token],
      "data": {
        "title": senderName,
        "body": messageChat.content,
        "subTitle": "subTitle",
        "payloadData": {
          "peerId": receiverDoc.id,
          "peerAvatar": receiverDoc.data()!["photoUrl"],
          "peerNickname": "nickname",
          "screen": "/chat_page"
        },
        "channelId": "1",
        "channelName": "hello"
      }
    });
    if (response.statusCode! < 400) {
      return true;
    }
    return false;
  }
}
