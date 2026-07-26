import 'package:dio/dio.dart';

String apiErrorMessage(Object error) {
  if (error is! DioException) return '데이터를 불러오는 중 문제가 발생했습니다.';
  final status = error.response?.statusCode;
  if (status == 401) return '로그인이 만료되었습니다. 다시 로그인해 주세요.';
  if (status == 404) return '요청한 데이터를 찾을 수 없습니다.';
  if (status != null && status >= 500) {
    return '서버가 응답하지 않습니다. 잠시 후 다시 시도해 주세요.';
  }
  return switch (error.type) {
    DioExceptionType.connectionTimeout ||
    DioExceptionType.sendTimeout ||
    DioExceptionType.receiveTimeout =>
      '서버 연결 시간이 초과되었습니다. 네트워크를 확인해 주세요.',
    DioExceptionType.connectionError =>
      'API 서버에 연결할 수 없습니다. 같은 Wi-Fi와 서버 주소를 확인해 주세요.',
    _ => error.response?.data is Map<String, dynamic>
        ? ((error.response!.data as Map<String, dynamic>)['detail']
                ?.toString() ??
            'API 요청에 실패했습니다.')
        : 'API 요청에 실패했습니다.',
  };
}
