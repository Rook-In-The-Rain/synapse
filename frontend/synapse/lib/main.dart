import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '/utils/providers/chat_list_provider.dart';
import '/utils/widgets/popup_menu_widgets.dart';
import '/utils/widgets/mobile_desktop_switcher.dart';
import '/utils/providers/gorouter_stream_provider.dart';
import '/utils/signup_login_manager.dart';
import '/utils/providers/appthemes_provider.dart';
import '/utils/app_themes.dart';
import '/pages/desktop_home_page.dart';
import '/pages/mobile_home_page.dart';
import '/pages/ai_chat_page.dart';
import '/pages/ri_chat_page.dart';
import '/pages/login_page.dart';
import '/pages/signup_page.dart';
import '/pages/settings_page.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform
  );

  runApp(Synapse());
}

class Synapse extends StatelessWidget {
  Synapse({super.key});
  final _router = GoRouter(
  initialLocation: '/login',
  refreshListenable: GoRouterRefreshStream(FirebaseAuth.instance.authStateChanges()),

  redirect: (context, state) {
    final user = FirebaseAuth.instance.currentUser;
    final bool loggedIn = user != null;
    final bool loggingIn = (state.matchedLocation == '/login') || (state.matchedLocation == '/signup');

    if (!loggedIn && !loggingIn) return '/signup';

    if (loggedIn && loggingIn) return '/';

    return null;
  },
  routes: [
    ShellRoute(
      builder: (context, state, child) {
          return Consumer<ChatProvider>(
            builder: (context, chatProvider, _) {
              final colorScheme = Theme.of(context).colorScheme;

               String getTitle() {
                final chatId = state.pathParameters['chatId'];
                if (chatId != null) {
                  final room = chatProvider.getChatbyId(chatId);
                  return room.headers.title;
                }
                if (state.matchedLocation == "/settings") return 'Settings';
                return '';
              }

              return Scaffold(
                extendBodyBehindAppBar: true,
                appBar: AppBar(
                  title: Text(getTitle(), style: const TextStyle(fontWeight: FontWeight.w600)), centerTitle: true,
                  elevation: 0,
                  scrolledUnderElevation: 0,
                  ),
                drawer: Drawer(
                        backgroundColor: colorScheme.surface,
                        child: Column(
                          children: [
                            Container(
                              height: 100,
                              decoration: BoxDecoration(color: colorScheme.primary),
                              alignment: Alignment.bottomRight,
                              padding: EdgeInsets.all(16),
                              child: Text('Menu', style: TextStyle(color: colorScheme.onPrimary, fontSize: 24)),
                            ),

                            Expanded(
                              child: Consumer<ChatProvider>(
                                builder: (context, chatProvider, child) => ListView(
                                  padding: EdgeInsets.zero,
                                  children: [
                                    ListTile(
                                      leading: Icon(Icons.home, color: colorScheme.onSurface),
                                      title: Text('Home', style: TextStyle(color: colorScheme.onSurface)),
                                      onTap: () {
                                        context.go('/');
                                        Navigator.pop(context); 
                                      },
                                    ),
                                    ...chatProvider.chatRooms.map((chatRoom) => HoverableChatTile(
                                      title: chatRoom.headers.title,
                                      onTap: () async {
                                        Navigator.pop(context);
                                        await Provider.of<ChatProvider>(context, listen: false).loadChatHistory(chatRoom.id);
                                        if (!context.mounted) return;
                                        if(chatRoom.headers.botType.startsWith("R")){
                                          context.go('/RIchat/${chatRoom.id}');
                                        }
                                        else{
                                          context.go('/AIchat/${chatRoom.id}');
                                        }
                                      },
                                      chatRoom: chatRoom
                                    )
    
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            Divider(color: colorScheme.onSurface.withAlpha(24), height: 1), 
                            SafeArea(
                              top: false,
                              child: Column(
                                children: [
                                  ListTile(
                                    leading: Icon(Icons.settings, color: colorScheme.onSurface),
                                    title: Text('Settings', style: TextStyle(color: colorScheme.onSurface)),
                                    onTap: () {
                                      context.go('/settings');
                                      Navigator.pop(context);
                                    },
                                  ),
                                  ListTile(
                                    leading: Icon(Icons.logout, color: colorScheme.error),
                                    title: Text('Log Out', style: TextStyle(color: colorScheme.error)),
                                    onTap: () {
                                      AuthManager().logOut();
                                      Navigator.pop(context);
                                      context.go('/login');
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                body: child,
            );
            }
          );
      },
      
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => ResponsiveLayout(mobileBody: MobileHomePage(), desktopBody: DesktopHomePage())
        ),
        GoRoute(
          path: '/AIchat/:chatId',
          builder: (context, state) => AIChatPage(key: ValueKey(state.pathParameters['chatId']!), chatId: state.pathParameters['chatId']!)
        ),
        GoRoute(
          path: '/RIchat/:chatId',
          builder: (context, state) => RIChatPage(key: ValueKey(state.pathParameters['chatId']!), chatId: state.pathParameters['chatId']!)
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => SettingsPage()
        )
      ]
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => LoginPage(),
    ),
    GoRoute(
      path: '/signup',
      builder: (context, state) => SignupPage(),
    ),
  ]
);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider())
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProv, _) => MaterialApp.router(
          debugShowCheckedModeBanner: false,
          title: 'Synapse',
          theme: AppThemes.lightTheme,
          darkTheme: AppThemes.darkTheme,
          themeMode: themeProv.themeMode,
          routerConfig: _router,
        ),
      ),
    );
  }
}