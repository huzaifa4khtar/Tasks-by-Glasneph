import 'package:flutter/material.dart';

class TopNotchBar extends StatelessWidget {
  final Color color;

  const TopNotchBar({super.key, this.color = Colors.transparent});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        color: color,
        height: MediaQuery.of(context).padding.top,
      ),
    );
  }
}
