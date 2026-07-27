import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_button.dart';
import '../widgets/status_badge.dart';
import 'processing_screen.dart';

class LiveCameraScreen extends StatefulWidget {
  const LiveCameraScreen({super.key});

  @override
  State<LiveCameraScreen> createState() => _LiveCameraScreenState();
}

class _LiveCameraScreenState extends State<LiveCameraScreen> {
  bool _isDetecting = false;
  bool _hasSnapshot = false;
  Timer? _timer;

  double _neckAngle = 14.5;
  double _shoulderAngle = 2.1;
  double _spineAngle = 6.4;
  double _hipAngle = 3.2;
  double _kneeAngle = 1.8;
  int _score = 92;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _toggleDetection() {
    setState(() {
      _isDetecting = !_isDetecting;
      if (_isDetecting) {
        _startLiveSimulation();
      } else {
        _timer?.cancel();
      }
    });
  }

  void _startLiveSimulation() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 600), (timer) {
      if (!mounted) return;
      setState(() {
        _neckAngle = (12.0 + (timer.tick % 6) * 0.8);
        _shoulderAngle = (1.5 + (timer.tick % 4) * 0.5);
        _spineAngle = (5.0 + (timer.tick % 5) * 0.6);
        _hipAngle = (2.0 + (timer.tick % 3) * 0.4);
        _kneeAngle = (1.5 + (timer.tick % 4) * 0.3);
        _score = maxScore(100 - (_neckAngle + _shoulderAngle + _spineAngle).toInt());
      });
    });
  }

  int maxScore(int val) => val < 50 ? 50 : (val > 99 ? 99 : val);

  void _captureSnapshot() {
    setState(() {
      _hasSnapshot = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Posture snapshot captured! MediaPipe landmark telemetry logged.')),
    );
  }

  void _analyzeSnapshot() {
    _timer?.cancel();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProcessingScreen(
          scanType: 'live',
          liveTelemetry: {
            'neck_angle': _neckAngle,
            'shoulder_alignment': _shoulderAngle,
            'spine_alignment': _spineAngle,
            'hip_alignment': _hipAngle,
            'knee_alignment': _kneeAngle,
            'score': _score,
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgBody,
      appBar: const CustomAppBar(title: 'AI Scan'),
      body: SafeArea(
        child: Column(
          children: [
            // Status Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  StatusBadge(
                    label: _isDetecting ? 'MediaPipe Detecting Live' : 'Camera Ready',
                    isGood: _score > 80,
                  ),
                  Text('33 Body Landmarks', style: AppTextStyles.caption),
                ],
              ),
            ),

            // Camera Viewfinder Simulation
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [AppColors.shadowCard],
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Image.network(
                        'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?q=80&w=800',
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, _, __) => Container(color: Colors.black87),
                      ),
                    ),

                    // Grid Overlay & Scanning Line Animation
                    if (_isDetecting)
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: AppColors.primary, width: 2),
                        ),
                        child: const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(LucideIcons.scanLine, size: 72, color: AppColors.primary),
                              SizedBox(height: 12),
                              Text(
                                'MediaPipe 33 Landmark Pose Engine Active',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Top Live Score Badge
                    if (_isDetecting)
                      Positioned(
                        top: 16,
                        right: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.primary),
                          ),
                          child: Text(
                            'Score: $_score%',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),

                    // Bottom Telemetry Grid
                    if (_isDetecting)
                      Positioned(
                        bottom: 16,
                        left: 16,
                        right: 16,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.borderLight),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildMetricItem('Neck', '${_neckAngle.toStringAsFixed(1)}°'),
                              _buildMetricItem('Shoulder', '${_shoulderAngle.toStringAsFixed(1)}°'),
                              _buildMetricItem('Spine', '${_spineAngle.toStringAsFixed(1)}°'),
                              _buildMetricItem('Hip', '${_hipAngle.toStringAsFixed(1)}°'),
                              _buildMetricItem('Knee', '${_kneeAngle.toStringAsFixed(1)}°'),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Controls Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: CustomButton(
                          text: _isDetecting ? 'Stop Detection' : 'Start Detection',
                          icon: _isDetecting ? LucideIcons.stopCircle : LucideIcons.playCircle,
                          isSecondary: _isDetecting,
                          onPressed: _toggleDetection,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CustomButton(
                          text: 'Capture Snapshot',
                          icon: LucideIcons.camera,
                          isSecondary: true,
                          onPressed: _captureSnapshot,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  CustomButton(
                    text: 'Analyze Posture Snapshot',
                    icon: LucideIcons.sparkles,
                    onPressed: _analyzeSnapshot,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricItem(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12)),
      ],
    );
  }
}
