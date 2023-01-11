class ChatPageArguments {
  final String peerId;

  final String peerAvatar;
  final String peerNickname;
  final String pushToken;

  ChatPageArguments(
      {required this.peerId,
      required this.peerAvatar,
      required this.peerNickname,
      this.pushToken = ''});
}
