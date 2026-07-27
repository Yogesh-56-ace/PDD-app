import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../models/ai_report_model.dart';
import '../services/ai_analysis_service.dart';
import 'ai_report_screen.dart';

import '../widgets/custom_app_bar.dart';

class ReportDetailsScreen extends StatefulWidget {
  final String reportId;

  const ReportDetailsScreen({super.key, required this.reportId});

  @override
  State<ReportDetailsScreen> createState() => _ReportDetailsScreenState();
}

class _ReportDetailsScreenState extends State<ReportDetailsScreen> {
  AiReportModel? _report;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    final report = await AiAnalysisService.fetchReportDetails(widget.reportId);
    if (mounted) {
      setState(() {
        _report = report;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.bgBody,
        appBar: CustomAppBar(title: 'History Details'),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bgBody,
      appBar: const CustomAppBar(title: 'History Details'),
      body: SafeArea(
        child: Column(
          children: [
            // Progress Comparison Header Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: const BoxDecoration(
                color: AppColors.primaryLight,
                border: Border(bottom: BorderSide(color: AppColors.borderLight)),
              ),
              child: const Row(
                children: [
                  Icon(LucideIcons.trendingUp, color: AppColors.primary, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Progress Comparison: +4% Posture Score Improvement vs baseline!',
                      style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: AiReportScreen(report: _report),
            ),
          ],
        ),
      ),
    );
  }
}
