import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class MonitoringPage extends StatefulWidget {
  final VoidCallback onSessionComplete;

  const MonitoringPage({super.key, required this.onSessionComplete});

  @override
  State<MonitoringPage> createState() => _MonitoringPageState();
}

class _MonitoringPageState extends State<MonitoringPage> {
  bool _isCameraActive = false;
  bool _isMonitoring = false;
  int _secondsLeft = 10;
  Timer? _countdownTimer;
  Timer? _samplingTimer;

  // Real-time metrics
  double _currentScore = 100.0;
  double _neckAngle = 92.0;
  double _shoulderTilt = 98.0;
  double _slouchFactor = 95.0;

  // Sampler values
  final List<double> _scoresList = [];
  int _alertsTriggered = 0;
  int _consecutiveBad = 0;

  // Results display
  bool _showScorecard = false;
  double _resScore = 0.0;
  double _resGoodPct = 0.0;
  double _resBadPct = 0.0;
  int _resAlerts = 0;

  final math.Random _random = math.Random();

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _samplingTimer?.cancel();
    super.dispose();
  }

  void _toggleCamera() {
    setState(() {
      _isCameraActive = !_isCameraActive;
      if (!_isCameraActive) {
        _isMonitoring = false;
        _countdownTimer?.cancel();
        _samplingTimer?.cancel();
      }
    });
  }

  void _calibrate() {
    if (!_isCameraActive) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Upright Neutral Posture Calibrated successfully!'),
        backgroundColor: Color(0xFF10B981),
      ),
    );
  }

  void _start10sScan() {
    if (!_isCameraActive || _isMonitoring) return;

    setState(() {
      _isMonitoring = true;
      _secondsLeft = 10;
      _scoresList.clear();
      _alertsTriggered = 0;
      _consecutiveBad = 0;
      _showScorecard = false;
    });

    // SAMPLING LOOP (twice a second)
    _samplingTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      // Simulate real-time MediaPipe coordinates calculations
      double simulatedScore = 90.0 + _random.nextDouble() * 10.0;
      
      // Slouch simulation (occasionally drops)
      if (_secondsLeft < 7 && _secondsLeft > 4) {
        simulatedScore = 50.0 + _random.nextDouble() * 20.0;
      }

      _scoresList.add(simulatedScore);

      setState(() {
        _currentScore = simulatedScore;
        _neckAngle = (simulatedScore + _random.nextDouble() * 5.0).clamp(0, 100);
        _shoulderTilt = (simulatedScore - _random.nextDouble() * 3.0).clamp(0, 100);
        _slouchFactor = (100 - (100 - simulatedScore) * 1.5).clamp(0, 100);

        if (simulatedScore < 80) {
          _consecutiveBad++;
          if (_consecutiveBad == 3) {
            _alertsTriggered++;
            _consecutiveBad = 0;
          }
        } else {
          _consecutiveBad = 0;
        }
      });
    });

    // SECONDS TIMER
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _secondsLeft--;
      });

      if (_secondsLeft <= 0) {
        _samplingTimer?.cancel();
        _countdownTimer?.cancel();
        _completeScan();
      }
    });
  }

  Future<void> _completeScan() async {
    if (_scoresList.isEmpty) return;

    final double avg = _scoresList.reduce((a, b) => a + b) / _scoresList.length;
    int goodCount = _scoresList.where((s) => s >= 80).length;
    final double goodPct = (goodCount / _scoresList.length) * 100.0;
    final double badPct = 100.0 - goodPct;

    setState(() {
      _resScore = avg;
      _resGoodPct = goodPct;
      _resBadPct = badPct;
      _resAlerts = _alertsTriggered;
      _showScorecard = true;
      _isMonitoring = false;
    });

    try {
      await ApiService.savePostureSession(
        avg,
        goodPct,
        badPct,
        _alertsTriggered,
        10,
      );
      widget.onSessionComplete();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save session: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 900;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Camera stage column
              Expanded(
                flex: isMobile ? 1 : 2,
                child: Column(
                  children: [
                    Card(
                      color: Colors.black,
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: AspectRatio(
                        aspectRatio: 16 / 9,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            if (_isCameraActive)
                              Container(
                                color: Colors.grey[900],
                                child: CustomPaint(
                                  painter: SkeletonPainter(
                                    score: _currentScore,
                                    isMonitoring: _isMonitoring,
                                  ),
                                  child: Container(),
                                ),
                              )
                            else
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.videocam_off, color: Colors.grey, size: 64),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'Webcam Stream Required',
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Grant browser camera permission to enable local skeletal tracking.',
                                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: _toggleCamera,
                                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
                                    child: const Text('Enable Camera Stream', style: TextStyle(color: Colors.white)),
                                  ),
                                ],
                              ),
                            
                            // Countdown Timer overlay
                            if (_isMonitoring)
                              Container(
                                color: Colors.black.withOpacity(0.3),
                                child: Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '$_secondsLeft',
                                        style: const TextStyle(
                                          fontSize: 96,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          shadows: [Shadow(blurRadius: 20, color: Color(0xFF10B981))],
                                        ),
                                      ),
                                      const Text(
                                        'HOLD NEUTRAL POSITION',
                                        style: TextStyle(color: Colors.white, letterSpacing: 2, fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _isCameraActive ? _calibrate : null,
                          icon: const Icon(Icons.tune),
                          label: const Text('Calibrate Neutral'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF0B2917),
                            side: const BorderSide(color: Color(0xFFE5E7EB)),
                          ),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton.icon(
                          onPressed: (_isCameraActive && !_isMonitoring) ? _start10sScan : null,
                          icon: const Icon(Icons.timer),
                          label: const Text('Run 10s Scan'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.white,
                          ),
                        ),
                        if (_isMonitoring) ...[
                          const SizedBox(width: 16),
                          ElevatedButton(
                            onPressed: _toggleCamera,
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                            child: const Text('Terminate Scan', style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ],
                    )
                  ],
                ),
              ),
              if (!isMobile) const SizedBox(width: 24),
              // Metrics third column
              if (!isMobile)
                Expanded(
                  flex: 1,
                  child: _buildMetricsColumn(),
                ),
            ],
          ),
          if (isMobile) ...[
            const SizedBox(height: 32),
            _buildMetricsColumn(),
          ],
          
          // Result Dialog scorecard
          if (_showScorecard) ...[
            const SizedBox(height: 32),
            _buildScorecardView(),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricsColumn() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text(
              'Real-Time Metrics',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0B2917)),
            ),
            const SizedBox(height: 24),
            // Gauge Score
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: _currentScore >= 80
                      ? const Color(0xFF10B981)
                      : (_currentScore >= 60 ? Colors.orange : Colors.red),
                  width: 8,
                ),
              ),
              child: Center(
                child: Text(
                  '${_currentScore.round()}%',
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 24),
            _buildJointProgress('Neck / Head Angle', _neckAngle),
            const SizedBox(height: 12),
            _buildJointProgress('Shoulder Alignment', _shoulderTilt),
            const SizedBox(height: 12),
            _buildJointProgress('Slouch Deviation', _slouchFactor),
          ],
        ),
      ),
    );
  }

  Widget _buildJointProgress(String label, double value) {
    Color barColor = const Color(0xFF10B981);
    if (value < 60) {
      barColor = Colors.red;
    } else if (value < 80) {
      barColor = Colors.orange;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 12)),
            Text('${value.round()}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: value / 100.0,
            color: barColor,
            backgroundColor: Colors.grey[200],
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  Widget _buildScorecardView() {
    return Card(
      elevation: 0,
      color: const Color(0xFFECFDF5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFA7F3D0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.stars_outlined, color: Color(0xFF047857), size: 28),
                const SizedBox(width: 12),
                Text(
                  'Session Posture Scorecard',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF065F46),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    const Text('AVG Score', style: TextStyle(color: Color(0xFF047857), fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(
                      '${_resScore.round()}%',
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF065F46)),
                    )
                  ],
                ),
                Column(
                  children: [
                    const Text('Healthy Alignment', style: TextStyle(color: Color(0xFF047857), fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(
                      '${_resGoodPct.round()}%',
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF065F46)),
                    )
                  ],
                ),
                Column(
                  children: [
                    const Text('Slouches Flagged', style: TextStyle(color: Color(0xFF047857), fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(
                      '$_resAlerts',
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF065F46)),
                    )
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => setState(() => _showScorecard = false),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF047857), foregroundColor: Colors.white),
              child: const Text('Dismiss Scorecard'),
            )
          ],
        ),
      ),
    );
  }
}

