// المسار: lib/screens/TransactionScreen.dart

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/gestures.dart';
import '../api/zaincash_service.dart';
import '../widgets/custom_dialog.dart';

class TransactionScreen extends StatefulWidget {
  const TransactionScreen({Key? key}) : super(key: key);

  @override
  _TransactionScreenState createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen> {
  final ZainCashService _zainCashService = ZainCashService();
  bool _isLoading = false;
  Map<String, dynamic>? transactionData;

  // دالة لعرض إشعار باستخدام SnackBar
  void _showSnackBar(String message, {bool isError = false}) {
    final snackBar = SnackBar(
      content: Text(
        message,
        style: const TextStyle(fontSize: 16, color: Colors.white),
      ),
      backgroundColor: isError ? Colors.redAccent : Colors.green,
      duration: const Duration(seconds: 3),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  // دالة لإنشاء معاملة جديدة
  Future<void> _createTransaction() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _zainCashService.createTransaction(
        amount: "250",
        serviceType: "A book",
        orderId: "Bill_1234567890",
        context: context,
      );
      _showSnackBar('تم إنشاء المعاملة بنجاح');
    } catch (e) {
      _showSnackBar('فشل في إنشاء المعاملة', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // دالة للتحقق من حالة المعاملة وعرض البيانات في Dialog
  Future<void> _checkTransactionStatus() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final Map<String, dynamic> result =
          await _zainCashService.checkTransactionStatus(context);

      setState(() {
        transactionData = result['to'];
      });

      if (transactionData != null) {
        _showSnackBar('تم التحقق من حالة المعاملة');
        _showTransactionDetailsDialog();
      } else {
        _showSnackBar('لم يتم العثور على بيانات المعاملة', isError: true);
      }
    } catch (e) {
      _showSnackBar('فشل في التحقق من حالة المعاملة', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // دالة لتنظيف البيانات المخزنة
  Future<void> _clearStorage() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _zainCashService.clearStorage();
      _showSnackBar('تم تنظيف البيانات بنجاح');
    } catch (e) {
      _showSnackBar('فشل في تنظيف البيانات', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // دالة لعرض تفاصيل المعاملة في Dialog
  void _showTransactionDetailsDialog() {
    if (transactionData == null) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            "تفاصيل المعاملة",
            style: TextStyle(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTransactionDetail("الاسم", transactionData!['name']),
                _buildTransactionDetail(
                    "رقم الهاتف", transactionData!['msisdn'].toString()),
                _buildTransactionDetail("العملة", transactionData!['currency']),
                _buildTransactionDetail(
                    "تاريخ الإنشاء", transactionData!['createdAt']),
                _buildTransactionDetail(
                    "تاريخ التحديث", transactionData!['updatedAt']),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("إغلاق",
                  style: TextStyle(color: Colors.blueAccent)),
            ),
          ],
        );
      },
    );
  }

  // دالة لإنشاء عرض للبيانات
  Widget _buildTransactionDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            "$label: ",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  // دالة لإنشاء الأزرار
  Widget _buildButton({
    required String label,
    required Color color,
    required VoidCallback onPressed,
    IconData? icon,
  }) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 5,
        shadowColor: Colors.black45,
      ),
      onPressed: onPressed,
      icon: icon != null ? Icon(icon, size: 24, color: Colors.black) : const SizedBox.shrink(),
      label: Text(
        label,
        style: const TextStyle(fontSize: 18 , fontWeight: FontWeight.bold, color: Colors.white),
      ),
    );
  }

  // دالة لفتح رابط Instagram
  void _launchInstagram() async {
    final Uri url = Uri.parse('https://www.instagram.com/od_331');
    if (!await launchUrl(url)) {
      _showSnackBar('تعذر فتح Instagram', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    // تحديد الاتجاه العام للتطبيق (من اليمين إلى اليسار)
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          title: const Text(
            "بوابة الدفع ZainCash",
            style: TextStyle(
                fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          centerTitle: true,
          backgroundColor: Colors.blueGrey[800],
          elevation: 4,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(30),
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(vertical: 5),
              color: Colors.blueGrey[700],
              child: const Text(
                "هذا التطبيق تجريبي",
                style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFFFF6933),
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                if (_isLoading)
                  const CircularProgressIndicator()
                else ...[
                  _buildButton(
                    label: "إنشاء معاملة وفتح نافذة الدفع",
                    color: Colors.blueAccent,
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return CustomDialog(
                            message: "هل تريد تأكيد الدفع؟",
                            onConfirm: () async {
                              Navigator.of(context).pop();
                              await _createTransaction();
                            },
                          );
                        },
                      );
                    },
                    icon: Icons.payment,
                  ),
                  const SizedBox(height: 20),
                  _buildButton(
                    label: "التحقق من حالة المعاملة المخزنة",
                    color: Colors.green,
                    onPressed: () async {
                      await _checkTransactionStatus();
                    },
                    icon: Icons.check_circle,
                  ),
                  const SizedBox(height: 20),
                  _buildButton(
                    label: "تنظيف التخزين",
                    color: Colors.redAccent,
                    onPressed: () async {
                      await _clearStorage();
                    },
                    icon: Icons.delete_forever,
                  ),
                  const SizedBox(height: 40),
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(15.0),
                      child: RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          children: [
                            const TextSpan(
                              text: 'By Ahmed Majid Developer\n',
                              style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.black87,
                                  fontWeight: FontWeight.bold),
                            ),
                            TextSpan(
                              text: 'Instagram: od_331',
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.blueAccent,
                                decoration: TextDecoration.underline,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = _launchInstagram,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
