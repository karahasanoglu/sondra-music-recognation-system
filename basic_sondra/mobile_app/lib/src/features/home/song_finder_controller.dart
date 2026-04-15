import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';

import '../../models/song_match_result.dart';
import '../../services/song_search_api.dart';

enum SongFinderPhase {
  idle,
  listening,
  searching,
  found,
  notFound,
  error,
}

class SongFinderController extends ChangeNotifier {
  SongFinderController({
    required SongSearchApi api,
    AudioRecorder? recorder,
  })  : _api = api,
        _recorder = recorder ?? AudioRecorder();

  static const double _gravity = 9.81;
  static const double _accelerationThreshold = 14;
  static const double _rotationThreshold = 4.5;
  static const Duration _sensorWindow = Duration(milliseconds: 650);
  static const Duration _sensorUiThrottle = Duration(milliseconds: 160);
  static const Duration _activationCooldown = Duration(seconds: 4);
  static const Duration _recordingDuration = Duration(seconds: 12);

  final SongSearchApi _api;
  final AudioRecorder _recorder;
  final AudioPlayer audioPlayer = AudioPlayer();
  String? currentPreviewId;

  StreamSubscription<AccelerometerEvent>? _accelerometerSub;
  StreamSubscription<GyroscopeEvent>? _gyroscopeSub;
  Timer? _recordingTicker;

  DateTime? _lastAccelerometerHit;
  DateTime? _lastGyroscopeHit;
  DateTime? _lastActivation;
  DateTime? _lastSensorRefresh;
  DateTime? _recordingStartedAt;
  bool _disposed = false;
  bool _isCancelled = false;

  SongFinderPhase phase = SongFinderPhase.idle;
  SongMatchResult? latestResult;
  String? errorMessage;
  double accelerationPower = 0;
  double rotationPower = 0;
  double recordingProgress = 0;
  int recordingSecondsLeft = _recordingDuration.inSeconds;
  bool microphoneReady = false;
  List<SongRecognitionHistoryItem> _history = [];
  List<SongRecognitionHistoryItem> _savedSongs = [];

  bool get isBusy =>
      phase == SongFinderPhase.listening || phase == SongFinderPhase.searching;

  bool get accelerometerArmed => accelerationPower >= _accelerationThreshold;
  bool get gyroscopeArmed => rotationPower >= _rotationThreshold;
  int get recordingDurationSeconds => _recordingDuration.inSeconds;
  String get apiBaseUrl => _api.baseUrl;
  List<SongRecognitionHistoryItem> get history => List.unmodifiable(_history);
  List<SongRecognitionHistoryItem> get savedSongs => List.unmodifiable(_savedSongs);

  Future<void> initialize() async {
    await _loadData();
    await _refreshMicrophonePermission();

    _accelerometerSub = accelerometerEvents.listen(_onAccelerometerEvent);
    _gyroscopeSub = gyroscopeEvents.listen(_onGyroscopeEvent);
  }

  Future<void> triggerListening({bool fromShake = false}) async {
    final now = DateTime.now();

    if (isBusy) {
      return;
    }

    if (_lastActivation != null &&
        now.difference(_lastActivation!) < _activationCooldown) {
      return;
    }

    _lastActivation = now;
    latestResult = null;
    errorMessage = null;
    _resetRecordingIndicators();
    _isCancelled = false;
    phase = SongFinderPhase.listening;
    _safeNotify();

    if (fromShake) {
      await HapticFeedback.lightImpact();

      // Gercek cihazda shake sonrasi mekanik gurultunun kayda girmemesi icin
      // kisa bir bekleme eklenir.
      await Future<void>.delayed(const Duration(milliseconds: 700));
    }

    final hasPermission = await _refreshMicrophonePermission(request: true);
    if (!hasPermission) {
      phase = SongFinderPhase.error;
      errorMessage = 'Mikrofon izni olmadan dinleme baslatilamaz.';
      _safeNotify();
      return;
    }

    final tempDirectory = await getTemporaryDirectory();
    final filePath = p.join(
      tempDirectory.path,
      'sondra_capture_${DateTime.now().millisecondsSinceEpoch}.wav',
    );

    String? recordedPath;

    try {
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 22050,
          numChannels: 1,
          bitRate: 128000,
        ),
        path: filePath,
      );

      _startRecordingTicker();
      
      final ticks = (_recordingDuration.inMilliseconds / 100).toInt();
      for (int i = 0; i < ticks; i++) {
        if (_isCancelled) {
           break;
        }
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }

      if (_isCancelled) {
        await _recorder.stop();
        return; 
      }

      recordedPath = await _recorder.stop();

      if (recordedPath == null) {
        throw const SongSearchException('Mikrofon kaydi tamamlanamadi.');
      }

      phase = SongFinderPhase.searching;
      _safeNotify();

      var result = await _api.searchSong(File(recordedPath));
      if (result.found && result.title != null) {
        result = await _enrichWithITunes(result);
      }

