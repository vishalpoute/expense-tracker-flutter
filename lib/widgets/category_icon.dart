import 'package:flutter/material.dart';

class CategoryIcon extends StatelessWidget {
  final String name;
  final Color? color;

  const CategoryIcon({super.key, required this.name, this.color});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/$name.png',
      scale: 2,
      color: color,
      errorBuilder: (context, error, stackTrace) => Icon(
        Icons.category,
        color: color,
        semanticLabel: 'Category',
      ),
    );
  }
}
