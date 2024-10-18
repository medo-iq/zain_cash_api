import 'dart:convert';

import 'package:crypto/crypto.dart'; // مكتبة تشفير
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

import '../screens/webview_screen.dart'; // استدعاء شاشة WebView
import 'config.dart'; // استدعاء ملف الإعدادات
import 'dio_client.dart';
import 'storage_service.dart'; // استدعاء خدمة التخزين

class ZainCashService {
  final DioClient _dioClient = DioClient();
  final StorageService _storageService = StorageService();
  final Logger _logger = Logger(
    printer: PrettyPrinter(colors: true),
  );

  // توليد JWT لطلب createTransaction
  String generateTransactionJWT({
    required String amount,
    required String serviceType,
    required String msisdn,
    required String orderId,
    required String redirectUrl,
    required String secret,
  }) {
    final payload = {
      'amount': amount,
      'serviceType': serviceType,
      'msisdn': msisdn,
      'orderId': orderId,
      'redirectUrl': redirectUrl,
      'iat': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'exp': DateTime.now().millisecondsSinceEpoch ~/ 1000 + 60 * 60,
    };

    return _generateJWT(payload, secret);
  }

  // توليد JWT لطلب checkTransactionStatus
  String generateStatusJWT({
    required String msisdn,
    required String transactionId,
    required String secret,
  }) {
    final payload = {
      'msisdn': msisdn,
      'id': transactionId, // يجب استخدام 'id' كما هو مطلوب
      'iat': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'exp': DateTime.now().millisecondsSinceEpoch ~/ 1000 + 60 * 60,
    };

    return _generateJWT(payload, secret);
  }

  // دالة عامة لتوليد JWT
  String _generateJWT(Map<String, dynamic> payload, String secret) {
    final header = {'alg': 'HS256', 'typ': 'JWT'};

    String base64UrlEncode(List<int> bytes) {
      return base64Url
          .encode(bytes)
          .replaceAll('+', '-')
          .replaceAll('/', '_')
          .replaceAll('=', '');
    }

    final headerEncoded = base64UrlEncode(utf8.encode(json.encode(header)));
    final payloadEncoded = base64UrlEncode(utf8.encode(json.encode(payload)));
    final signature = Hmac(sha256, utf8.encode(secret))
        .convert(utf8.encode('$headerEncoded.$payloadEncoded'));

    final signatureEncoded = base64UrlEncode(signature.bytes);

    _logger
        .i("JWT Generated: $headerEncoded.$payloadEncoded.$signatureEncoded");

    return '$headerEncoded.$payloadEncoded.$signatureEncoded';
  }

  // تنظيف جميع البيانات المخزنة
  Future<void> clearStorage() async {
    try {
      await _storageService.clearAllData();
      _logger.i("All stored data has been cleared.");
    } catch (e) {
      _logger.e("Error clearing stored data: $e");
    }
  }

  // تنسيق المبلغ كعدد عشرى
  String formatAmount(String amount) {
    try {
      double formattedAmount = double.parse(amount);
      return formattedAmount
          .toStringAsFixed(2); // تنسيق المبلغ بإضافة خانتين عشريتين
    } catch (e) {
      _logger.e("Error formatting amount: $e");
      return '0.00'; // قيمة افتراضية في حال وجود خطأ
    }
  }

  // إنشاء معاملة جديدة
  Future<void> createTransaction({
    required String amount,
    required String serviceType,
    required String orderId,
    required BuildContext context,
  }) async {
    try {
      String formattedAmount = formatAmount(amount); // تنسيق المبلغ
      String jwtToken = generateTransactionJWT(
        amount: formattedAmount,
        serviceType: serviceType,
        msisdn: Config.msisdn,
        orderId: orderId,
        redirectUrl: Config.redirectUrl,
        secret: Config.secret,
      );

      final dio = _dioClient.dio;
      final stopwatch = Stopwatch()..start(); // تسجيل وقت الطلب

      _logger.i("Starting transaction request...");

      var response = await dio.post(
        'transaction/init',
        data: {
          'token': jwtToken,
          'merchantId': Config.merchantId,
          'lang': 'ar',
        },
      );

      _logger.i("Request completed in ${stopwatch.elapsedMilliseconds} ms");

      if (response.statusCode == 200) {
        var responseData = response.data;

        // التحقق من وجود خطأ في الاستجابة
        if (responseData['err'] != null) {
          _logger.e("Error from server: ${responseData['err']['msg']}");
        } else {
          String transactionId = responseData['id'];
          String status = responseData['status'];

          _logger.i("Transaction ID: $transactionId, Status: $status");

          // تخزين transactionId في shared_preferences
          await _storageService.storeData('transactionId', transactionId);

          // استخدام WebView لعرض رابط الدفع
          String paymentUrl =
              'https://test.zaincash.iq/transaction/pay?id=$transactionId';
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => WebViewScreen(paymentUrl: paymentUrl),
            ),
          );
        }
      } else {
        _logger.e("Transaction failed with status: ${response.statusCode}");
      }
    } catch (e) {
      _logger.e("Error occurred during transaction: $e");
    }
  }

  // التحقق من حالة المعاملة
  Future<Map<String, dynamic>> checkTransactionStatus(
      BuildContext context) async {
    try {
      // استرجاع transactionId من التخزين
      String? transactionId =
          await _storageService.retrieveData('transactionId');
      if (transactionId == null || transactionId.isEmpty) {
        _logger.e("No transaction ID found in storage");
        _showNoTransactionDialog(
            context); // عرض Dialog لإبلاغ المستخدم بعدم وجود معاملة
        return {}; // إرجاع بيانات فارغة إذا لم يتم العثور على transactionId
      }

      // توليد JWT للتحقق من المعاملة باستخدام transactionId
      String jwtToken = generateStatusJWT(
        msisdn: Config.msisdn,
        transactionId: transactionId,
        secret: Config.secret,
      );

      _logger.i("Checking transaction status for ID: $transactionId");

      final dio = _dioClient.dio;

      var response = await dio.post(
        'transaction/get',
        data: {
          'token': jwtToken,
          'merchantId': Config.merchantId,
          'id': transactionId, // إرسال transactionId للتحقق
        },
      );

      if (response.statusCode == 200) {
        var responseData = response.data;

        // التحقق من وجود خطأ في الاستجابة
        if (responseData['err'] != null) {
          _logger.e("Error from server: ${responseData['err']['msg']}");
          return {};
        } else {
          // إرجاع البيانات الناجحة
          return responseData;
        }
      } else {
        _logger.e("Failed to check transaction status: ${response.statusCode}");
        return {};
      }
    } catch (e) {
      _logger.e("Error checking status: $e");
      return {};
    }
  }

  // دالة لعرض Dialog عند عدم وجود transactionId
  void _showNoTransactionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("لا يوجد معاملة"),
          content: Text(
              "لم يتم العثور على معاملة محفوظة. الرجاء إنشاء معاملة جديدة."),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("إغلاق"),
            ),
          ],
        );
      },
    );
  }
}
