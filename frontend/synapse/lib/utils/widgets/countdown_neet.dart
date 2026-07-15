import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; 
import 'dart:async';
import 'package:provider/provider.dart';
import '../providers/appthemes_provider.dart';

class NeetCountdown extends StatefulWidget {
  const NeetCountdown({super.key});

  @override
  State<NeetCountdown> createState() => _NeetCountdownState();
}

class _NeetCountdownState extends State<NeetCountdown> {
  late Timer _timer;
  late Duration _timeRemaining;

  final DateTime _neetDate = DateTime(2027, DateTime.may, 2);

  @override
  void initState() {
    super.initState();
    _calculateTimeRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _calculateTimeRemaining();
    });
  }

  void _calculateTimeRemaining() {
    final DateTime now = DateTime.now();
    setState(() {
      _timeRemaining = _neetDate.difference(now);
      if (_timeRemaining.isNegative) {
        _timeRemaining = Duration.zero;
        _timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    int days = duration.inDays;
    int hours = duration.inHours.remainder(24);
    int minutes = duration.inMinutes.remainder(60);
    int seconds = duration.inSeconds.remainder(60);

    return '$days Days\n${twoDigits(hours)}:${twoDigits(minutes)}:${twoDigits(seconds)}';
  }

  @override
  Widget build(BuildContext context) {
    
    if (_timeRemaining == Duration.zero) {
      return _buildClockDisplay('NEET Passed!');
    }
    return _buildClockDisplay(_formatDuration(_timeRemaining));
  }

  Widget _buildClockDisplay(String timeString) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final bool isDarkMode = themeProvider.isDarkMode;
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    final Color clockBorderColor = isDarkMode ? Colors.cyan.withAlpha(179) : colorScheme.primary;
    final Color clockTextColor = isDarkMode ? Colors.white : colorScheme.onSurface;
    final Color stayFocusedTextColor = isDarkMode ? Colors.white.withAlpha(138) : colorScheme.onSurface.withAlpha(138);
    return Container(
      width: 180, 
      height: 180,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: clockBorderColor, width: 3), 
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              timeString,
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat( 
                color: clockTextColor,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'NEET Countdown!',
              style: TextStyle(color: stayFocusedTextColor, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}