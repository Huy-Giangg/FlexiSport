import 'package:flutter/material.dart';

class QuickPromptsWidget extends StatelessWidget {
  final List<String> prompts;
  final ValueChanged<String> onSelected;

  const QuickPromptsWidget({
    super.key,
    required this.prompts,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (prompts.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 44,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: prompts.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final prompt = prompts[index];
          return ActionChip(
            label: Text(
              prompt,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF0F172A),
              ),
            ),
            backgroundColor: const Color(0xFFF1F5F9),
            side: BorderSide(color: Colors.grey.shade300, width: 0.8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 0,
            pressElevation: 1,
            onPressed: () => onSelected(prompt),
          );
        },
      ),
    );
  }
}
