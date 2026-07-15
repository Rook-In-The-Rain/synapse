import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:markdown/markdown.dart' as md;

class UserChatBubble extends StatelessWidget {
  final String message;
  const UserChatBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
              bottomLeft: Radius.circular(16)),
        ),
        child: Text(
          message,
          style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontSize: 16),
        ),
      ),
    );
  }
}

class TypingPlaceholder extends StatefulWidget {
  const TypingPlaceholder({super.key});

  @override
  State<TypingPlaceholder> createState() => _TypingPlaceholderState();
}

class _TypingPlaceholderState extends State<TypingPlaceholder> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller.drive(CurveTween(curve: Curves.easeInOut)),
      child: Container(
        width: 80,
        height: 12,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.onSurface.withAlpha(40),
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}

class SynapseMarkdownConfig {
  static final md.ExtensionSet extensionSet = md.ExtensionSet(
    md.ExtensionSet.gitHubFlavored.blockSyntaxes,
    [
      md.EmojiSyntax(),
      ...md.ExtensionSet.gitHubFlavored.inlineSyntaxes,
      LatexSyntax(),
    ],
  );

  static final Map<String, MarkdownElementBuilder> builders = {
    'latex': LatexBuilder(),
  };
}

class AIChatBubble extends StatelessWidget {
  final String message;
  final bool isTyping;

  const AIChatBubble({
    super.key,
    required this.message,
    this.isTyping = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      margin: const EdgeInsets.only(right: 50, top: 4, bottom: 4, left: 10),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (message.isEmpty && isTyping)
            const TypingPlaceholder()
          else
            MarkdownBody(
              data: message, 
              selectable: true,
              extensionSet: SynapseMarkdownConfig.extensionSet,
              builders: SynapseMarkdownConfig.builders,
              styleSheet: MarkdownStyleSheet(
                p: TextStyle(
                  fontSize: 16,
                  color: colorScheme.onSurface,
                  height: 1.5,
                ),
                blockquote: TextStyle(
                  color: colorScheme.onSurface.withAlpha(200),
                  fontSize: 16,
                  fontStyle: FontStyle.italic,
                ),
                blockquoteDecoration: BoxDecoration(
                  color: colorScheme.primary.withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                  border: Border(
                    left: BorderSide(color: colorScheme.primary, width: 2),
                  ),
                ),
                listBullet: TextStyle(color: colorScheme.primary),
              ),
            ),
        ],
      ),
    );
  }
}

class LatexSyntax extends md.InlineSyntax {
  LatexSyntax() : super(r'(\${1,2})([^\$]+?)\1([.,;:!?)])?');

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    final equation = match.group(2)!.trim();
    final isDisplay = match.group(1) == r'$$';
    final trailingPunctuation = match.group(3) ?? '';

    final element = md.Element.text('latex', equation);
    if (isDisplay) element.attributes['display'] = 'true';
    element.attributes['punctuation'] = trailingPunctuation;

    parser.addNode(element);
    return true;
  }
}

class LatexBuilder extends MarkdownElementBuilder {
  @override
  Widget visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    final text = element.textContent;
    final isDisplay = element.attributes['display'] == 'true';
    final punctuation = element.attributes['punctuation'] ?? '';

    final Widget mathWidget = Math.tex(
      text,
      mathStyle: isDisplay ? MathStyle.display : MathStyle.text,
      textStyle: preferredStyle?.copyWith(
        fontSize: isDisplay ? 20 : 16,
        fontFamily: 'Roboto',
      ),
    );

    if (isDisplay) {
      return Container(
        width: double.infinity,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: mathWidget,
      );
    }

    return Text.rich(
      TextSpan(
        children: [
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: mathWidget,
          ),
          TextSpan(text: punctuation, style: preferredStyle),
        ],
      ),
    );
  }
}