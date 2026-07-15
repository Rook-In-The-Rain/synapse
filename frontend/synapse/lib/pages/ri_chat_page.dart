import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import '../utils/widgets/chat_bubble.dart';
import '../utils/providers/chat_list_provider.dart';
import '../utils/signup_login_manager.dart';


class RIChatPage extends StatefulWidget{
  final String chatId;
  const RIChatPage({super.key, required this.chatId});
  
  @override
  State<RIChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<RIChatPage> {

  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? username;
  late ChatRoom _chatRoom;

  @override
  void initState() {
    super.initState();
    _loadUsernameAndChatRoom();
  }

    Future<void> _loadUsernameAndChatRoom() async {
    _chatRoom = Provider.of<ChatProvider>(context, listen: false).getChatbyId(widget.chatId);
    username = await AuthManager().getUsername();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Column(children: 
      [
        SizedBox(height: kToolbarHeight + MediaQuery.of(context).padding.top - 50),
          Expanded(child: 
            Consumer<ChatProvider>(
              builder: (context, chatProvider, child){
              final List<Message> messages = _chatRoom.messages;
              final bool showActions = messages.isNotEmpty && !messages.last.isTyping;
              return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 20), 
                  itemCount: showActions ? messages.length + 1 : messages.length,
                  controller: _scrollController,
                  itemBuilder: (context, index) {
                    if (index == messages.length) {
                      return _buildActionRow(context, _chatRoom);
                    }
                    final message = messages[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                      child: message.isUser 
                      ? UserChatBubble(message: message.text)
                      : AIChatBubble(message: message.text.replaceAll("!!name!!", username ?? "User"), isTyping: message.isTyping),
                    );
                  },
                );
              }
            )
          ),
          _buildMessageInput(context)
        ]
      ),
    );
  }

Widget _buildMessageInput(BuildContext context) {
    
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: colorScheme.secondary.withAlpha(40) ,
        boxShadow: [
          BoxShadow(
            color: colorScheme.onSurface.withAlpha(5),
            blurRadius: 10,
            offset: const Offset(0, -5),
          )
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Consumer<ChatProvider>(
              builder: (context, provider, child) {
                bool canSend = !provider.isStreaming;
                return Row(
                children: [
                  Expanded(
                  child: Focus(
                    onKeyEvent: (FocusNode node, KeyEvent event) {
                        if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.enter && canSend) {
                          if (HardwareKeyboard.instance.isShiftPressed) {
                            return KeyEventResult.ignored; 
                          } else {
                          final text = _messageController.text.trim();
                          if(text.isEmpty) return KeyEventResult.ignored;
                          _messageController.clear();
                          provider.sendUserMessageAndReply(widget.chatId, text);
                            
                            return KeyEventResult.handled; 
                          }
                        }
                        return KeyEventResult.ignored;
                      },
                    child: TextField(
                      controller: _messageController,
                      minLines: 1,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Ask a question...',
                        hintStyle: TextStyle(color: colorScheme.primary.withAlpha(100)),
                        filled: true,
                        fillColor: colorScheme.surface,
                        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15), 
                          borderSide: BorderSide(color: colorScheme.onSurface.withAlpha(2)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide(color: colorScheme.onSurface.withAlpha(6)),
                        )
                      ),
                    ),
                  )
                ),
                const SizedBox(width: 12),
                CircleAvatar(
                  backgroundColor: canSend ? colorScheme.primary : colorScheme.onSurface.withAlpha(12),
                  radius: 22,
                  child: IconButton(
                    icon: provider.isStreaming 
                      ? SizedBox(
                          width: 15, 
                          height: 15, 
                          child: CircularProgressIndicator(color: colorScheme.onPrimary, strokeWidth: 2)
                        )
                      : Icon(Icons.send, color: colorScheme.onPrimary, size: 20),
                    
                    onPressed: canSend ? () {
                      final text = _messageController.text.trim();
                      if (text.isEmpty) return;
                      _messageController.clear();
                      provider.sendUserMessageAndReply(widget.chatId, text);
                    } : null, 
                  ),
                )
              ]);
            },
          ),
        ),
      ),
    );
  }
}


Widget _buildActionRow(BuildContext context, ChatRoom room) {
  final ChatRoom chatRoom = room;

  return Padding(
    padding: const EdgeInsets.only(left: 16, right: 16, bottom: 20, top: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        _ActionChip(
          icon: Icons.edit_outlined,
          label: "Edit input",
          onPressed: () {
            final List<String> messageIds = chatRoom.messages
                .sublist(chatRoom.messages.length - 2)
                .map((e) => e.id)
                .toList();
            Provider.of<ChatProvider>(context, listen: false)
                .deleteMessages(chatRoom.id, messageIds);
          },
        ),
        const SizedBox(width: 8),
        _ActionChip(
          icon: Icons.refresh_rounded,
          label: "Regenerate",
          onPressed: () {
            final List<Message> messages =
                chatRoom.messages.sublist(chatRoom.messages.length - 2);
            Provider.of<ChatProvider>(context, listen: false)
                .regenerateMessage(chatRoom.id, messages);
          },
        ),
        const SizedBox(width: 8),
        _ActionChip(
          icon: Icons.copy_all_rounded,
          label: "Copy",
          onPressed: () {
            if (chatRoom.messages.isNotEmpty) {
              final String lastMessageText = chatRoom.messages.last.text;
              
              Clipboard.setData(ClipboardData(text: lastMessageText)).then((_) {
                if(!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text("Copied to clipboard"),
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 1),
                    width: 200,
                  ),
                );
              });
            }
          },
        ),
      ],
    ),
  );
}


class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  const _ActionChip({required this.icon, required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16, color: colorScheme.secondary),
      label: Text(
        label,
        style: TextStyle(fontSize: 12, color: colorScheme.secondary, fontWeight: FontWeight.w400),
      ),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        backgroundColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.grey.withAlpha(20)),
        ),
      ),
    );
  }
}

