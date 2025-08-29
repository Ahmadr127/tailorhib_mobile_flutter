import 'package:flutter/material.dart';

class LabelText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final double bottomPadding;

  const LabelText({
    super.key,
    required this.text,
    this.style,
    this.bottomPadding = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: Text(
        text,
        style: style ??
            const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
      ),
    );
  }
}
