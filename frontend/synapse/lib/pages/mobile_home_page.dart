import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/signup_login_manager.dart';
import '../utils/app_themes.dart';
import '../utils/providers/appthemes_provider.dart';
import '../utils/providers/chat_list_provider.dart';
import '../utils/widgets/popup_menu_widgets.dart';
import '../utils/widgets/bottom_home_page_bar.dart';
import '../utils/widgets/countdown_neet.dart';
import '../utils/widgets/quote_builder.dart';

class MobileHomePage extends StatefulWidget {
  const MobileHomePage({super.key});

  @override
  State<MobileHomePage> createState() => _HomePageState();
}

class _HomePageState extends State<MobileHomePage> {
  String? _username;

  @override
  void initState() {
    super.initState();
    _loadUsername();
    dynamic currUser = AuthManager().currUser;
    Provider.of<ChatProvider>(context, listen: false).initialize(currUser.uid);
  }

  void _loadUsername() async {
    try {
      _username = await AuthManager().getUsername();
      setState(() {});
    } catch (e) {
      _username = "User";
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final bool isDarkMode = themeProvider.isDarkMode;

    final List<Color> bgGradient = isDarkMode
        ? [const Color(0xFF0D0D19), const Color(0xFF1A1A3A)]
        : [const Color(0xFFF0F2F5), const Color(0xFFE0E2E5)];

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'SYNAPSE',
          style: GoogleFonts.poppins(
            fontSize: MediaQuery.of(context).size.width < 600 ? 28 : 40,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: bgGradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 800) {
              return SingleChildScrollView(
                padding: const EdgeInsets.only(top: 120, left: 20, right: 20, bottom: 20),
                child: Column(
                  children: [
                    _buildButtonSection(context, isDarkMode),
                    const SizedBox(height: 40),
                    _buildInfoSection(),
                  ],
                ),
              );
            } else {
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: constraints.maxWidth * 0.05),
                child: Row(
                  children: [
                    Expanded(flex: 2, child: _buildButtonSection(context, isDarkMode)),
                    Expanded(flex: 1, child: _buildInfoSection()),
                  ],
                ),
              );
            }
          },
        ),
      ),
      bottomNavigationBar: BottomBar(username: _username ?? "User"),
    );
  }

  Widget _buildButtonSection(BuildContext context, bool isDarkMode) {
    final primaryGradient = isDarkMode ? AppThemes.darkPrimaryGradient : AppThemes.lightPrimaryGradient;
    final secondaryGradient = isDarkMode ? AppThemes.darkSecondaryGradient : AppThemes.lightSecondaryGradient;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 30),
        _gradientButton(
          context: context,
          text: 'Start New Learning Chat!',
          icon: Icons.chat_bubble_outline,
          colors: primaryGradient,
          onTap: () {
            final List<String> botTypes = ["AI_Biology", "AI_Chemistry", "AI_Physics"];
            showChatInitPopup(context, botTypes);
          },
        ),
        const SizedBox(height: 20),
        _gradientButton(
          context: context,
          text: 'Talk to a personalised AI!',
          icon: Icons.sentiment_satisfied_alt,
          colors: secondaryGradient,
          onTap: () {
            final List<String> botTypes = ["RI_Mentor"];
            showChatInitPopup(context, botTypes, _username);
          },
        ),
      ],
    );
  }

  Widget _buildInfoSection() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        NeetCountdown(),
        SizedBox(height: 24),
        QuoteCard(),
      ],
    );
  }

  Widget _gradientButton({
    required BuildContext context,
    required String text,
    required IconData icon,
    required List<Color> colors,
    required VoidCallback onTap,
  }) {
    bool isMobile = MediaQuery.of(context).size.width < 600;
    
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: isMobile ? double.infinity : null,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: colors),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  text,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: isMobile ? 16 : 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}