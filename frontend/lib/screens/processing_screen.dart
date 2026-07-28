import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../models/ai_report_model.dart';
import '../services/ai_analysis_service.dart';
import '../widgets/base_layout.dart';
import 'ai_report_screen.dart';

class ProcessingScreen extends StatefulWidget {
  final String? mode; // image, video, live
  final String? scanType;
  final File? mediaFile;
  final Map<String, dynamic>? liveFrameData;
  final Map<String, dynamic>? liveTelemetry;

  const ProcessingScreen({
    super.key,
    this.mode,
    this.scanType,
    this.mediaFile,
    this.liveFrameData,
    this.liveTelemetry,
  });

  @override
  State<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends State<ProcessingScreen> {
  int _currentStep = 0;
  double _progress = 0.1;
  Timer? _timer;
  AiReportModel? _generatedReport;

  final List<String> _steps = [
    'Uploading posture media to server...',
    'Detecting human body position with MediaPipe...',
    'Extracting 33 3D body landmarks & joint vectors...',
    'Calculating posture angles (Neck, Shoulder, Spine, Hip, Knee)...',
    'Querying GPT-5 / Gemini AI explanation engine...',
    'Finalizing medical posture report...',
  ];

  bool _isProcessing = true;

  @override
  void initState() {
    super.initState();
    _startProcessingFlow();
  }

  void _startProcessingFlow() {
    _timer = Timer.periodic(const Duration(milliseconds: 600), (t) {
      if (mounted && _isProcessing) {
        setState(() {
          if (_currentStep < _steps.length - 1) {
            _currentStep++;
            _progress = (_currentStep + 1) / _steps.length;
          }
        });
      }
    });

    _executeAnalysis();
  }

  Future<void> _executeAnalysis() async {
    try {
      final activeMode = widget.scanType ?? widget.mode ?? 'image';
      final activeTelemetry = widget.liveTelemetry ?? widget.liveFrameData ?? {};

      AiReportModel? report;
      if (activeMode == 'image') {
        report = await AiAnalysisService.uploadImage(widget.mediaFile);
      } else if (activeMode == 'video') {
        report = await AiAnalysisService.uploadVideo(widget.mediaFile);
      } else {
        report = await AiAnalysisService.analyzeLiveSnapshot(activeTelemetry);
      }

      if (!mounted) return;

      if (report != null) {
        _generatedReport = report;
        _timer?.cancel();
        setState(() {
          _progress = 1.0;
          _currentStep = _steps.length - 1;
        });

        await Future.delayed(const Duration(milliseconds: 300));

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => AiReportScreen(report: _generatedReport),
            ),
          );
        }
      } else {
        throw Exception('Received null report from AI analysis service');
      }
    } catch (e, stackTrace) {
      _timer?.cancel();
      debugPrint('❌ Error during posture analysis: $e\n$stackTrace');
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.cardBg,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(LucideIcons.alertTriangle, color: AppColors.alertRed, size: 26),
                SizedBox(width: 10),
                Text('Analysis Error', style: TextStyle(color: AppColors.textMain, fontWeight: FontWeight.bold)),
              ],
            ),
            content: SingleChildScrollView(
              child: Text(
                'An error occurred while analyzing the posture image:\n\n$e',
                style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).pop();
                },
                child: const Text('Back to Upload', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BaseLayout(
      title: 'AI Processing',
      padding: const EdgeInsets.all(28.0),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Spacer(),

          // Animated Radial Processing Indicator
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 140,
                height: 140,
                child: CircularProgressIndicator(
                  value: _progress,
                  strokeWidth: 10,
                  backgroundColor: AppColors.cardBg,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: AppColors.cardBg,
                  shape: BoxShape.circle,
                  boxShadow: [AppColors.shadowCard],
                ),
                child: const Icon(
                  LucideIcons.sparkles,
                  color: AppColors.primary,
                  size: 44,
                ),
              ),
            ],
          ),

          const SizedBox(height: 36),

          Text('AI Posture Analysis', style: AppTextStyles.h2),
          const SizedBox(height: 8),
          Text(
            'MediaPipe 33 Landmark Pose Engine & Gemini AI',
            style: AppTextStyles.bodyMuted,
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 36),

          // Step Progress Box
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.borderLight),
              boxShadow: const [AppColors.shadowCard],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Step ${_currentStep + 1} of ${_steps.length}', style: AppTextStyles.caption),
                    Text(
                      '${(_progress * 100).toInt()}%',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: _progress,
                  backgroundColor: AppColors.bgBody,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                  minHeight: 6,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _steps[_currentStep],
                        style: AppTextStyles.bodyMain.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Spacer(),

          Text(
            'Please keep your app open while AI computes joint angles.',
            style: AppTextStyles.caption,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
