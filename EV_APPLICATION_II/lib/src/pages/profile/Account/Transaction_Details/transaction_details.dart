import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../utilities/Seperater/gradientPainter.dart';
class TransactionDetailsWidget extends StatelessWidget {
  final List<Map<String, dynamic>> transactionDetails;
  final String username;
  final int? userId;


  const TransactionDetailsWidget({Key? key,required this.username, this.userId, required this.transactionDetails}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return transactionDetails.isEmpty
        ? Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(20.0),
            child: const Center(
              child: Text(
                'No transaction history found.',
                style: TextStyle(fontSize: 18, color: Colors.red),
              ),
            ),
          )
        : Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                for (int index = 0; index < transactionDetails.length; index++)
                  Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(5.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    transactionDetails[index]['status'],
                                    style: const TextStyle(
                                      fontSize: 20,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    DateFormat('MM/dd/yyyy, hh:mm:ss a').format(
                                      DateTime.parse(transactionDetails[index]['time']).toLocal(),
                                    ),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.white60,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${transactionDetails[index]['status'] == 'Credited' ? '+ ₹' : '- ₹'}${transactionDetails[index]['amount']}',
                              style: TextStyle(
                                fontSize: 19,
                                color: transactionDetails[index]['status'] == 'Credited' ? Colors.green : Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (index != transactionDetails.length - 1) CustomGradientDivider(),
                    ],
                  ),
              ],
            ),
          );
  }
}
