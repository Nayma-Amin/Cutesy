import 'package:flutter/material.dart';

class SlidingText extends StatefulWidget {
  final String text;
  final double speed;

  const SlidingText({super.key, required this.text, this.speed = 50});

  @override
  State<SlidingText> createState() => _SlidingTextState();
}

class _SlidingTextState extends State<SlidingText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Animation<double>? _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.speed.toInt()),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.text.isNotEmpty) {
        _recalculateAnimation();
      }
    });
  }

  void _recalculateAnimation() {
    final textPainter = TextPainter(
      text: TextSpan(
        text: widget.text,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      maxLines: 1,
      textScaleFactor: MediaQuery.of(context).textScaleFactor,
      textDirection: TextDirection.ltr,
    )..layout();

    final textWidth = textPainter.width;
    final screenWidth = MediaQuery.of(context).size.width;

    _animation = Tween<double>(
      begin: screenWidth,
      end: -textWidth - 20,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.linear));

    _controller
      ..reset()
      ..repeat();
  }

  @override
  void didUpdateWidget(covariant SlidingText oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.text != widget.text && widget.text.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _recalculateAnimation();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_animation == null || widget.text.isEmpty) {
      return _container(const SizedBox.shrink());
    }

    return _container(
      ClipRect(
        child: AnimatedBuilder(
          animation: _animation!,
          builder: (_, child) {
            return Transform.translate(
              offset: Offset(_animation!.value, 0),
              child: child,
            );
          },
          child: OverflowBox(
            minWidth: 0,
            maxWidth: double.infinity,
            alignment: Alignment.centerLeft,
            child: Align(
              alignment: Alignment.center,
              child: Text(
                widget.text,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.visible,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _container(Widget child) {
    return Container(
      height: 40,
      width: double.infinity,
      color: Colors.purple.shade50,
      child: child,
    );
  }
}
