import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../models/ai_report_model.dart';
import '../services/ai_analysis_service.dart';
import 'report_details_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<AiReportModel> _allReports = [];
  List<AiReportModel> _filteredReports = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final list = await AiAnalysisService.fetchHistory();
    if (mounted) {
      setState(() {
        _allReports = list;
        _filteredReports = list;
        _isLoading = false;
      });
    }
  }

  void _applyFilter(String query, String filter) {
    setState(() {
      _searchQuery = query;
      _selectedFilter = filter;
      _filteredReports = _allReports.where((r) {
        final matchesQuery = r.date.toLowerCase().contains(query.toLowerCase()) ||
            r.problemsDetected.any((p) => p.toLowerCase().contains(query.toLowerCase()));
        final matchesFilter = filter == 'All' || r.type.toLowerCase() == filter.toLowerCase();
        return matchesQuery && matchesFilter;
      }).toList();
    });
  }

  Future<void> _deleteReport(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Posture Report'),
        content: const Text('Are you sure you want to delete this report from history?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await AiAnalysisService.deleteReport(id);
      setState(() {
        _allReports.removeWhere((r) => r.id == id);
        _applyFilter(_searchQuery, _selectedFilter);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report deleted from history.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('AI Posture History & Cloud Vault', style: AppTextStyles.h2),
          const SizedBox(height: 4),
          Text('Review, filter, share or export MediaPipe 33 Landmark reports', style: AppTextStyles.bodyMuted),
          const SizedBox(height: 16),

          // Search Bar & Filter Chips
          TextField(
            onChanged: (val) => _applyFilter(val, _selectedFilter),
            decoration: InputDecoration(
              hintText: 'Search by date or posture defect...',
              prefixIcon: const Icon(LucideIcons.search, color: AppColors.textMuted, size: 18),
              filled: true,
              fillColor: AppColors.cardBg,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.borderLight),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.borderLight),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Filter Chips (All, Image, Video, Live)
          Row(
            children: ['All', 'Image', 'Video', 'Live']
                .map(
                  (f) => Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(f),
                      selected: _selectedFilter == f,
                      selectedColor: AppColors.primaryLight,
                      onSelected: (selected) {
                        if (selected) _applyFilter(_searchQuery, f);
                      },
                    ),
                  ),
                )
                .toList(),
          ),

          const SizedBox(height: 16),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredReports.isEmpty
                    ? const Center(child: Text('No matching reports found.'))
                    : ListView.builder(
                        itemCount: _filteredReports.length,
                        itemBuilder: (context, index) {
                          final r = _filteredReports[index];
                          final score = r.overallScore;
                          final isGood = score >= 80;
                          final isFair = score >= 60 && score < 80;
                          final statusLabel = isGood ? 'GOOD' : (isFair ? 'FAIR' : 'POOR');
                          final badgeBg = isGood
                              ? AppColors.primaryLight
                              : (isFair ? AppColors.warningLight : AppColors.alertLight);
                          final badgeColor = isGood
                              ? AppColors.primary
                              : (isFair ? AppColors.warning : AppColors.alert);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 14),
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                            decoration: BoxDecoration(
                              color: AppColors.cardBg,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: const [AppColors.shadowCard],
                              border: Border.all(color: AppColors.borderLight),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 46,
                                      height: 46,
                                      decoration: BoxDecoration(
                                        color: badgeBg,
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Icon(
                                        r.type == 'video'
                                            ? LucideIcons.video
                                            : (r.type == 'live' ? LucideIcons.camera : LucideIcons.image),
                                        color: badgeColor,
                                        size: 22,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            r.date,
                                            style: AppTextStyles.h3.copyWith(fontSize: 14, fontWeight: FontWeight.bold),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            'Neck: ${r.neckAngle}° • Spine: ${r.spineAlignment}°',
                                            style: AppTextStyles.caption.copyWith(fontSize: 12),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: badgeBg,
                                        borderRadius: BorderRadius.circular(24),
                                        border: Border.all(color: badgeColor.withOpacity(0.3)),
                                      ),
                                      child: Text(
                                        '$statusLabel ($score%)',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: badgeColor,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(height: 22),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(LucideIcons.download, size: 16, color: AppColors.textMuted),
                                          onPressed: () {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('PDF downloaded.')),
                                            );
                                          },
                                        ),
                                        IconButton(
                                          icon: const Icon(LucideIcons.share2, size: 16, color: AppColors.textMuted),
                                          onPressed: () {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Report shared.')),
                                            );
                                          },
                                        ),
                                        IconButton(
                                          icon: const Icon(LucideIcons.trash2, size: 16, color: AppColors.alert),
                                          onPressed: () => _deleteReport(r.id),
                                        ),
                                      ],
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => ReportDetailsScreen(reportId: r.id),
                                          ),
                                        );
                                      },
                                      child: const Row(
                                        children: [
                                          Text('View Details', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12)),
                                          SizedBox(width: 4),
                                          Icon(LucideIcons.chevronRight, size: 14, color: AppColors.primary),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
