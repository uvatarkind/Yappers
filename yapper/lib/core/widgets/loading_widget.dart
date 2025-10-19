import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class YapperLoadingWidget extends StatelessWidget {
  final double size;
  final Color color;

  const YapperLoadingWidget({
    Key? key,
    this.size = 50,
    this.color = Colors.purple,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: LoadingAnimationWidget.inkDrop(
        color: color,
        size: size,
      ),
    );
  }
}
