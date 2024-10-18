import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

class DioClient {
  final Dio _dio;
  final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 2, // عدد الأسطر في الـ stack trace
      errorMethodCount: 5, // عدد الأسطر في حالة الخطأ
      colors: true, // تمكين الألوان
      printEmojis: true, // استخدام الإيموجي لتوضيح نوع الرسالة
      printTime: false, // عدم إظهار الوقت
    ),
  );

  DioClient()
      : _dio = Dio(
    BaseOptions(
      baseUrl: 'https://test.zaincash.iq/',
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 13),
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
    ),
  ) {
    // إضافة Interceptor لتسجيل الطلبات، الردود، والأخطاء
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          _logger.i("[Request] [${options.method}] -> ${options.path}");
          if (options.data != null) {
            _logger.d("[Request Data] -> ${options.data}");
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          _logger.i("[Response] [${response.statusCode}] -> ${response.data}");
          return handler.next(response);
        },
        onError: (DioError error, handler) {
          _logger.e("[Error] [${error.response?.statusCode}] -> ${error.message}");
          if (error.response != null) {
            _logger.w("[Error Data] -> ${error.response?.data}");
          }
          return handler.next(error);
        },
      ),
    );
  }

  // إتاحة الوصول إلى Dio خارجياً
  Dio get dio => _dio;

  // وظيفة لتغيير الـ baseUrl إذا لزم الأمر
  void updateBaseUrl(String newUrl) {
    _dio.options.baseUrl = newUrl;
    _logger.i("Base URL updated to: $newUrl");
  }
}
