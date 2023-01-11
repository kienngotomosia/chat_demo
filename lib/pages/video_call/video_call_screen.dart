import 'package:agora_uikit/agora_uikit.dart';
import 'package:flutter/material.dart';

class VideoCallScreen extends StatefulWidget {
  const VideoCallScreen({super.key});

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  final AgoraClient _client = AgoraClient(
      agoraConnectionData: AgoraConnectionData(
    appId: 'efea4691838c4b01a7321c5f9abfafb9',
    channelName: 'demo_chatq',
    tempToken: '7258be8035524bc18074f2860e3d956b',
  ));
  Future<void> _initAgora() async {
    await _client.initialize();
  }

  @override
  void initState() {
    super.initState();
    _initAgora();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            AgoraVideoViewer(
              client: _client,
              layoutType: Layout.floating,
              showNumberOfUsers: true,
            ),
            AgoraVideoButtons(
              client: _client,
              enabledButtons: const [
                BuiltInButtons.toggleCamera,
                BuiltInButtons.switchCamera,
                BuiltInButtons.callEnd,
                BuiltInButtons.toggleMic,
              ],
            )
          ],
        ),
      ),
    );
  }
}
