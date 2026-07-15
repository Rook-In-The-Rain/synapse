import 'package:flutter/material.dart';
import '../signup_login_manager.dart';
import '../backend_connector.dart';

class QuoteCard extends StatefulWidget {
  const QuoteCard({super.key});

  @override
  State<QuoteCard> createState() => _QuoteCardState();
}

class _QuoteCardState extends State<QuoteCard> {
  late Future<Map<String, dynamic>> _quoteFuture;

  @override
  void initState() {
    super.initState();
    _quoteFuture = _getQuote();
  }

  Future<Map<String, dynamic>> _getQuote() async {
    final String token = await AuthManager().getIdToken() ?? "";
    return BackendService().getQuote(token);
  }
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return FutureBuilder<Map<String, dynamic>>(
      future: _quoteFuture, 
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildSkeleton(colorScheme);
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return _buildContent(context, "Stay focused!", "Synapse");
        }

        final data = snapshot.data!;
        return _buildContent(
          context, 
          data['quote'] ?? "Keep pushing!", 
          data['author'] ?? "Synapse"
        );
      },
    );
  }

  Widget _buildContent(BuildContext context, String text, String author) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: 320,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.onSurface.withAlpha(15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.onSurface.withAlpha(30),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.format_quote_rounded, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                "Daily Motivation Quote",
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colorScheme.onSurface.withAlpha(220),
              fontSize: 15,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              "— $author",
              style: TextStyle(
                color: colorScheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeleton(ColorScheme colorScheme) {
    return Container(
      width: 320,
      height: 140,
      decoration: BoxDecoration(
        color: colorScheme.onSurface.withAlpha(10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
    );
  }
}