      latestResult = result;
      phase = result.found ? SongFinderPhase.found : SongFinderPhase.notFound;
      
      if (result.found) {
        HapticFeedback.lightImpact();
        
        _history.insert(
          0,
          SongRecognitionHistoryItem(
            title: result.title ?? 'Bilinmeyen Sarki',
            artist: result.artist ?? 'Bilinmeyen Sanatci',
            recognizedAt: DateTime.now(),
            score: result.score,
            previewUrl: result.previewUrl,
            albumCoverUrl: result.albumCoverUrl,
          ),
        );
        _saveData();
      }
    } catch (exc) {
      phase = SongFinderPhase.error;
      errorMessage = exc.toString();
    } finally {
      _stopRecordingTicker();
      for (final path in {
        filePath,
        if (recordedPath != null) recordedPath,
      }) {
        final recordedFile = File(path);
        if (await recordedFile.exists()) {
          await recordedFile.delete();
        }
      }
      _safeNotify();
    }
  }

  void cancelListening() {
    if (phase == SongFinderPhase.listening || phase == SongFinderPhase.searching) {
      _isCancelled = true;
      _stopRecordingTicker();
      resetState();
    }
  }

  void resetState() {
    latestResult = null;
    errorMessage = null;
    _resetRecordingIndicators();
    phase = SongFinderPhase.idle;
    _safeNotify();
  }

  Future<SongMatchResult> _enrichWithITunes(SongMatchResult result) async {
    try {
      final title = (result.title ?? '').replaceAll(RegExp(r'\(.*\)'), '').replaceAll(RegExp(r'\[.*\]'), '').replaceAll(RegExp(r'feat\.?.*?$', caseSensitive: false), '');
      final artist = (result.artist ?? '').replaceAll(RegExp(r'\(.*\)'), '').replaceAll(RegExp(r'\[.*\]'), '');
      final query = Uri.encodeComponent('$title $artist');

      final url = Uri.parse('https://itunes.apple.com/search?term=$query&limit=1&entity=song');
      final res = await http.get(url).timeout(const Duration(seconds: 4));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data != null && data['resultCount'] != null && data['resultCount'] > 0) {
          final item = data['results'][0];
          String? cover = item['artworkUrl100']?.toString();
          if (cover != null) {
            cover = cover.replaceAll('100x100bb', '600x600bb');
          }
          return result.copyWith(
            previewUrl: item['previewUrl']?.toString(),
            albumCoverUrl: cover,
          );
        }
      }
    } catch (_) {}
    return result; 
  }

  bool saveCurrentSong() {
    if (latestResult != null && latestResult!.found) {
      final item = SongRecognitionHistoryItem(
        title: latestResult!.title ?? 'Bilinmeyen Sarki',
        artist: latestResult!.artist ?? 'Bilinmeyen Sanatci',
        recognizedAt: DateTime.now(),
        score: latestResult!.score,
        previewUrl: latestResult!.previewUrl,
        albumCoverUrl: latestResult!.albumCoverUrl,
      );

      bool alreadySaved = _savedSongs.any((s) => s.title == item.title && s.artist == item.artist);
      if (alreadySaved) {
         return false;
      }
      
      _savedSongs.insert(0, item);
      _saveData();
      _safeNotify();
      return true;
    }
    return false;
  }

  void removeHistoryItem(int index) {
    if (index >= 0 && index < _history.length) {
      audioPlayer.pause();
      _history.removeAt(index);
      _saveData();
      _safeNotify();
    }
  }

  void clearHistory() {
    audioPlayer.pause();
    _history.clear();
    _saveData();
    _safeNotify();
  }

  void removeSavedSong(int index) {
    if (index >= 0 && index < _savedSongs.length) {
      audioPlayer.pause();
      _savedSongs.removeAt(index);
      _saveData();
      _safeNotify();
    }
  }

  void clearSavedSongs() {
    audioPlayer.pause();
    _savedSongs.clear();
    _saveData();
    _safeNotify();
  }

  Future<void> requestMicrophoneToggle() async {
    // If it's not ready, request it. If permanently denied or we try to revoke it, open app settings
    if (!microphoneReady) {
      final status = await Permission.microphone.request();
      if (status.isPermanentlyDenied) {
         await openAppSettings();
      }
    } else {
      await openAppSettings();
    }
    await Future.delayed(const Duration(milliseconds: 500));
    await _refreshMicrophonePermission();
  }

  Future<File> get _dataFile async {
    final dir = await getApplicationDocumentsDirectory();
    return File(p.join(dir.path, 'sondra_data.json'));
  }

  Future<void> _loadData() async {
    try {
      final file = await _dataFile;
      if (await file.exists()) {
        final content = await file.readAsString();
        final map = jsonDecode(content) as Map<String, dynamic>;

        if (map.containsKey('history')) {
          _history = (map['history'] as List)
              .map((e) => SongRecognitionHistoryItem.fromJson(e as Map<String, dynamic>))
              .toList();
        }
        if (map.containsKey('saved')) {
          _savedSongs = (map['saved'] as List)
              .map((e) => SongRecognitionHistoryItem.fromJson(e as Map<String, dynamic>))
              .toList();
        }
        _safeNotify();
      }
    } catch (_) {}
  }

  Future<void> _saveData() async {
    try {
      final file = await _dataFile;
      final map = {
        'history': _history.map((e) => e.toJson()).toList(),
        'saved': _savedSongs.map((e) => e.toJson()).toList(),
      };
      await file.writeAsString(jsonEncode(map));
    } catch (_) {}
  }

  Future<bool> _refreshMicrophonePermission({bool request = false}) async {
    final status = request
        ? await Permission.microphone.request()
        : await Permission.microphone.status;
    microphoneReady = status.isGranted;
    _safeNotify();
    return microphoneReady;
  }

  void _onAccelerometerEvent(AccelerometerEvent event) {
    accelerationPower =
        (sqrt(event.x * event.x + event.y * event.y + event.z * event.z) -
                _gravity)
            .abs();

    if (accelerationPower >= _accelerationThreshold) {
      _lastAccelerometerHit = DateTime.now();
      _maybeTriggerFromSensors();
    }

    _notifySensorRefresh();
  }

  void _onGyroscopeEvent(GyroscopeEvent event) {
    rotationPower =
        sqrt(event.x * event.x + event.y * event.y + event.z * event.z);

    if (rotationPower >= _rotationThreshold) {
      _lastGyroscopeHit = DateTime.now();
      _maybeTriggerFromSensors();
    }

    _notifySensorRefresh();
  }

  void _maybeTriggerFromSensors() {
    if (_lastAccelerometerHit == null || _lastGyroscopeHit == null) {
      return;
    }

    final distance =
        _lastAccelerometerHit!.difference(_lastGyroscopeHit!).abs();

    if (distance <= _sensorWindow) {
      unawaited(triggerListening(fromShake: true));
    }
  }

  void _notifySensorRefresh() {
    final now = DateTime.now();
    if (_lastSensorRefresh == null ||
        now.difference(_lastSensorRefresh!) >= _sensorUiThrottle) {
      _lastSensorRefresh = now;
      _safeNotify();
    }
  }

  void _startRecordingTicker() {
    _recordingStartedAt = DateTime.now();
    _recordingTicker?.cancel();
    _recordingTicker = Timer.periodic(
      const Duration(milliseconds: 120),
      (_) {
        if (_recordingStartedAt == null) {
          return;
        }

        final elapsed = DateTime.now().difference(_recordingStartedAt!);
        final totalMs = _recordingDuration.inMilliseconds;
        final progress =
            (elapsed.inMilliseconds / totalMs).clamp(0.0, 1.0).toDouble();
        final remainingMs = max(0, totalMs - elapsed.inMilliseconds);

        recordingProgress = progress;
        recordingSecondsLeft = (remainingMs / 1000).ceil();
        _safeNotify();
      },
    );
  }

  void _stopRecordingTicker() {
    _recordingTicker?.cancel();
    _recordingTicker = null;
    _recordingStartedAt = null;
    _resetRecordingIndicators();
  }

  void _resetRecordingIndicators() {
    recordingProgress = 0;
    recordingSecondsLeft = _recordingDuration.inSeconds;
  }

  void _safeNotify() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _accelerometerSub?.cancel();
    _gyroscopeSub?.cancel();
    _recordingTicker?.cancel();
    unawaited(_recorder.dispose());
    audioPlayer.dispose();
    _api.dispose();
    super.dispose();
  }
}

class SongRecognitionHistoryItem {
  const SongRecognitionHistoryItem({
    required this.title,
    required this.artist,
    required this.recognizedAt,
    this.score,
    this.previewUrl,
    this.albumCoverUrl,
  });

  final String title;
  final String artist;
  final DateTime recognizedAt;
  final int? score;
  final String? previewUrl;
  final String? albumCoverUrl;
  
  String get unqId => '${recognizedAt.millisecondsSinceEpoch}_${title.hashCode}';

  factory SongRecognitionHistoryItem.fromJson(Map<String, dynamic> json) {
    return SongRecognitionHistoryItem(
      title: json['title'] as String? ?? 'Bilinmeyen Sarki',
      artist: json['artist'] as String? ?? 'Bilinmeyen Sanatci',
      recognizedAt: DateTime.tryParse(json['recognizedAt'] as String? ?? '') ?? DateTime.now(),
      score: json['score'] as int?,
      previewUrl: json['previewUrl'] as String?,
      albumCoverUrl: json['albumCoverUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'artist': artist,
        'recognizedAt': recognizedAt.toIso8601String(),
        'score': score,
        'previewUrl': previewUrl,
        'albumCoverUrl': albumCoverUrl,
      };
}
