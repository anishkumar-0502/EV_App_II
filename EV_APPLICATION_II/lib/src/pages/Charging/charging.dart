import 'package:flutter/material.dart';

class Charging extends StatefulWidget {
  final String? searchChargerID;
  final String? username;

  const Charging({super.key, required this.username, this.searchChargerID});

  @override
  State<Charging> createState() => _ChargingPageState();
}

class _ChargingPageState extends State<Charging> with TickerProviderStateMixin {
  late AnimationController _controller;
  final double _currentTemperature = 26;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getTemperatureColor() {
    if (_currentTemperature < 30) {
      return Colors.green;
    } else if (_currentTemperature < 50) {
      return const Color.fromARGB(255, 209, 99, 16);
    } else {
      return Colors.red;
    }
  }

  Widget _buildAnimatedTempColorCircle() {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: 160,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: SweepGradient(
              colors: [
                _getTemperatureColor().withOpacity(0.6),
                _getTemperatureColor(),
                _getTemperatureColor().withOpacity(0.6),
              ],
              stops: [0.0, _controller.value, 1.0],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade900,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${_currentTemperature.toInt()}',
                      style: TextStyle(color: _getTemperatureColor(), fontSize: 24),
                    ),
                    Text(
                      '°C',
                      style: TextStyle(color: _getTemperatureColor(), fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 23),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.grey),
                  onPressed: () {
                    Navigator.of(context).pop(); // Navigate back
                  },
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.settings, color: Colors.grey),
                      onPressed: () {
                        // Add settings functionality here
                      },
                    ),
                    const Row(
                      children: [
                        Icon(Icons.help_outline, color: Colors.green),
                        SizedBox(width: 8),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 450),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildCustomCard(
                  _buildAnimatedPowerButton(),
                ),
                _buildCustomCard(
                  _buildCustomTemperatureControl(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomCard(Widget child) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            spreadRadius: 2,
            blurRadius: 5,
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildAnimatedPowerButton() {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: SweepGradient(
              colors: const [Colors.orange, Colors.red, Colors.orange],
              stops: [0.0, _controller.value, 1.0],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade900,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.power_settings_new, color: Colors.white, size: 32),
                onPressed: () {},
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCustomTemperatureControl() {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Current t°',
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              '${_currentTemperature.toInt()} °C',
              style: const TextStyle(color: Colors.white, fontSize: 24),
            ),
          ],
        ),
        const SizedBox(width: 8),
        _buildAnimatedTempColorCircle(),
      ],
    );
  }
}

class TemperatureDialPainter extends CustomPainter {
  final Color color;

  TemperatureDialPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..shader = LinearGradient(
        colors: [color.withOpacity(0.6), color],
      ).createShader(Rect.fromCircle(center: Offset(size.width / 2, size.height / 2), radius: size.width / 2))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6;

    const double startAngle = -3.14 / 2;
    const double sweepAngle = 3.14;

    canvas.drawArc(Rect.fromLTWH(0, 0, size.width, size.height), startAngle, sweepAngle, false, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

void main() {
  runApp(const MaterialApp(
    home: Charging(username: 'User123', searchChargerID: 'ChargerXYZ'),
  ));
}
