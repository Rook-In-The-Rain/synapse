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


class DesktopHomePage extends StatefulWidget { 
  const DesktopHomePage({super.key});

  @override
  State<DesktopHomePage> createState() => _HomePageState();
}

class _HomePageState extends State<DesktopHomePage> {
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
    } catch (_) {
      _username = "User";
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final bool isDarkMode = themeProvider.isDarkMode;

    final List<Color> primaryButtonGradientColors = isDarkMode ? AppThemes.darkPrimaryGradient : AppThemes.lightPrimaryGradient;
    final List<Color> secondaryButtonGradientColors = isDarkMode ? AppThemes.darkSecondaryGradient : AppThemes.lightSecondaryGradient;
    final List<Color> scaffoldBackgroundGradientColors = isDarkMode ? AppThemes.darkScaffoldBackgroundGradient: AppThemes.lightScaffoldBackgroundGradient; 


    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'SYNAPSE',
          style: GoogleFonts.poppins( 
            color: Theme.of(context).appBarTheme.foregroundColor,
            fontSize: 40,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: scaffoldBackgroundGradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width * 0.05),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center, 
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child:
                        GestureDetector(
                          onTap: () {
                            final List<String> botTypes = ["AI_Biology", "AI_Chemistry", "AI_Physics"];
                            showChatInitPopup(context, botTypes);
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16), 
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: primaryButtonGradientColors,
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(30.0),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withAlpha(int.parse((0.3 * 255).round().toString())),
                                  spreadRadius: 2,
                                  blurRadius: 7,
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.chat_bubble_outline, color: Colors.white),
                                SizedBox(width: 10),
                                Text(
                                  'Start New Learning Chat!',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(width: 10),
                                Icon(Icons.search, color: Colors.white),
                              ],
                            ),
                          ),
                        )
                    ),
                    const SizedBox(height: 20),
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                          onTap: () {
                            final List<String> botTypes = ["RI_Mentor"];
                            showChatInitPopup(context, botTypes, _username);
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16), 
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: secondaryButtonGradientColors,
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(30.0),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withAlpha(77),
                                  spreadRadius: 2,
                                  blurRadius: 7,
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min, 
                              children: [
                                Icon(Icons.sentiment_satisfied_alt, color: Colors.white),
                                SizedBox(width: 10),
                                Text(
                                  'Talk to a personalised AI!',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                    ),
                  ],
                ),
              ),

              Expanded(
                flex: 1,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Center(
                        child: const NeetCountdown(),
                    ),
                    SizedBox(height: 20),
                    QuoteCard()
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomBar(username: _username ?? "User"),
    );
  }
}