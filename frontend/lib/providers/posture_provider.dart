import 'dart:async';
import 'package:flutter/material.dart';

class PostureProvider extends ChangeNotifier {
  bool _isMonitoring = false;
  int _timerSeconds = 0;
  Timer? _timer;
  
  bool _isBadPosture = false;
  double _neckAngle = 12.0;
  double _shoulderAngle = 2.0;
  double _spineAngle = 8.0;
  int _postureScore = 92;
  int _alertCount = 0;
  int _slouchedSeconds = 0;

  bool get isMonitoring => _isMonitoring;
  int get timerSeconds => _timerSeconds;
  bool get isBadPosture => _isBadPosture;
  double get neckAngle => _neckAngle;
  double get shoulderAngle => _shoulderAngle;
  double get spineAngle => _spineAngle;
  int get postureScore => _postureScore;
  int get alertCount => _alertCount;
  int get slouchedSeconds => _slouchedSeconds;

  String get formattedTimer {
    final h = (_timerSeconds ~/ 3600).toString().padLeft(2, '0');
    final m = ((_timerSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final s = (_timerSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  void startMonitoring() {
    _isMonitoring = true;
    _timerSeconds = 0;
    _alertCount = 0;
    _slouchedSeconds = 0;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _timerSeconds++;
      if (_isBadPosture) {
        _slouchedSeconds++;
      }
      notifyListeners();
    });
    notifyListeners();
  }

  void stopMonitoring() {
    _isMonitoring = false;
    _timer?.cancel();
    notifyListeners();
  }

  void updateMetrics({
    required bool isBad,
    required double neck,
    required double shoulder,
    required double spine,
  }) {
    if (_isBadPosture != isBad) {
      if (isBad) _alertCount++;
      _isBadPosture = isBad;
    }
    _neckAngle = neck;
    _shoulderAngle = shoulder;
    _spineAngle = spine;
    _postureScore = (100 - (_slouchedSeconds * 100 / (_timerSeconds > 0 ? _timerSeconds : 1))).clamp(0, 100).toInt();
    notifyListeners();
  }
}
