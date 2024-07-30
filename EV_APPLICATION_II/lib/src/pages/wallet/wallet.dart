import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../utilities/Seperater/gradientPainter.dart';

class WalletPage extends StatefulWidget {
  final String username;
  final int? userId;

  const WalletPage({super.key, required this.username, this.userId});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  late Razorpay _razorpay;
  double? walletBalance;
  double? _lastPaymentAmount; // Store the last payment amount
  final TextEditingController _amountController = TextEditingController(text: '500');

  List<Map<String, dynamic>> transactionDetails = []; // Define transactionDetails

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    fetchWallet(); // Fetch wallet balance when the page is initialized
    fetchTransactionDetails(); // Fetch transaction details
    _amountController.addListener(() {
      setState(() {}); // Update the UI whenever the text changes
    });
  }

  @override
  void dispose() {
    _razorpay.clear();
    _amountController.dispose();
    super.dispose();
  }

  // Method to set wallet balance
  void setWalletBalance(double balance) {
    setState(() {
      walletBalance = balance.toDouble(); // Convert integer to double
    });
  }

  // Function to fetch wallet balance
  void fetchWallet() async {
    int? user_id = widget.userId;

    try {
      var response = await http.post(
        Uri.parse('http://122.166.210.142:9098/wallet/FetchWalletBalance'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': user_id}),
      );

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        if (data['data'] != null) {
          setWalletBalance(data['data'].toDouble()); // Cast to double
        } else {
          print('Error: balance field is null');
        }
      } else {
        throw Exception('Failed to load wallet balance');
      }
    } catch (error) {
      print('Error fetching wallet balance: $error');
    }
  }

  // Function to set transaction details
  void setTransactionDetails(List<Map<String, dynamic>> value) {
    setState(() {
      transactionDetails = value;
    });
  }

  // Function to fetch transaction details
  void fetchTransactionDetails() async {
    String? username = widget.username;

    try {
      var response = await http.post(
        Uri.parse('http://122.166.210.142:9098/wallet/getTransactionDetails'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username}),
      );

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        if (data['value'] is List) {
          List<dynamic> transactionData = data['value'];
          List<Map<String, dynamic>> transactions = transactionData.map((transaction) {
            return {
              'status': transaction['status'],
              'amount': transaction['amount'],
              'time': transaction['time'],
            };
          }).toList();
          setTransactionDetails(transactions);
        } else {
          print('Error: transaction details format is incorrect');
        }
      } else {
        throw Exception('Failed to load transaction details');
      }
    } catch (error) {
      print('Error fetching transaction details: $error');
    }
  }

  void handlePayment(double amount) async {
    String? username = widget.username;
    const String currency = 'INR';
    try {
      var response = await http.post(
        Uri.parse('http://122.166.210.142:9098/wallet/createOrder'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'amount': amount, 'currency': currency}),
      );
      var data = json.decode(response.body);
      Map<String, dynamic> options = {
        'key': 'rzp_test_dcep4q6wzcVYmr',
        'amount': data['amount'],
        'currency': data['currency'],
        'name': 'Outdid Tech',
        'description': 'Wallet Recharge',
        'order_id': data['id'],
        'prefill': {'name': username},
        'theme': {'color': '#3399cc'},
      };
      _lastPaymentAmount = amount; // Store the amount

      _razorpay.open(options);
    } catch (error) {
      print('Error during payment: $error');
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    String? username = widget.username;

    try {
      Map<String, dynamic> result = {
        'user': username,
        'RechargeAmt': _lastPaymentAmount, // Use the stored amount
        'transactionId': response.orderId,
        'responseCode': 'SUCCESS',
        'date_time': DateTime.now().toString(),
      };

      var output = await http.post(
        Uri.parse('http://122.166.210.142:9098/wallet/savePayments'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(result),
      );

      var responseData = json.decode(output.body);
      if (responseData == 1) {
        print('Payment successful!');
        _showPaymentSuccessModal(result);
        
        setState(() {
          fetchWallet(); // Fetch wallet balance after successful payment
          fetchTransactionDetails(); // Fetch transaction details after successful payment
        });

      } else {
        print('Payment details not saved!');
      }
    } catch (error) {
      print('Error saving payment details: $error');
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    String? username = widget.username;
    Map<String, dynamic> paymentError = {
      'user': username,
      'RechargeAmt': _lastPaymentAmount, // Use the stored amount
      'message': response.message,
      'date_time': DateTime.now().toString(),
    };

    _showPaymentFailureModal(paymentError);
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    print('External Wallet: ${response.walletName}');
  }

  void _showPaymentSuccessModal(Map<String, dynamic> paymentResult) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      builder: (BuildContext context) {
        return Padding(
          padding: MediaQuery.of(context).viewInsets,
          child: PaymentSuccessModal(paymentResult: paymentResult),
        );
      },
    );
  }

  void _showPaymentFailureModal(Map<String, dynamic> paymentError) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      builder: (BuildContext context) {
        return Padding(
          padding: MediaQuery.of(context).viewInsets,
          child: PaymentFailureModal(paymentError: paymentError),
        );
      },
    );
  }

  double _calculateProgress() {
    const double maxLimit = 10000.0; // Updated max limit
    if (walletBalance != null && walletBalance! > 0) {
      return walletBalance! / maxLimit;
    }
    return 0.0;
  }

  String _getBalanceLevel() {
    double progress = _calculateProgress();
    if (progress < 0.33) {
      return 'Low';
    } else if (progress < 0.66) {
      return 'Medium';
    } else {
      return 'Full';
    }
  }

  Color _getBalanceColor() {
    double progress = _calculateProgress();
    if (progress < 0.33) {
      return Colors.red;
    } else if (progress < 0.66) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }

  void _showHelpModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      builder: (BuildContext context) {
        return Padding(
          padding: MediaQuery.of(context).viewInsets,
          child: const HelpModal(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.white),
            onPressed: _showHelpModal,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your Wallet',
              style: TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Fast, one-click payments\nSeamless charging',
              style: TextStyle(fontSize: 16, color: Colors.white70),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Balance',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        walletBalance != null ? '₹${walletBalance!.toStringAsFixed(2)}' : '₹0',
                        style: const TextStyle(fontSize: 32, color: Colors.white),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getBalanceColor(),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _getBalanceLevel(),
                          style: const TextStyle(fontSize: 14, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Max ₹10,000', // Updated max limit text
                    style: TextStyle(fontSize: 14, color: Colors.white70),
                  ),
                  const SizedBox(height: 16),
                  LinearProgressIndicator(
                    value: _calculateProgress(),
                    color: Colors.orange,
                    backgroundColor: Colors.white12,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Add money',
              style: TextStyle(fontSize: 18, color: Colors.white),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _amountController,
                      style: const TextStyle(color: Colors.white, fontSize: 18),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Enter amount',
                        hintStyle: TextStyle(color: Colors.white54),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: <TextInputFormatter>[
                        FilteringTextInputFormatter.digitsOnly
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.clear, color: Colors.white54),
                    onPressed: () {
                      _amountController.clear();
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    backgroundColor: Colors.white12,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    _amountController.text = '100';
                  },
                  child: const Text('₹100', style: TextStyle(color: Colors.white)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    backgroundColor: Colors.white12,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    _amountController.text = '500';
                  },
                  child: const Text('₹500', style: TextStyle(color: Colors.white)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    backgroundColor: Colors.white12,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    _amountController.text = '1000';
                  },
                  child: const Text('₹1,000', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                backgroundColor: Colors.white12,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                _amountController.text = '2000';
              },
              child: const Text('Maximum', style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: const Color(0xFF1C8B40),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                double amount = double.tryParse(_amountController.text) ?? 0.0;
                if (amount > 0) {
                  handlePayment(amount);
                } else {
                  // Handle invalid input or amount
                }
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Add ₹${_amountController.text}', style: const TextStyle(color: Colors.white, fontSize: 18)),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class PaymentSuccessModal extends StatelessWidget {
  final Map<String, dynamic> paymentResult;

  const PaymentSuccessModal({super.key, required this.paymentResult});

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Payment Success',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          CustomGradientDivider(),
          const SizedBox(height: 16),
          Center(
            child: Text(
              '₹${(paymentResult['RechargeAmt'] ?? 0).toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 48, color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 16),
          const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 32),
              SizedBox(width: 8),
              Text(
                'Completed',
                style: TextStyle(fontSize: 18, color: Colors.green),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "Payment should now be in ${paymentResult['user'] ?? ''}'s wallet ",
            style: const TextStyle(fontSize: 16, color: Colors.white70),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.grey.shade800, // Background color for the ListTile
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.grey.shade600,
                child: const Icon(Icons.account_circle, color: Colors.white, size: 40),
              ),
              title: Text(
                paymentResult['user'] ?? '',
                style: const TextStyle(fontSize: 18, color: Colors.white),
              ),
              subtitle: Text(
                DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.parse(paymentResult['date_time'] ?? DateTime.now().toString())),
                style: const TextStyle(fontSize: 16, color: Colors.white70),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.grey.shade800, // Background color for the ListTile
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.grey.shade600,
                child: const Icon(Icons.receipt_long, color: Colors.white, size: 40),
              ),
              title: const Text(
                'Transaction ID',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
              subtitle: Text(
                '${paymentResult['transactionId'] ?? ''}',
                style: const TextStyle(fontSize: 16, color: Colors.white70),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PaymentFailureModal extends StatelessWidget {
  final Map<String, dynamic> paymentError;

  const PaymentFailureModal({Key? key, required this.paymentError}) : super(key: key);

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Payment Failure',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          CustomGradientDivider(),
          const SizedBox(height: 16),
          Center(
            child: Text(
              '₹${(paymentError['RechargeAmt'] ?? 0).toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 48, color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 16),
          const Row(
            children: [
              Icon(Icons.error, color: Colors.red, size: 32),
              SizedBox(width: 8),
              Text(
                'Failed',
                style: TextStyle(fontSize: 18, color: Colors.red),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            paymentError['message'] ?? 'Unknown error occurred.',
            style: const TextStyle(fontSize: 16, color: Colors.white70),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.grey.shade800, // Background color for the ListTile
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.grey.shade600,
                child: const Icon(Icons.account_circle, color: Colors.white, size: 40),
              ),
              title: Text(
                paymentError['user'] ?? '',
                style: const TextStyle(fontSize: 18, color: Colors.white),
              ),
              subtitle: Text(
                DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.parse(paymentError['date_time'] ?? DateTime.now().toString())),
                style: const TextStyle(fontSize: 16, color: Colors.white70),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.grey.shade800, // Background color for the ListTile
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.grey.shade600,
                child: const Icon(Icons.receipt_long, color: Colors.white, size: 40),
              ),
              title: const Text(
                'Transaction ID',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
              subtitle: Text(
                '${paymentError['transactionId'] ?? ''}',
                style: const TextStyle(fontSize: 16, color: Colors.white70),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class HelpModal extends StatelessWidget {
  const HelpModal({Key? key}) : super(key: key);

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Wallet Help',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          CustomGradientDivider(),
          const SizedBox(height: 16),
          const Text(
            'How to use the Wallet',
            style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            '1. Add Money: Use the "Add Money" section to recharge your wallet. Enter the amount and click "Add ₹".\n'
            '2. Balance: View your current wallet balance and its level (Low, Medium, Full).\n'
            '3. Transaction History: Check your recent transactions and their status (Credited, Debited).\n'
            '4. Payment Methods: Use Razorpay for secure and quick transactions.\n'
            '5. Max Limit: The wallet has a maximum limit of ₹10,000.',
            style: TextStyle(fontSize: 16, color: Colors.white70),
          ),
          const SizedBox(height: 16),
          const Text(
            'Need More Help?',
            style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'For further assistance, contact our support team at support@outdidtech.com.',
            style: TextStyle(fontSize: 16, color: Colors.white70),
          ),
        ],
      ),
    );
  }
}
