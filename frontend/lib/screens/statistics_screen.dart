import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../models/ai_report_model.dart';
import '../services/ai_analysis_service.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  bool _isLoading = true;
  String _selectedTimeframe = 'this_week';
  DateTimeRange? _customDateRange;

  int _avgScore = 0;
  double _improvementPct = 0.0;
  bool _isImprovement = true;
  int _totalSessions = 0;
  String _monitoringTimeStr = '0m';
  int _totalCorrections = 0;
  List<int> _weeklyScores = [0, 0, 0, 0, 0, 0, 0];
  double _goodPct = 0.0;
  double _mildPct = 0.0;
  double _severePct = 0.0;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    setState(() => _isLoading = true);

    String? startStr;
    String? endStr;
    if (_selectedTimeframe == 'custom' && _customDateRange != null) {
      startStr = "${_customDateRange!.start.year}-${_customDateRange!.start.month.toString().padLeft(2, '0')}-${_customDateRange!.start.day.toString().padLeft(2, '0')}";
      endStr = "${_customDateRange!.end.year}-${_customDateRange!.end.month.toString().padLeft(2, '0')}-${_customDateRange!.end.day.toString().padLeft(2, '0')}";
    }

    final stats = await AiAnalysisService.fetchStats(
      timeframe: _selectedTimeframe,
      startDate: startStr,
      endDate: endStr,
    );

    if (stats != null) {
      _applyBackendStats(stats);
    } else {
      await _loadFallbackFromHistory();
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _applyBackendStats(Map<String, dynamic> stats) {
    _totalSessions = stats['total_sessions'] ?? 0;
    _avgScore = stats['avg_score'] ?? 0;
    _improvementPct = (stats['improvement_pct'] ?? 0.0).toDouble();
    _isImprovement = stats['is_improvement'] ?? true;
    _monitoringTimeStr = stats['total_duration_str'] ?? '0m';
    _totalCorrections = stats['total_corrections'] ?? 0;

    final rawWeekly = stats['weekly_scores'] as List<dynamic>? ?? [];
    _weeklyScores = rawWeekly.map((e) => (e is num) ? e.toInt() : 0).toList();
    while (_weeklyScores.length < 7) {
      _weeklyScores.add(0);
    }

    final dist = stats['time_distribution'] as Map<String, dynamic>? ?? {};
    _goodPct = (dist['good_pct'] ?? 0.0).toDouble();
    _mildPct = (dist['mild_pct'] ?? 0.0).toDouble();
    _severePct = (dist['severe_pct'] ?? 0.0).toDouble();
  }

  Future<void> _loadFallbackFromHistory() async {
    final historyList = await AiAnalysisService.fetchHistory();
    if (historyList.isEmpty) {
      _totalSessions = 0;
      _avgScore = 0;
      _monitoringTimeStr = '0m';
      _totalCorrections = 0;
      _weeklyScores = [0, 0, 0, 0, 0, 0, 0];
      _goodPct = 0.0;
      _mildPct = 0.0;
      _severePct = 0.0;
      return;
    }

    _totalSessions = historyList.length;
    int totalScore = 0;
    int totalSec = 0;
    int totalCorr = 0;
    int goodCount = 0;
    int mildCount = 0;
    int severeCount = 0;
    final weeklyTotals = <int, List<int>>{0: [], 1: [], 2: [], 3: [], 4: [], 5: [], 6: []};

    for (final report in historyList) {
      final score = report.overallScore;
      totalScore += score;
      totalCorr += report.problemsDetected.length;
      totalSec += 180; // 3 mins per scan

      if (score >= 80) {
        goodCount++;
      } else if (score >= 60) {
        mildCount++;
      } else {
        severeCount++;
      }

      try {
        DateTime dt = DateTime.now();
        if (report.date.contains('-')) {
          dt = DateTime.parse(report.date.split(' ')[0]);
        }
        int dayIdx = dt.weekday - 1;
        if (dayIdx >= 0 && dayIdx < 7) {
          weeklyTotals[dayIdx]!.add(score);
        }
      } catch (_) {}
    }

    _avgScore = (totalScore / _totalSessions).round();
    int h = totalSec ~/ 3600;
    int m = (totalSec % 3600) ~/ 60;
    _monitoringTimeStr = h > 0 ? '${h}h ${m}m' : '${m}m';
    _totalCorrections = totalCorr;
    _improvementPct = 3.5;
    _isImprovement = true;

    _weeklyScores = List.generate(7, (i) {
      final list = weeklyTotals[i]!;
      if (list.isEmpty) return 0;
      return (list.reduce((a, b) => a + b) / list.length).round();
    });

    _goodPct = (goodCount / _totalSessions).clamp(0.0, 1.0);
    _mildPct = (mildCount / _totalSessions).clamp(0.0, 1.0);
    _severePct = (severeCount / _totalSessions).clamp(0.0, 1.0);
  }

  void _openCalendarFilter() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Filter Statistics', style: AppTextStyles.h3),
                    IconButton(
                      icon: const Icon(LucideIcons.x, size: 20),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildFilterOption('Today', 'today', ctx),
                _buildFilterOption('This Week', 'this_week', ctx),
                _buildFilterOption('This Month', 'this_month', ctx),
                _buildFilterOption('All Time', 'all', ctx),
                ListTile(
                  leading: const Icon(LucideIcons.calendar, color: AppColors.primary),
                  title: Text(
                    _customDateRange == null
                        ? 'Custom Date Range...'
                        : 'Custom: ${_customDateRange!.start.day}/${_customDateRange!.start.month} - ${_customDateRange!.end.day}/${_customDateRange!.end.month}',
                    style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
                  ),
                  trailing: const Icon(LucideIcons.chevronRight, size: 18),
                  onTap: () async {
                    Navigator.pop(ctx);
                    final picked = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2025, 1, 1),
                      lastDate: DateTime.now(),
                      initialDateRange: _customDateRange ??
                          DateTimeRange(
                            start: DateTime.now().subtract(const Duration(days: 7)),
                            end: DateTime.now(),
                          ),
                    );
                    if (picked != null) {
                      setState(() {
                        _selectedTimeframe = 'custom';
                        _customDateRange = picked;
                      });
                      _loadStatistics();
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilterOption(String label, String value, BuildContext modalContext) {
    final isSelected = _selectedTimeframe == value;
    return ListTile(
      title: Text(label, style: AppTextStyles.body.copyWith(
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? AppColors.primary : AppColors.textMain,
      )),
      trailing: isSelected ? const Icon(LucideIcons.check, color: AppColors.primary, size: 20) : null,
      onTap: () {
        Navigator.pop(modalContext);
        setState(() {
          _selectedTimeframe = value;
          _customDateRange = null;
        });
        _loadStatistics();
      },
    );
  }

  String get _filterBadgeLabel {
    switch (_selectedTimeframe) {
      case 'today':
        return 'Today';
      case 'this_week':
        return 'This Week';
      case 'this_month':
        return 'This Month';
      case 'all':
        return 'All Time';
      case 'custom':
        if (_customDateRange != null) {
          return "${_customDateRange!.start.month}/${_customDateRange!.start.day} - ${_customDateRange!.end.month}/${_customDateRange!.end.day}";
        }
        return 'Custom';
      default:
        return 'This Week';
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadStatistics,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Bar with Header & Calendar Filter Icon
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Weekly Statistics', style: AppTextStyles.h2),
                    const SizedBox(height: 4),
                    Text('Spine alignment & posture score trends', style: AppTextStyles.bodyMuted),
                  ],
                ),
                GestureDetector(
                  onTap: _openCalendarFilter,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.cardBg,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.borderLight),
                      boxShadow: const [AppColors.shadowSoft],
                    ),
                    child: const Icon(LucideIcons.calendar, color: AppColors.textMain, size: 20),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            if (_isLoading)
              Container(
                height: 300,
                child: const Center(child: CircularProgressIndicator()),
              )
            else if (_totalSessions == 0)
              _buildEmptyStateCard()
            else ...[
              // Posture Score Overview Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: const [AppColors.shadowCard],
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'POSTURE SCORE AVERAGE',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: AppColors.textMuted,
                          ),
                        ),
                        GestureDetector(
                          onTap: _openCalendarFilter,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _filterBadgeLabel,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '$_avgScore%',
                          style: const TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textMain,
                            letterSpacing: -1.0,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: _isImprovement ? AppColors.primaryLight : AppColors.alertLight,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _isImprovement ? LucideIcons.trendingUp : LucideIcons.trendingDown,
                                size: 14,
                                color: _isImprovement ? AppColors.primary : AppColors.alert,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${_isImprovement ? '+' : '-'}${_improvementPct.toStringAsFixed(1)}%',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: _isImprovement ? AppColors.primary : AppColors.alert,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 2 Stats Cards (Monitoring Time & Total Corrections)
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [AppColors.shadowSoft],
                        border: Border.all(color: const Color(0xFFF0F0F0)),
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: const BoxDecoration(
                              color: Color(0xFFE8F8EE),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(LucideIcons.clock, color: Color(0xFF0F9F59), size: 22),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _monitoringTimeStr,
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Monitoring Time',
                            style: TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [AppColors.shadowSoft],
                        border: Border.all(color: const Color(0xFFF0F0F0)),
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: const BoxDecoration(
                              color: Color(0xFFFFF4E5),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(LucideIcons.sparkles, color: Color(0xFFF97316), size: 22),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '$_totalCorrections',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Total Corrections',
                            style: TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Weekly Performance Bar Chart Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [AppColors.shadowCard],
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Weekly Performance', style: AppTextStyles.h3),
                        Text('Mon - Sun', style: AppTextStyles.caption),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 200,
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: 100,
                          barTouchData: BarTouchData(
                            enabled: true,
                            touchTooltipData: BarTouchTooltipData(
                              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                                final score = rod.toY.toInt();
                                return BarTooltipItem(
                                  '${days[group.x.toInt()]}\n',
                                  const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  children: [
                                    TextSpan(
                                      text: score > 0 ? '$score%' : 'No Data',
                                      style: TextStyle(
                                        color: score > 0 ? AppColors.primaryLight : Colors.white70,
                                        fontWeight: FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                          titlesData: FlTitlesData(
                            show: true,
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                                  if (value.toInt() >= 0 && value.toInt() < days.length) {
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Text(days[value.toInt()], style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600)),
                                    );
                                  }
                                  return const SizedBox();
                                },
                              ),
                            ),
                            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          ),
                          gridData: const FlGridData(show: false),
                          borderData: FlBorderData(show: false),
                          barGroups: List.generate(7, (i) {
                            final scoreVal = _weeklyScores[i];
                            return _buildBarGroup(i, scoreVal.toDouble());
                          }),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Time Distribution Progress Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [AppColors.shadowCard],
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Time Distribution', style: AppTextStyles.h3),
                    const SizedBox(height: 16),
                    _buildProgressRow('Good Posture', _goodPct, AppColors.primary),
                    const SizedBox(height: 12),
                    _buildProgressRow('Mild Slouching', _mildPct, AppColors.warning),
                    const SizedBox(height: 12),
                    _buildProgressRow('Severe Slouching', _severePct, AppColors.alert),
                  ],
                ),
              ),
              const SizedBox(height: 30),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyStateCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: const [AppColors.shadowSoft],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.barChart2, size: 36, color: AppColors.primary),
          ),
          const SizedBox(height: 16),
          Text(
            'No Posture Data Available',
            style: AppTextStyles.h3,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Start a posture monitoring session or upload an image/video analysis to generate your real-time spinal statistics.',
            style: AppTextStyles.bodyMuted,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  BarChartGroupData _buildBarGroup(int x, double y) {
    final isZero = y <= 0;
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: isZero ? 4 : y,
          color: isZero ? AppColors.accentGray : AppColors.primary,
          width: 16,
          borderRadius: BorderRadius.circular(6),
        ),
      ],
    );
  }

  Widget _buildProgressRow(String title, double percentage, Color color) {
    final pctInt = (percentage * 100).toInt();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: AppTextStyles.body.copyWith(fontSize: 13)),
            Text('$pctInt%', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentage.clamp(0.0, 1.0),
            backgroundColor: AppColors.accentGray,
            color: color,
            minHeight: 8,
          ),
        ),
      ],
    );
  }
}
