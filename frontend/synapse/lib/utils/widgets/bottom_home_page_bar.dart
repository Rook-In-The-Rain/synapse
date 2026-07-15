import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/appthemes_provider.dart';

class BottomBar extends StatelessWidget {
  final String username;

  const BottomBar({super.key, required this.username});

  String _getFirstLetter(String name) {
    if (name.isEmpty) return '';
    return name[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bool isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;

    final Color backgroundColor = isDarkMode ? Color(0xFF1E2738) : colorScheme.surface;
    final Color textColor = isDarkMode ? Colors.white70 : colorScheme.onSurfaceVariant;
    final Color avatarBackgroundColor = isDarkMode ? colorScheme.primary.withAlpha(179) : colorScheme.primaryContainer;
    final Color avatarTextColor = isDarkMode ? Colors.white : colorScheme.onPrimaryContainer;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border(
          top: BorderSide(
            color: isDarkMode ? Colors.white.withAlpha(26) : Colors.grey.shade300,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: avatarBackgroundColor,
                child: Text(
                  _getFirstLetter(username),
                  style: TextStyle(
                    color: avatarTextColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    username,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'NEET 2026 Aspirant',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: textColor.withAlpha(179),
                    ),
                  ),
                ],
              ),
            ],
          )
        ],
      ),
    );
  }
}