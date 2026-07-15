import 'package:flutter/material.dart';
import '../providers/chat_list_provider.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';


class HoverableChatTile extends StatefulWidget {
  final String title;
  final VoidCallback onTap;
  final ChatRoom chatRoom;

  const HoverableChatTile({
    super.key, 
    required this.title, 
    required this.onTap,
    required this.chatRoom
  });

  @override
  State<HoverableChatTile> createState() => _HoverableChatTileState();
}

class _HoverableChatTileState extends State<HoverableChatTile> {
  bool _isHovered = false;
  bool _isMenuOpen = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: ListTile(
        leading: Icon(Icons.chat_bubble_outline, color: Theme.of(context).colorScheme.secondary),
        title: Text(widget.title, style: TextStyle(color: Theme.of(context).colorScheme.secondary), maxLines: 1, overflow: TextOverflow.ellipsis,),
        hoverColor: Theme.of(context).colorScheme.primary.withAlpha(25),
        onTap: widget.onTap,
        trailing: (_isHovered || _isMenuOpen)
            ? PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onOpened: () => setState(() => _isMenuOpen = true),
                onCanceled: () => setState(() => _isMenuOpen = false),
                onSelected: (value){
                  if(value == 'delete'){
                    final provider = context.read<ChatProvider>();
                    final roomId = widget.chatRoom.id;
                    Navigator.pop(context);
                    final String currLocation = GoRouterState.of(context).uri.toString();
                    if (currLocation.contains(roomId)) {
                      context.go('/'); 
                    }
                    provider.deleteChatRoom(roomId);
                  }
                  if(value == 'edit'){
                    final roomId = widget.chatRoom.id;
                    _showRenameDialog(context, roomId);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'edit', child: Text('Rename')),
                  const PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              )
            : const SizedBox(width: 48),
      ),
    );
  }
}


void _showRenameDialog(BuildContext context, String roomId) {
  final controller = TextEditingController();

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Rename Chat'),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: const InputDecoration(hintText: "Enter new name"),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context), 
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            final newName = controller.text.trim();
            if (newName.isNotEmpty) {
              context.read<ChatProvider>().renameChatRoom(roomId, newName);
            }
            Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );
}


void showChatInitPopup(BuildContext context, List<String> botTypes, [String? username]) {
  final controller = TextEditingController();
  String selectedBot = botTypes[0];

  showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) {
        return AlertDialog(
          title: const Text('Initialise Chat'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                autofocus: true,
                decoration: const InputDecoration(hintText: "Enter a name for the chat"),
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                initialValue:  selectedBot,
                decoration: const InputDecoration(labelText: 'Bot Type'),
                items: botTypes.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value.split('_').last),
                    );
                  }).toList(),
                onChanged: (newVal){
                  setDialogState(() {
                      selectedBot = newVal!;
                    });
                },
              )
            ]),
          
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), 
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final newName = controller.text.trim();
                if(!context.mounted) return;
                if (newName.isNotEmpty) {
                  context.read<ChatProvider>().createNewChat(newName, selectedBot);
                }
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      }
    )
  );
}

