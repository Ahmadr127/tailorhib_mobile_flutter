import 'package:flutter/material.dart';

class DropdownField extends StatelessWidget {
  final String value;
  final VoidCallback onTap;
  final double borderRadius;
  final Color borderColor;

  const DropdownField({
    super.key,
    required this.value,
    required this.onTap,
    this.borderRadius = 8,
    this.borderColor = Colors.grey,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: borderColor.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  color: value.startsWith('Pilih') ? Colors.grey : Colors.black,
                ),
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}
