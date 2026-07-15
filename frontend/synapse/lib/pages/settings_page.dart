import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/providers/appthemes_provider.dart';
import '../utils/signup_login_manager.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 800) {
            return Center(
              child: SizedBox(
                width: 700,
                child: _buildSettingsList(context, isMobile: false),
              ),
            );
          } else {
            return _buildSettingsList(context, isMobile: true);
          }
        },
      ),
    );
  }

  Widget _buildSettingsList(BuildContext context, {required bool isMobile}) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return ListView(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16.0 : 40.0,
        vertical: 20.0,
      ),
      children: [
        _sectionHeader("ACCOUNT"),
        
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Theme.of(context).dividerColor.withAlpha(26)),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            leading: const Icon(Icons.person_outline),
            title: const Text("Username", style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: const Text("Change your display name"),
            trailing: isMobile 
              ? const Icon(Icons.arrow_forward_ios, size: 16)
              : ElevatedButton(
                  onPressed: () => showUsernameChangePopup(context),
                  child: const Text("Change"),
                ),
            onTap: isMobile ? () => showUsernameChangePopup(context) : null,
          ),
        ),

        const SizedBox(height: 20),
        _sectionHeader("APPEARANCE"),

        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Theme.of(context).dividerColor.withAlpha(26)),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            leading: const Icon(Icons.palette_outlined),
            title: const Text("App Theme", style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text("Current: ${themeProvider.isDarkMode ? 'Dark Mode' : 'Light Mode'}"),
            trailing: SizedBox(
              width: 120,
              child: DropdownButtonFormField<String>(
                initialValue: themeProvider.isDarkMode ? 'dark' : 'light',
                decoration: const InputDecoration(
                  border: InputBorder.none, 
                ),
                items: const [
                  DropdownMenuItem(value: "dark", child: Text("Dark")),
                  DropdownMenuItem(value: "light", child: Text("Light")),
                ],
                onChanged: (value) {
                  if (value != null) {
                    if ((value == 'dark' && !themeProvider.isDarkMode) ||
                        (value == 'light' && themeProvider.isDarkMode)) {
                      themeProvider.toggleTheme();
                    }
                  }
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}

void showUsernameChangePopup(BuildContext context) {
  TextEditingController controller = TextEditingController();

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Change Username'),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: const InputDecoration(
          hintText: "Enter a new username",
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton( 
          onPressed: () {
            final newName = controller.text.trim();
            if (newName.isNotEmpty) {
              AuthManager().updateUsername(newName);
            }
            Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );
}