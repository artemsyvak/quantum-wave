import 'package:flutter/material.dart';

class WavePainter extends CustomPainter {
  final List<double> samples;

  WavePainter(this.samples);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.deepPurpleAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;


    List<double> haichik = [];

    for (int i = 0; i < samples.length; i++) {
      if(i % 441 == 0){
      haichik.add(samples[i]);
      }
    }

    final path = Path();
    Animatable curve = CurveTween(curve: Curves.easeInOut);
    final midHeight = size.height / 2;
    final widthStep = size.width / haichik.length;

    path.moveTo(0, midHeight);

    for (int i = 0; i < haichik.length; i++) {
      final x = i * widthStep;
      final y = midHeight - haichik[i] * midHeight;
      path.lineTo(x, y);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    // Only repaint if samples have changed significantly
    return samples != (oldDelegate as WavePainter).samples;
  }
}

class WaveAnimation extends StatefulWidget {
  final List<double> samples;

  const WaveAnimation({super.key, required this.samples});

  @override
  _WaveAnimationState createState() => _WaveAnimationState();
}

class _WaveAnimationState extends State<WaveAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  List<double> samples = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 100))
      ..repeat();

    _controller.addListener(() {
      setState(() {
        samples = widget.samples;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: WavePainter(samples),
      size: const Size(double.infinity, 200),
    );
  }
}
