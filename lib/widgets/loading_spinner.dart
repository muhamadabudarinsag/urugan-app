import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class LoadingSpinner extends StatelessWidget {
  final Color color;
  final double size;

  const LoadingSpinner({super.key, required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return SpinKitWave(
      color: color,
      size: size,
    );
  }
}
