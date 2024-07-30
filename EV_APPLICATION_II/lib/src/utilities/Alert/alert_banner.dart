// alert_banner.dart
import 'package:flutter/material.dart';
import '../Seperater/gradientPainter.dart';

class AlertBanner extends StatelessWidget {
  final String message;
  final Color backgroundColor;
  final Color textColor;

  const AlertBanner({
    Key? key,
    required this.message,
    this.backgroundColor = Colors.red,
    this.textColor = Colors.white,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      color: backgroundColor,
      child: Text(
        message,
        style: TextStyle(color: textColor, fontSize: 16),
        textAlign: TextAlign.center,
      ),
    );
  }
}


class ErrorDetails extends StatelessWidget {
  final String? errorData;

  const ErrorDetails({Key? key, required this.errorData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: const BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center, // Center the content
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Error Details',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).popUntil((route) => route.isFirst); // Close the QR code scanner page and return to the Home Page
                },
              ),
            ],
          ),
          const SizedBox(height: 10), // Add spacing between the header and the green line
          CustomGradientDivider(),
          const SizedBox(height: 20), // Add spacing between the green line and the icon
          const Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 70,
          ),
          const SizedBox(height: 20),
          Text(
            errorData ?? 'An unknown error occurred.',
            style: const TextStyle(color: Colors.white70, fontSize: 20),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}