class SkeletonPainter extends CustomPainter {
  final double score;
  final bool isMonitoring;

  SkeletonPainter({required this.score, required this.isMonitoring});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint linePaint = Paint()
      ..color = score >= 80 ? const Color(0xFF10B981) : Colors.red
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    final Paint jointPaint = Paint()
      ..color = score >= 80 ? const Color(0xFF10B981) : Colors.red
      ..style = PaintingStyle.fill;

    final double width = size.width;
    final double height = size.height;

    // Draw grid overlay lines
    final Paint gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.04)
      ..strokeWidth = 1;
    for (int i = 1; i < 6; i++) {
      canvas.drawLine(Offset(width * i / 6, 0), Offset(width * i / 6, height), gridPaint);
      canvas.drawLine(Offset(0, height * i / 6), Offset(width, height * i / 6), gridPaint);
    }

    // Coordinates points mapping simulation
    final Offset head = Offset(width * 0.5, height * 0.3);
    final Offset neck = Offset(width * 0.5, height * 0.45);
    final Offset lSh = Offset(width * 0.35, height * 0.55);
    final Offset rSh = Offset(width * 0.65, height * 0.55);

    // Draw skeletal connections
    canvas.drawLine(head, neck, linePaint);
    canvas.drawLine(lSh, rSh, linePaint);
    canvas.drawLine(neck, lSh, linePaint);
    canvas.drawLine(neck, rSh, linePaint);

    // Draw glowing joint points
    canvas.drawCircle(head, 10, jointPaint);
    canvas.drawCircle(neck, 6, jointPaint);
    canvas.drawCircle(lSh, 6, jointPaint);
    canvas.drawCircle(rSh, 6, jointPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
