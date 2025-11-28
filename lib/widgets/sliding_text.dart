import 'package:flutter/material.dart';

class SlidingText extends StatefulWidget {
  final String text;
  final double speed;

  const SlidingText({
    super.key,
    required this.text,
    this.speed = 30,
  });

  @override
  State<SlidingText> createState() => _SlidingTextState();
}

class _SlidingTextState extends State<SlidingText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: Duration(seconds: widget.speed.toInt()),
      vsync: this,
    )..repeat();

    _animation = Tween<Offset>(
      begin: const Offset(1, 0), // start just outside right
      end: const Offset(-1, 0),  // end just outside left
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.linear));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // full screen width
    final screenWidth = MediaQuery.of(context).size.width;

    return Center(
      child: Container(
        width: screenWidth, // full screen width
        height: 40,
        color: Colors.purple.shade50, // optional background
        child: ClipRect(
          child: SlideTransition(
            position: _animation,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                widget.text,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple,
                ),
                maxLines: 1, // ensure single line
                overflow: TextOverflow.visible,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
