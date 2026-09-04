import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AiChatFab extends StatefulWidget {
  const AiChatFab({super.key});

  @override
  State<AiChatFab> createState() => _AiChatFabState();
}

class _AiChatFabState extends State<AiChatFab> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _scaleAnim = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnim,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF006D38).withOpacity(0.4),
              blurRadius: 16,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton(
          heroTag: 'ai_chat_fab',
          onPressed: () {
            context.push('/ai-chat');
          },
          backgroundColor: const Color(0xFF006D38),
          elevation: 4,
          shape: const CircleBorder(),
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 28),
              Positioned(
                right: 2,
                top: 2,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
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
