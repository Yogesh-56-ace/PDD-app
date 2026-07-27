import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  bool _isLoading = true;
  String _activeTab = 'daily';
  Map<String, dynamic> _analyticsData = {};

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    try {
      final res = await ApiService.getAnalytics();
      setState(() {
        _analyticsData = res;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)));
    }

    final summary = _analyticsData['summary'] ?? {};
    final bucket = _analyticsData[_activeTab] as List? ?? [];

    final List<String> labels = bucket.isNotEmpty 
      ? bucket.map((item) => item['label'] as String).toList() 
      : ['No Data'];
    final List<double> scores = bucket.isNotEmpty 
      ? bucket.map((item) => (item['score'] as num).toDouble()).toList() 
      : [0.0];
    final List<double> alerts = bucket.isNotEmpty 
      ? bucket.map((item) => (item['alerts'] as num).toDouble()).toList() 
      : [0.0];

    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 900;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tab selection buttons
          Row(
            children: [
              _buildTabButton('Daily Stats', 'daily'),
              const SizedBox(width: 12),
              _buildTabButton('Weekly Stats', 'weekly'),
              const SizedBox(width: 12),
              _buildTabButton('Monthly Stats', 'monthly'),
            ],
          ),
          const SizedBox(height: 24),

          // Chart containers
          Wrap(
            spacing: 24,
            runSpacing: 24,
            children: [
              // 1. Line Chart card
              _buildChartCard(
                width: isMobile ? size.width - 48 : (size.width - 72) * 0.5,
                title: 'Average Posture Score Trend',
                child: CustomPaint(
                  size: const Size(double.infinity, 220),
                  painter: LineChartPainter(
                    scores: scores,
                    labels: labels,
                  ),
                ),
              ),

              // 2. Bar Chart card
              _buildChartCard(
                width: isMobile ? size.width - 48 : (size.width - 72) * 0.5,
                title: 'Slouch Alerts Triggered',
                child: CustomPaint(
                  size: const Size(double.infinity, 220),
                  painter: BarChartPainter(
                    alerts: alerts,
                    labels: labels,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Improvement analysis metrics card
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Biometric Posture Improvement Analysis',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0B2917)),
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 40,
                    runSpacing: 24,
                    alignment: WrapAlignment.spaceAround,
                    children: [
                      _buildSummaryMetric('Total Audits', '${summary['total_sessions'] ?? 0}'),
                      _buildSummaryMetric('Avg Score', '${(summary['avg_score'] ?? 0.0).toStringAsFixed(1)}%'),
                      _buildSummaryMetric('Healthy Alignment', '${(summary['avg_good_pct'] ?? 0.0).toStringAsFixed(1)}%'),
                      _buildSummaryMetric('Slouch Flags', '${summary['total_alerts'] ?? 0}', isDanger: true),
                    ],
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTabButton(String label, String tabName) {
    final isActive = _activeTab == tabName;
    return ElevatedButton(
      onPressed: () {
        setState(() {
          _activeTab = tabName;
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isActive ? const Color(0xFF0B2917) : Colors.white,
        foregroundColor: isActive ? Colors.white : Colors.grey,
        elevation: 0,
        side: BorderSide(color: isActive ? const Color(0xFF0B2917) : const Color(0xFFE5E7EB)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      child: Text(label),
    );
  }

  Widget _buildChartCard({required double width, required String title, required Widget child}) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0B2917))),
          const SizedBox(height: 24),
          child,
        ],
      ),
    );
  }

  Widget _buildSummaryMetric(String label, String value, {bool isDanger = false}) {
    return Container(
      width: 140,
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: isDanger ? Colors.red : const Color(0xFF10B981),
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }
}

class LineChartPainter extends CustomPainter {
  final List<double> scores;
  final List<String> labels;

  LineChartPainter({required this.scores, required this.labels});

  @override
  void paint(Canvas canvas, Size size) {
    final double width = size.width;
    final double height = size.height;

    final Paint gridPaint = Paint()
      ..color = Colors.grey[200]!
      ..strokeWidth = 1;

    // Draw baseline grid lines
    canvas.drawLine(Offset(0, height * 0.25), Offset(width, height * 0.25), gridPaint);
    canvas.drawLine(Offset(0, height * 0.5), Offset(width, height * 0.5), gridPaint);
    canvas.drawLine(Offset(0, height * 0.75), Offset(width, height * 0.75), gridPaint);
    canvas.drawLine(Offset(0, height), Offset(width, height), gridPaint);

    if (scores.isEmpty || (scores.length == 1 && scores[0] == 0)) return;

    final Paint linePaint = Paint()
      ..color = const Color(0xFF0B2917)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final Paint pointPaint = Paint()
      ..color = const Color(0xFF10B981)
      ..style = PaintingStyle.fill;

    final double stepX = scores.length > 1 ? width / (scores.length - 1) : width;

    // Draw score points path
    final Path path = Path();
    for (int i = 0; i < scores.length; i++) {
      // scale score 0-100 to canvas height
      final double x = i * stepX;
      final double y = height - (scores[i] / 100.0) * height * 0.8; // margin on top

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, linePaint);

    // Draw points & labels
    for (int i = 0; i < scores.length; i++) {
      final double x = i * stepX;
      final double y = height - (scores[i] / 100.0) * height * 0.8;

      canvas.drawCircle(Offset(x, y), 5, pointPaint);
      canvas.drawCircle(Offset(x, y), 5, Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 1.5);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class BarChartPainter extends CustomPainter {
  final List<double> alerts;
  final List<String> labels;

  BarChartPainter({required this.alerts, required this.labels});

  @override
  void paint(Canvas canvas, Size size) {
    final double width = size.width;
    final double height = size.height;

    final Paint gridPaint = Paint()
      ..color = Colors.grey[200]!
      ..strokeWidth = 1;

    canvas.drawLine(Offset(0, height * 0.25), Offset(width, height * 0.25), gridPaint);
    canvas.drawLine(Offset(0, height * 0.5), Offset(width, height * 0.5), gridPaint);
    canvas.drawLine(Offset(0, height * 0.75), Offset(width, height * 0.75), gridPaint);
    canvas.drawLine(Offset(0, height), Offset(width, height), gridPaint);

    if (alerts.isEmpty) return;

    final maxVal = alerts.reduce((currMax, val) => val > currMax ? val : currMax);
    final double scaleMax = maxVal > 0 ? maxVal * 1.2 : 5.0;

    final double stepX = width / alerts.length;
    final double barWidth = stepX * 0.4;

    final Paint barPaint = Paint()
      ..color = Colors.red.withOpacity(0.8)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < alerts.length; i++) {
      final double barHeight = (alerts[i] / scaleMax) * height * 0.8;
      final double x = i * stepX + (stepX - barWidth) / 2;
      final double y = height - barHeight;

      final RRect rrect = RRect.fromRectAndCorners(
        Rect.fromLTWH(x, y, barWidth, barHeight),
        topLeft: const Radius.circular(4),
        topRight: const Radius.circular(4),
      );
      canvas.drawRRect(rrect, barPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
