import 'providers/chat_list_provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;



class BackendService{
  final Uri backendUrl = Uri.parse("https://frenzied-semicolon-unruffled.ngrok-free.dev");

    Stream<String> getAiStream(String question, String model, String token, String chatRoomID, String username) async* {
    final client = http.Client();
      
      try {
        final Uri streamUrl = backendUrl.resolve('chatrooms/$chatRoomID/generate');
        final request = http.Request("POST", streamUrl);
        
        request.headers['Content-Type'] = 'application/json';
        request.headers['Authorization'] = 'Bearer $token';
        request.body = jsonEncode({"question": question, "username": username, "model": model});

        final response = await client.send(request);

        if (response.statusCode == 200) {
          await for (final chunk in response.stream.transform(utf8.decoder)) {
            yield chunk; 
          }
        } else {
          yield "Error: Server returned ${response.statusCode}";
        }
      } catch (e) {
        yield "Connection Error: $e";
      } finally {
        client.close();
      }
    }

    Future<Map<String, dynamic>> getQuote(String token) async {
      try {
        final Uri quoteUrl = backendUrl.resolve("quote");
        final response = await http.get(quoteUrl, headers: {'Authorization': 'Bearer $token'});

        if (response.statusCode == 200) {
          return jsonDecode(response.body) as Map<String, dynamic>; 
        } else {
          return {
            "quote": "Sample Quote :D",
            "author": "Synapse System",
            "error": "Status: ${response.statusCode}"
          }; 
        }
      } catch (e) {
        return {
          "quote": "Sample Quote 2 :D",
          "author": "Synapse System",
          "error": e.toString()
        };
      }
    }

    Future<void> deleteChatRoom(String token, String chatId) async {
      try {
        final Uri deleteUrl = backendUrl.resolve("chatrooms/$chatId");
        
        final response = await http.delete(deleteUrl, headers: {'Authorization': 'Bearer $token'});

        if (response.statusCode != 200) {
          return;
        }
      } catch (e) {
        return;
      }
    }

    Future<List<ChatRoom>> fetchChatRooms(String token) async {
      try{
        final Uri chatRoomsUrl = backendUrl.resolve("chatrooms");
        final response = await http.get(chatRoomsUrl, headers: {'Authorization': 'Bearer $token'});
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final roomList = json["chatrooms"] as List<dynamic>;
        return roomList.map((room) => ChatRoom.fromJSON(room)).toList();
      }
      catch (e) {
        return [];
      }
    }

    Future<List<Message>> fetchAllMessages(String token, String chatId) async {
      try{
        final Uri messagesUrl = backendUrl.resolve("chatrooms/$chatId/messages");
        final response = await http.get(messagesUrl, headers: {'Authorization': 'Bearer $token'});
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final messageList = json["messages"] as List<dynamic>;
        return messageList.map((message) => Message.fromJSON(message)).toList();
      }
      catch (e) {
        return [];
      }
    }

    Future<String> saveMessage(String token, String chatId, Message message) async {
      try{
        final Uri messagesUrl = backendUrl.resolve("chatrooms/$chatId/messages");
        final Map<String, dynamic> messageToSave = message.toMap();
        final response = await http.post(messagesUrl, headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'}, body: jsonEncode(messageToSave));
        final respBody = jsonDecode(response.body);
        return respBody["id"];
      }
      catch (e) {
        return "";
      }
    }

    Future<String> createNewChat(String token, String title, String botType) async {
      try{
        final Uri messagesUrl = backendUrl.resolve("chatrooms");
        final Map<String, dynamic> messageToSave = {'title': title, 'botType': botType};
        final response = await http.post(messagesUrl, headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'}, body: jsonEncode(messageToSave));
        final respBody = jsonDecode(response.body);
        return respBody["id"];
      }
      catch (e) {
        return "";
      }
    }

    Future<void> renameChatRoom(String token, String chatId, String name) async{
      try{
        final Uri chatroomUrl = backendUrl.resolve("chatrooms/$chatId/rename");
        final Map<String, dynamic> packet = {'new_name': name};
        final _ = await http.put(chatroomUrl, headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'}, body: jsonEncode(packet));
        return;
      }
      catch (e) {
        return;
      }
    }

    Future<void> deleteMessages(String token, String chatId, List<String> messageIds) async{
      try{
        final Uri deleteMessagesUrl = backendUrl.resolve("chatrooms/$chatId/messages");
        final Map<String, dynamic> data = {"messageIds": messageIds};
        await http.delete(deleteMessagesUrl, headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'}, body: jsonEncode(data));
        return;
      }
      catch (e) {
        return;
      }
    }

    Future<void> addNewUser(String token, String username, String email) async {
      try{
        final Uri newUserUrl = backendUrl.resolve("users");
        final Map<String, dynamic> data = {"email": email, "username": username};
        final _ = await http.post(newUserUrl, headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'}, body: jsonEncode(data));
        return;
      }
      catch (e){
        return;
      }
    }

    Future<Map<String, dynamic>> getUserDetails(String token) async {
      try{
        final Uri userDetailsUrl = backendUrl.resolve("users");
        final response = await http.get(userDetailsUrl, headers: {'Authorization': 'Bearer $token'});
        final user = jsonDecode(response.body) as Map<String, dynamic>;
        return user;
      }
      catch (e){
        return {};
      }
    }

    Future<void> updateUserDetails(String token, {String newName = "", String email = ""}) async{
      try{
        final Uri userUrl = backendUrl.resolve("users");
        final Map<String, dynamic> packet = newName != "" ? {'username': newName} : {"email": email};
        final _ = await http.put(userUrl, headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'}, body: jsonEncode(packet));
        return;
      }
      catch (e) {
        return;
      }
    }

  }
