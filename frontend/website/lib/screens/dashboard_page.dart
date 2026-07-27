import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/session.dart';

class DashboardPage extends StatefulWidget {
  final VoidCallback onStartScan;

  const DashboardPage({super.key, required this.onStartScan});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  List<PostureSession> _recentSessions = [];
  bool _isLoading = true;
  double _avgScore = 0.0;
  int _totalAlerts = 0;
  int _trackedMins = 0;
  int _dailyTarget = 30;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      final sessions = await ApiService.getSessions();
      final user = await ApiService.getUser();
      
      double scoreSum = 0;
      int alertsSum = 0;
      int durationSum = 0;

      for (var s in sessions) {
        scoreSum += s.postureScore;
        alertsSum += s.alertsTriggered;
        durationSum += s.duration;
      }

      setState(() {
        _recentSessions = sessions.take(5).toList();
        _avgScore = sessions.isNotEmpty ? scoreSum / sessions.length : 0.0;
        _totalAlerts = alertsSum;
        _trackedMins = (durationSum / 60).round();
        _dailyTarget = user != null ? (user['daily_target'] ?? 30) : 30;
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

    final double goalPct = _dailyTarget > 0 ? (_trackedMins / _dailyTarget) : 0.0;
    final int displayPct = (goalPct * 100).clamp(0, 100).round();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stat Cards Grid
          Wrap(
            spacing: 24,
            runSpacing: 24,
            children: [
              _buildStatCard(
                'Avg Posture Score',
                '${_avgScore.toStringAsFixed(1)}%',
                _avgScore >= 80 ? 'Good posture habit' : 'Moderate slouching risk',
                Icons.emoji_events_outlined,
                const Color(0xFFD1FAE5),
                const Color(0xFF047857),
              ),
              _buildStatCard(
                'Active Sessions',
                '${_recentSessions.length}',
                'Logs calculated dynamically',
                Icons.timer_outlined,
                const Color(0xFFE0F2FE),
                const Color(0xFF0369A1),
              ),
              _buildStatCard(
                'Slouch Alerts',
                '$_totalAlerts',
                'Posture adjustments made',
                Icons.warning_amber_outlined,
                const Color(0xFFFEE2E2),
                const Color(0xFFB91C1C),
              ),
            ],
          ),
          const SizedBox(height: 32),
          
          // Splits row: Goal ring + Quick Scanner CTA
          Wrap(
            spacing: 24,
            runSpacing: 24,
            children: [
              // Goal Ring card
              _buildSectionCard(
                width: 380,
                title: 'Spinal Health Goal',
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 140,
                          height: 140,
                          child: CircularProgressIndicator(
                            value: goalPct.clamp(0.0, 1.0),
                            strokeWidth: 12,
                            backgroundColor: Colors.grey[200],
                            color: const Color(0xFF10B981),
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$displayPct%',
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0B2917),
                              ),
                            ),
                            const Text(
                              'Complete',
                              style: TextStyle(color: Colors.grey, fontSize: 11),
                            ),
                          ],
                        )
                      ],
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            children: [
                              const Text('Target', style: TextStyle(color: Colors.grey, fontSize: 11)),
                              Text('$_dailyTarget min', style: const TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          Container(width: 1, height: 24, color: const Color(0xFFE5E7EB)),
                          Column(
                            children: [
                              const Text('Tracked', style: TextStyle(color: Colors.grey, fontSize: 11)),
                              Text('$_trackedMins min', style: const TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Launch CTA card
              _buildSectionCard(
                width: 380,
                title: 'Ergonomic Assistant',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.play_circle_fill, color: Color(0xFF10B981), size: 28),
                          const SizedBox(height: 8),
                          const Text(
                            'Scan your posture now',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0B2917)),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Run a quick 10-second camera test to analyze head alignment and slouch coefficients.',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: widget.onStartScan,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Start Live Scan'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Row(
                      children: [
                        Icon(Icons.lightbulb_outline, color: Color(0xFF10B981), size: 20),
                        SizedBox(width: 8),
                        Text('Ergonomics Tip', style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Ensure your webcam sits directly at eye level. Sit approximately 20-30 inches away from your screen.',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Recent Sessions list
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Recent Monitoring Sessions',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0B2917)),
                  ),
                  const SizedBox(height: 16),
                  if (_recentSessions.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text('No tracking sessions recorded. Launch scanner to record sessions.', style: TextStyle(color: Colors.grey)),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _recentSessions.length,
                      separatorBuilder: (context, index) => const Divider(color: Color(0xFFE5E7EB)),
                      itemBuilder: (context, index) {
                        final s = _recentSessions[index];
                        final score = s.postureScore.round();
                        
                        Color scoreColor = const Color(0xFF10B981);
                        if (score < 60) {
                          scoreColor = Colors.red;
                        } else if (score < 80) {
                          scoreColor = Colors.orange;
                        }

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    s.timestamp.toLocal().toString().split('.')[0],
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    'Duration: ${s.duration} seconds • Alerts: ${s.alertsTriggered} flags',
                                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: scoreColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '$score%',
                                  style: TextStyle(
                                    color: scoreColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String label, String value, String sub, IconData icon, Color bg, Color iconColor) {
    return Container(
      width: 240,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.w600)),
                Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0B2917))),
                Text(sub, style: const TextStyle(color: Colors.grey, fontSize: 10)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSectionCard({required double width, required String title, required Widget child}) {
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
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0B2917))),
          const SizedBox(height: 24),
          child,
        ],
      ),
    );
  }
}
