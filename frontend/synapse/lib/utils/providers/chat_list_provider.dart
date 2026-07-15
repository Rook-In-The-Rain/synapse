import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../signup_login_manager.dart';
import '../backend_connector.dart';

class Message {
  String text;
  final bool isUser;
  String id;
  DateTime? timestamp = DateTime.now();
  bool isTyping;

  
  Message({required this.text, this.isUser = true, this.isTyping = false, this.timestamp, this.id=""});

  factory Message.fromFirestore(DocumentSnapshot doc) {

    Map data = doc.data() as Map<String, dynamic>;

    return Message(
      id: doc.id,
      text: data['text'],    
      isUser: data['isUser'], 
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      );
  }

  factory Message.fromJSON(Map<String, dynamic> json) {
    return Message(
      id: json['id'] ?? "",
      text: json['text'] ?? "",
      isUser: json['isUser'], 
      timestamp: json['timestamp'] != null ? DateTime.parse(json['timestamp']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'isUser': isUser,
      'timestamp': timestamp?.toIso8601String()
    };
  }
}

class ChatHeaders {
  String title = "";
  String botType = "";
  String summary = "";

  ChatHeaders({this.title = "New Chat", this.botType = "AI Assistant", this.summary = ""});

  factory ChatHeaders.fromMap(Map<String, dynamic> data) {
    return ChatHeaders(
      title: data['title'] ?? "New Chat",
      botType: data['botType'] ?? "AI Assistant",
      summary: data['summary'] ?? "Nothing"
    );
  }
}

class ChatRoom {
  final String id;
  final ChatHeaders headers;
  List<Message> messages = [];

  ChatRoom({required this.id, ChatHeaders? headers}) 
      : headers = headers ?? ChatHeaders();

  factory ChatRoom.fromFirestore(DocumentSnapshot doc){
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return ChatRoom(
      id: doc.id,
      headers: ChatHeaders.fromMap(data['headers']),
    );
  }

  factory ChatRoom.fromJSON(Map<String, dynamic> json){
    return ChatRoom(
      id: json['id'] ?? "",
      headers: ChatHeaders.fromMap(json['headers'])
    );
  }

}


class ChatProvider extends ChangeNotifier {
  final List<ChatRoom> _chatRooms = [];
  late String _username;
  bool _isStreaming = false;

  List<ChatRoom> get chatRooms => _chatRooms;
  bool get isStreaming => _isStreaming;

  void initialize(String userUid) async {
    String token = await AuthManager().getIdToken() ?? "";
    final rooms = await BackendService().fetchChatRooms(token);
    _username = await AuthManager().getUsername();
    _chatRooms.clear();
    _chatRooms.addAll(rooms);
    notifyListeners();
  }

  Future<void> loadChatHistory(String chatId) async {
    String token = await AuthManager().getIdToken() ?? "";
    List<Message> history = await BackendService().fetchAllMessages(token, chatId);
    ChatRoom room = getChatbyId(chatId);

    room.messages.clear();
    room.messages.addAll(history);

    notifyListeners();
  }

  Future<void> deleteChatRoom(String chatRoomID) async{
    chatRooms.removeWhere((room) => room.id == chatRoomID);
    String token = await AuthManager().getIdToken() ?? "";
    await BackendService().deleteChatRoom(token, chatRoomID);
    notifyListeners();
  }

  Future<void> renameChatRoom(String chatRoomID, String name) async{
    final ChatRoom room = getChatbyId(chatRoomID);
    String token = await AuthManager().getIdToken() ?? "";
    BackendService().renameChatRoom(token, chatRoomID, name);
    room.headers.title = name;
    notifyListeners();
  }


  Future<void> sendUserMessageAndReply(String chatId, String text) async {
    final room = getChatbyId(chatId);
    _isStreaming = true;
    notifyListeners();

    try {
      Message userMsg = Message(text: text, isUser: true, timestamp: DateTime.now());
      String token = await AuthManager().getIdToken() ?? "";
      userMsg.id = await BackendService().saveMessage(token, chatId, userMsg);
      room.messages.add(userMsg);

      Message aiMessage = Message(text: "", isUser: false, isTyping: true, timestamp: DateTime.now());
      room.messages.add(aiMessage);
      notifyListeners();
      final BackendService backend = BackendService();
      await for (String chunk in backend.getAiStream(userMsg.text, room.headers.botType, token, chatId, _username)) {
        aiMessage.text += chunk;
        notifyListeners();
      }

      aiMessage.isTyping = false;
      aiMessage.id = await BackendService().saveMessage(token, chatId, aiMessage);
    } finally {
      _isStreaming = false;
      notifyListeners();
    }
  }

  ChatRoom getChatbyId(String id) {
    return _chatRooms.firstWhere((room) => room.id == id);
  }

  Future<void> createNewChat(String title, String botType) async {
    String token = await AuthManager().getIdToken() ?? "";
    String realId = await BackendService().createNewChat(token, title, botType);
    
    final headers = ChatHeaders(title: title, botType: botType);
    _chatRooms.add(ChatRoom(id: realId, headers: headers));

    notifyListeners();
  }

  Future<void> deleteMessages(String chatId, List<String> messageIds) async{
    ChatRoom room = getChatbyId(chatId);
    room.messages = room.messages.where((m) => !messageIds.contains(m.id)).toList();
    String token = await AuthManager().getIdToken() ?? "";
    BackendService().deleteMessages(token, chatId, messageIds);
    notifyListeners();
  }

  Future<void> regenerateMessage(String chatId, List<Message> messages) async{
    final Message userMessage = messages[0];
    final Message aiMessage = messages[1];
    await deleteMessages(chatId, [userMessage.id, aiMessage.id]);
    await sendUserMessageAndReply(chatId, userMessage.text);
  }

}