import 'package:flutter/material.dart';

/// Widget de texto animado que rola horizontalmente quando o texto é muito longo
class MarqueeText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final Duration duration;
  final Duration pauseDuration;

  const MarqueeText({
    Key? key,
    required this.text,
    this.style,
    this.duration = const Duration(seconds: 8),
    this.pauseDuration = const Duration(seconds: 2),
  }) : super(key: key);

  @override
  State<MarqueeText> createState() => _MarqueeTextState();
}

class _MarqueeTextState extends State<MarqueeText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.linear,
    ));

    // Iniciar animação com delay
    Future.delayed(widget.pauseDuration, () {
      if (mounted) {
        _startAnimation();
      }
    });
  }

  void _startAnimation() {
    _controller.repeat(
      period: widget.duration + widget.pauseDuration,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final textPainter = TextPainter(
          text: TextSpan(text: widget.text, style: widget.style),
          textDirection: TextDirection.ltr,
          maxLines: 1,
        );
        textPainter.layout();

        // Se o texto cabe no espaço disponível, não animar
        if (textPainter.width <= constraints.maxWidth) {
          return Text(
            widget.text,
            style: widget.style,
            maxLines: 1,
          );
        }

        // Caso contrário, animar o texto
        final double textWidth = textPainter.width;
        final double containerWidth = constraints.maxWidth;
        final double scrollDistance = textWidth - containerWidth;

        return ClipRect(
          child: AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(
                  -scrollDistance * _animation.value,
                  0,
                ),
                child: SizedBox(
                  width: textWidth,
                  child: Text(
                    widget.text,
                    style: widget.style,
                    maxLines: 1,
                    textAlign: TextAlign.left,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

/// Widget de Tab personalizada com texto marquee
class MarqueeTab extends StatelessWidget {
  final String text;
  final Icon? icon;

  const MarqueeTab({
    Key? key,
    required this.text,
    this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Tab(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            icon!,
            const SizedBox(height: 4),
          ],
          Expanded(
            child: Center(
              child: MarqueeText(
                text: text,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                duration: const Duration(seconds: 6),
                pauseDuration: const Duration(seconds: 3),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
