import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// Features
import 'features/mood_input/ui/mood_input_screen.dart';
import 'features/calendar/ui/calendar_screen.dart';
import 'features/weekly_mood/ui/weekly_mood_screen.dart';
import 'features/reminder/ui/reminder_screen.dart';
import 'features/login/ui/login.dart';

// Session
import 'session_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await initializeDateFormatting('es_ES', null);

  final session = await SessionManager.getSession();

  runApp(MyApp(startAtHome: session != null));
}

class MyApp extends StatelessWidget {
  final bool startAtHome;
  const MyApp({super.key, required this.startAtHome});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Mood Tracker 💚',
      theme: ThemeData(
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: Colors.green,
          unselectedItemColor: Colors.grey,
        ),
      ),
      // Si hay sesión guardada → va directo a MainNavigation (tab 0)
      home: startAtHome
          ? const MainNavigation(initialIndex: 0)
          : const LoginScreen(),
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key, this.initialIndex = 1});
  final int initialIndex;

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  final List<Widget> _screens = const [
    MoodInputScreen(),
    CalendarScreen(),
    MoodStatsScreen(),
    ReminderScreen(),
  ];

  void _onItemTapped(int index) => setState(() => _selectedIndex = index);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.emoji_emotions), label: 'Estado Ánimo'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Calendario'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Estadísticas'),
          BottomNavigationBarItem(icon: Icon(Icons.alarm), label: 'Recordatorios'),
        ],
      ),
    );
  }
}
