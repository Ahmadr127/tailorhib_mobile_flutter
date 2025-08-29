import 'package:dio/dio.dart';
import '../models/tailor_model.dart';
import '../utils/logger.dart';
import 'api_service.dart';

class SearchService {
  late final Dio _dio;

  SearchService() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiService.baseUrl.substring(0, ApiService.baseUrl.lastIndexOf('/api')),
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 3),
  ));
  }

  Future<List<TailorModel>> searchTailors(String query) async {
    try {
      AppLogger.info('Memulai pencarian penjahit', tag: 'SearchService');
      final endpoint = '/api/tailors/search/name/$query';
      AppLogger.debug('URL: ${_dio.options.baseUrl}$endpoint',
          tag: 'SearchService');

      final response = await _dio.get(endpoint);

      AppLogger.debug('Status code: ${response.statusCode}',
          tag: 'SearchService');
      AppLogger.debug('Response headers: ${response.headers}',
          tag: 'SearchService');
      AppLogger.debug('Response data: ${response.data}', tag: 'SearchService');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = response.data;

        if (responseData['success'] == true && responseData['data'] != null) {
          final List<dynamic> tailorsData = responseData['data']['tailors'];
          final results =
              tailorsData.map((json) => TailorModel.fromJson(json)).toList();

          AppLogger.info(
              'Berhasil mendapatkan ${results.length} hasil pencarian',
              tag: 'SearchService');
          return results;
        } else {
          AppLogger.warning('Response sukses tapi tidak ada data penjahit',
              tag: 'SearchService');
          return [];
        }
      } else {
        AppLogger.error('Error searching tailors: ${response.statusCode}',
            error: response.data, tag: 'SearchService');
        throw Exception('Gagal mencari penjahit');
      }
    } on DioException catch (e) {
      AppLogger.error('Dio error while searching tailors',
          error: {
            'message': e.message,
            'error': e.error,
            'response': e.response?.data,
            'statusCode': e.response?.statusCode,
            'requestOptions': {
              'path': e.requestOptions.path,
              'method': e.requestOptions.method,
              'baseUrl': e.requestOptions.baseUrl,
              'queryParameters': e.requestOptions.queryParameters,
              'headers': e.requestOptions.headers,
            }
          },
          tag: 'SearchService');
      throw Exception('Terjadi kesalahan jaringan saat mencari penjahit');
    } catch (e) {
      AppLogger.error('Error while searching tailors',
          error: e, tag: 'SearchService');
      throw Exception('Terjadi kesalahan saat mencari penjahit');
    }
  }
}
