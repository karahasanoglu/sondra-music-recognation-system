import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/song_match_result.dart';

class SongSearchApi {
  SongSearchApi({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        baseUrl = (baseUrl ?? _resolveBaseUrl()).replaceAll(RegExp(r'/$'), '');

  final http.Client _client;
  final String baseUrl;

  static String _resolveBaseUrl() {
    const envUrl = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    if (envUrl.isNotEmpty) {
      return envUrl;
    }

    if (kIsWeb) {
      return 'http://localhost:8000';
    }

    if (Platform.isAndroid) {
      return 'https://increasedly-declinatory-chandra.ngrok-free.dev';
    }

    return 'https://increasedly-declinatory-chandra.ngrok-free.dev';
  }

  Future<SongMatchResult> searchSong(File audioFile) async {
    final uri = Uri.parse('$baseUrl/api/match');

    final request = http.MultipartRequest('POST', uri);
    request.files.add(
      await http.MultipartFile.fromPath(
        'audio',
        audioFile.path,
        filename: audioFile.uri.pathSegments.last,
      ),
    );

    http.StreamedResponse streamed;

    try {
      streamed =
          await _client.send(request).timeout(const Duration(seconds: 60));
    } on SocketException {
      throw const SongSearchException(
        'Sunucuya baglanilamadi. Telefon ve bilgisayar ayni agda mi, backend calisiyor mu kontrol et.',
      );
    } on HttpException {
      throw const SongSearchException(
        'Sunucu ile iletisim kurulamadi.',
      );
    } on TimeoutException {
      throw const SongSearchException(
        'Sunucu gec cevap verdi. Istek zaman asimina ugradi.',
      );
    } catch (e) {
      throw SongSearchException(
        'Beklenmeyen bir hata olustu: $e',
      );
    }

    final response = await http.Response.fromStream(streamed);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      String message =
          'Sunucu sarki aramasini tamamlayamadi. Kod: ${response.statusCode}';

      try {
        final payload = jsonDecode(response.body) as Map<String, dynamic>;
        final detail = payload['detail']?.toString();
        if (detail != null && detail.isNotEmpty) {
          message = detail;
        }
      } catch (_) {
        // JSON degilse varsayilan mesaji kullan.
      }

      throw SongSearchException(message);
    }

    try {
      final payload = jsonDecode(response.body) as Map<String, dynamic>;
      return SongMatchResult.fromJson(payload);
    } catch (e) {
      throw SongSearchException(
        'Sunucu gecersiz veri dondurdu: $e',
      );
    }
  }

  void dispose() {
    _client.close();
  }
}

class SongSearchException implements Exception {
  const SongSearchException(this.message);

  final String message;

  @override
  String toString() => message;
}
