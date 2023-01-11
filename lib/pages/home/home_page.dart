import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_demo/constants/app_constants.dart';
import 'package:flutter_chat_demo/constants/constants.dart';
import 'package:flutter_chat_demo/models/chat_agrument_model.dart';
import 'package:flutter_chat_demo/pages/auth/login_screen.dart';
import 'package:flutter_chat_demo/pages/video_call/video_call_screen.dart';
import 'package:flutter_chat_demo/providers/providers.dart';
import 'package:flutter_chat_demo/utils/utils.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../widgets/widgets.dart';
import '../pages.dart';

class HomePage extends StatefulWidget {
  HomePage({Key? key}) : super(key: key);

  @override
  State createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  HomePageState({Key? key});

  final FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final GoogleSignIn googleSignIn = GoogleSignIn();
  final ScrollController listScrollController = ScrollController();

  int _limit = 20;
  int _limitIncrement = 20;
  String _textSearch = "";
  bool isLoading = false;

  late AuthProvider authProvider;
  late String currentUserId;
  late HomeProvider homeProvider;
  Debouncer searchDebouncer = Debouncer(milliseconds: 300);
  StreamController<bool> btnClearController = StreamController<bool>();
  TextEditingController searchBarTec = TextEditingController();

  List<PopupChoices> choices = <PopupChoices>[
    PopupChoices(title: 'Settings', icon: Icons.settings),
    PopupChoices(title: 'Log out', icon: Icons.exit_to_app),
  ];
  UserChat contactUser = UserChat(
      id: 'id',
      photoUrl: 'photoUrl',
      nickname: 'nickname',
      aboutMe: 'aboutMe',
      pushToken: 'pushToken');
  @override
  void initState() {
    super.initState();
    authProvider = context.read<AuthProvider>();
    homeProvider = context.read<HomeProvider>();

    if (authProvider.getUserFirebaseId()?.isNotEmpty == true) {
      currentUserId = authProvider.getUserFirebaseId()!;
    } else {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => LoginScreen()),
        (Route<dynamic> route) => false,
      );
    }
    registerNotification();
    configLocalNotification();
    listScrollController.addListener(scrollListener);
  }

  @override
  void dispose() {
    super.dispose();
    btnClearController.close();
  }

  void getUser(String userId) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get()
        .then((value) {
      setState(() {
        contactUser = UserChat.fromDocument(value);
      });
      print('contact user: ${contactUser.nickname}');
    });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getLastestMessage(contactId) {
    var data = FirebaseFirestore.instance
        .collection('messages')
        .doc('$currentUserId-$contactId')
        .collection('$currentUserId-$contactId')
        .snapshots();
    print('data:${data.length}');
    return data;
  }

  void registerNotification() async {
    NotificationSettings settings = await firebaseMessaging.requestPermission();
    print('User granted permission: ${settings.authorizationStatus}');

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('onMessage: ${message.data}');
      message.data['type'] == 'call'
          ? showDialog(
              context: context,
              builder: (context) {
                getUser(message.data['contactid']);
                return Scaffold(
                  appBar: AppBar(
                    automaticallyImplyLeading: true,
                  ),
                  body: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Incoming call...'),
                        Text(contactUser.nickname),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: Container(
                                    height: 60,
                                    width: 60,
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                        child: Icon(
                                      Icons.call_end,
                                      color: Colors.white,
                                    )))),
                            const SizedBox(width: 50),
                            GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) => VideoCallScreen()));
                                },
                                child: Container(
                                    height: 60,
                                    width: 60,
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                        child: Icon(
                                      Icons.call,
                                      color: Colors.white,
                                    )))),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              })
          : showNotification(message.data);

      return;
    });

    firebaseMessaging.getToken().then((token) {
      print('push token: $token');
      if (token != null) {
        homeProvider.updateDataFirestore(FirestoreConstants.pathUserCollection,
            currentUserId, {'pushToken': token});
      }
    }).catchError((err) {
      Fluttertoast.showToast(msg: err.message.toString());
    });
  }

  void configLocalNotification() {
    AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('app_icon');
    DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings();
    InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  void scrollListener() {
    if (listScrollController.offset >=
            listScrollController.position.maxScrollExtent &&
        !listScrollController.position.outOfRange) {
      setState(() {
        _limit += _limitIncrement;
      });
    }
  }

  void onItemMenuPress(PopupChoices choice) {
    if (choice.title == 'Log out') {
      handleSignOut();
    } else {
      Navigator.push(
          context, MaterialPageRoute(builder: (context) => SettingsPage()));
    }
  }

  void showNotification(dynamic data) async {
    AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      Platform.isAndroid
          ? 'com.dfa.flutterchatdemo'
          : 'com.duytq.flutterchatdemo',
      'Flutter chat demo',
      playSound: true,
      enableVibration: true,
      importance: Importance.max,
      priority: Priority.high,
    );
    DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails();
    NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );
    var message = json.decode(data['notification']);
    await flutterLocalNotificationsPlugin.show(
      0,
      message['title'],
      message['body'],
      platformChannelSpecifics,
      payload: null,
    );
  }

  Future<bool> onBackPress() {
    openDialog();
    return Future.value(false);
  }

  Future<void> openDialog() async {
    switch (await showDialog(
        context: context,
        builder: (BuildContext context) {
          return SimpleDialog(
            clipBehavior: Clip.hardEdge,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: EdgeInsets.zero,
            children: <Widget>[
              Container(
                color: ColorConstants.themeColor,
                padding: EdgeInsets.only(bottom: 10, top: 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Container(
                      child: Icon(
                        Icons.exit_to_app,
                        size: 30,
                        color: Colors.white,
                      ),
                      margin: EdgeInsets.only(bottom: 10),
                    ),
                    Text(
                      'Exit app',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Are you sure to exit app?',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),
              SimpleDialogOption(
                onPressed: () {
                  Navigator.pop(context, 0);
                },
                child: Row(
                  children: <Widget>[
                    Container(
                      child: Icon(
                        Icons.cancel,
                        color: ColorConstants.primaryColor,
                      ),
                      margin: EdgeInsets.only(right: 10),
                    ),
                    Text(
                      'Cancel',
                      style: TextStyle(
                          color: ColorConstants.primaryColor,
                          fontWeight: FontWeight.bold),
                    )
                  ],
                ),
              ),
              SimpleDialogOption(
                onPressed: () {
                  Navigator.pop(context, 1);
                },
                child: Row(
                  children: <Widget>[
                    Container(
                      child: Icon(
                        Icons.check_circle,
                        color: ColorConstants.primaryColor,
                      ),
                      margin: EdgeInsets.only(right: 10),
                    ),
                    Text(
                      'Yes',
                      style: TextStyle(
                          color: ColorConstants.primaryColor,
                          fontWeight: FontWeight.bold),
                    )
                  ],
                ),
              ),
            ],
          );
        })) {
      case 0:
        break;
      case 1:
        exit(0);
    }
  }

  Future<void> handleSignOut() async {
    authProvider.handleSignOut();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => LoginScreen()),
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppConstants.homeTitle,
          style: TextStyle(color: ColorConstants.primaryColor),
        ),
        centerTitle: true,
        actions: <Widget>[buildPopupMenu()],
      ),
      body: SafeArea(
        child: WillPopScope(
          child: Stack(
            children: <Widget>[
              // List
              Column(
                children: [
                  buildSearchBar(),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: homeProvider.getStreamFireStore(
                          FirestoreConstants.pathUserCollection,
                          _limit,
                          _textSearch),
                      builder: (BuildContext context,
                          AsyncSnapshot<QuerySnapshot> snapshot) {
                        if (snapshot.hasData) {
                          if ((snapshot.data?.docs.length ?? 0) > 0) {
                            return ListView.builder(
                              padding: EdgeInsets.all(10),
                              itemBuilder: (context, index) => buildItem(
                                  context, snapshot.data?.docs[index]),
                              itemCount: snapshot.data?.docs.length,
                              controller: listScrollController,
                            );
                          } else {
                            return Center(
                              child: Text("No users"),
                            );
                          }
                        } else {
                          return Center(
                            child: CircularProgressIndicator(
                              color: ColorConstants.themeColor,
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),

              // Loading
              Positioned(
                child: isLoading ? LoadingView() : SizedBox.shrink(),
              )
            ],
          ),
          onWillPop: onBackPress,
        ),
      ),
    );
  }

  Widget buildSearchBar() {
    return Container(
      height: 40,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.search, color: ColorConstants.greyColor, size: 20),
          SizedBox(width: 5),
          Expanded(
            child: TextFormField(
              textInputAction: TextInputAction.search,
              controller: searchBarTec,
              onChanged: (value) {
                searchDebouncer.run(() {
                  if (value.isNotEmpty) {
                    btnClearController.add(true);
                    setState(() {
                      _textSearch = value;
                    });
                  } else {
                    btnClearController.add(false);
                    setState(() {
                      _textSearch = "";
                    });
                  }
                });
              },
              decoration: InputDecoration.collapsed(
                hintText: 'Search nickname (you have to type exactly string)',
                hintStyle:
                    TextStyle(fontSize: 13, color: ColorConstants.greyColor),
              ),
              style: TextStyle(fontSize: 13),
            ),
          ),
          StreamBuilder<bool>(
              stream: btnClearController.stream,
              builder: (context, snapshot) {
                return snapshot.data == true
                    ? GestureDetector(
                        onTap: () {
                          searchBarTec.clear();
                          btnClearController.add(false);
                          setState(() {
                            _textSearch = "";
                          });
                        },
                        child: Icon(Icons.clear_rounded,
                            color: ColorConstants.greyColor, size: 20))
                    : SizedBox.shrink();
              }),
        ],
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: ColorConstants.greyColor2,
      ),
      padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
      margin: EdgeInsets.fromLTRB(16, 8, 16, 8),
    );
  }

  Widget buildPopupMenu() {
    return PopupMenuButton<PopupChoices>(
      onSelected: onItemMenuPress,
      itemBuilder: (BuildContext context) {
        return choices.map((PopupChoices choice) {
          return PopupMenuItem<PopupChoices>(
              value: choice,
              child: Row(
                children: <Widget>[
                  Icon(
                    choice.icon,
                    color: ColorConstants.primaryColor,
                  ),
                  Container(
                    width: 10,
                  ),
                  Text(
                    choice.title,
                    style: TextStyle(color: ColorConstants.primaryColor),
                  ),
                ],
              ));
        }).toList();
      },
    );
  }

  Widget buildItem(BuildContext context, DocumentSnapshot? document) {
    if (document != null) {
      UserChat userChat = UserChat.fromDocument(document);
      print(userChat.pushToken);
      if (userChat.id == currentUserId) {
        return SizedBox.shrink();
      } else {
        return Container(
          child: TextButton(
            child: Row(
              children: <Widget>[
                Material(
                  child: userChat.photoUrl.isNotEmpty
                      ? Image.network(
                          userChat.photoUrl,
                          fit: BoxFit.cover,
                          width: 50,
                          height: 50,
                          loadingBuilder: (BuildContext context, Widget child,
                              ImageChunkEvent? loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              width: 50,
                              height: 50,
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: ColorConstants.themeColor,
                                  value: loadingProgress.expectedTotalBytes !=
                                          null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, object, stackTrace) {
                            return Icon(
                              Icons.account_circle,
                              size: 50,
                              color: ColorConstants.greyColor,
                            );
                          },
                        )
                      : Icon(
                          Icons.account_circle,
                          size: 50,
                          color: ColorConstants.greyColor,
                        ),
                  borderRadius: BorderRadius.all(Radius.circular(25)),
                  clipBehavior: Clip.hardEdge,
                ),
                Flexible(
                  child: Container(
                    child: Column(
                      children: <Widget>[
                        Container(
                          child: Text(
                            '${userChat.nickname}',
                            maxLines: 1,
                            style:
                                TextStyle(color: ColorConstants.primaryColor),
                          ),
                          alignment: Alignment.centerLeft,
                          margin: EdgeInsets.fromLTRB(10, 0, 0, 5),
                        ),
                        Container(
                          child: StreamBuilder(
                            stream: getLastestMessage(userChat.id),
                            builder: (context, snapshot) => Text(
                              'jsonDecode(snapshot.data)',
                              style: TextStyle(),
                            ),
                          ),
                          alignment: Alignment.centerLeft,
                          margin: EdgeInsets.fromLTRB(10, 0, 0, 0),
                        )
                      ],
                    ),
                    margin: EdgeInsets.only(left: 20),
                  ),
                ),
              ],
            ),
            onPressed: () {
              if (Utilities.isKeyboardShowing()) {
                Utilities.closeKeyboard(context);
              }
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatPage(
                    arguments: ChatPageArguments(
                      peerId: userChat.id,
                      peerAvatar: userChat.photoUrl,
                      peerNickname: userChat.nickname,
                      pushToken: userChat.pushToken,
                    ),
                  ),
                ),
              );
            },
            style: ButtonStyle(
              backgroundColor:
                  MaterialStateProperty.all<Color>(ColorConstants.greyColor2),
              shape: MaterialStateProperty.all<OutlinedBorder>(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
              ),
            ),
          ),
          margin: EdgeInsets.only(bottom: 10, left: 5, right: 5),
        );
      }
    } else {
      return SizedBox.shrink();
    }
  }
}
