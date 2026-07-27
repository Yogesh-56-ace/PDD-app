import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/session.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<PostureSession> _allSessions = [];
  List<PostureSession> _filteredSessions = [];
  bool _isLoading = true;
  final _searchController = TextEditingController();
  String _filterVal = 'all';

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final list = await ApiService.getSessions();
      setState(() {
        _allSessions = list;
        _filteredSessions = list;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _applyFilter() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      _filteredSessions = _allSessions.where((s) {
        final dateStr = s.timestamp.toLocal().toString().toLowerCase();
        final scoreStr = s.postureScore.round().toString();
        final matchesSearch = dateStr.contains(query) || scoreStr.contains(query);

        bool matchesDropdown = true;
        if (_filterVal == 'good') {
          matchesDropdown = s.postureScore >= 80;
        } else if (_filterVal == 'warning') {
          matchesDropdown = s.postureScore >= 50 && s.postureScore < 80;
        } else if (_filterVal == 'bad') {
          matchesDropdown = s.postureScore < 50;
        }

        return matchesSearch && matchesDropdown;
      }).toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)));
    }

    final double width = MediaQuery.of(context).size.width;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Card(
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
                'Posture Session History Logs',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0B2917)),
              ),
              const SizedBox(height: 16),
              
              // Filter controls Row
              Wrap(
                spacing: 16,
                runSpacing: 16,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SizedBox(
                    width: 250,
                    height: 40,
                    child: TextField(
                      controller: _searchController,
                      onChanged: (v) => _applyFilter(),
                      decoration: const InputDecoration(
                        labelText: 'Search logs...',
                        prefixIcon: Icon(Icons.search, size: 20),
                        contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 180,
                    height: 40,
                    child: DropdownButtonFormField<String>(
                      value: _filterVal,
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'all', child: Text('All Scores')),
                        DropdownMenuItem(value: 'good', child: Text('Good (>=80%)')),
                        DropdownMenuItem(value: 'warning', child: Text('Moderate (50-80%)')),
                        DropdownMenuItem(value: 'bad', child: Text('Poor (<50%)')),
                      ],
                      onChanged: (val) {
                        setState(() {
                          _filterVal = val!;
                          _applyFilter();
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Data table representation
              if (_filteredSessions.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: Center(
                    child: Text('No matching session records found.', style: TextStyle(color: Colors.grey)),
                  ),
                )
              else
                width < 700 
                ? ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _filteredSessions.length,
                    separatorBuilder: (context, index) => const Divider(color: Color(0xFFE5E7EB)),
                    itemBuilder: (context, index) => _buildMobileLogTile(_filteredSessions[index]),
                  )
                : _buildDesktopTable(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopTable() {
    return Table(
      border: const TableBorder(
        bottom: BorderSide(color: Color(0xFFE5E7EB)),
        horizontalInside: BorderSide(color: Color(0xFFF3F4F6)),
      ),
      columnWidths: const {
        0: FlexColumnWidth(3),
        1: FlexColumnWidth(2),
        2: FlexColumnWidth(2),
        3: FlexColumnWidth(2),
        4: FlexColumnWidth(2),
        5: FlexColumnWidth(2),
      },
      children: [
        // Table Header
        TableRow(
          decoration: const BoxDecoration(color: Color(0xFFF9FAFB)),
          children: [
            _buildHeaderCell('Date & Time'),
            _buildHeaderCell('Duration'),
            _buildHeaderCell('Score'),
            _buildHeaderCell('Good Posture'),
            _buildHeaderCell('Bad Posture'),
            _buildHeaderCell('Alerts'),
          ],
        ),
        // Table Rows
        ..._filteredSessions.map((s) {
          final dateStr = s.timestamp.toLocal().toString().split('.')[0];
          final score = s.postureScore.round();
          
          Color scoreColor = const Color(0xFF10B981);
          if (score < 60) {
            scoreColor = Colors.red;
          } else if (score < 80) {
            scoreColor = Colors.orange;
          }

          return TableRow(
            children: [
              _buildDataCell(dateStr, isBold: true),
              _buildDataCell('${s.duration}s scan'),
              TableCell(
                verticalAlignment: TableCellVerticalAlignment.middle,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: scoreColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$score%',
                          style: TextStyle(color: scoreColor, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              _buildDataCell('${s.goodPercentage.round()}%', color: const Color(0xFF10B981)),
              _buildDataCell('${s.badPercentage.round()}%', color: Colors.red),
              _buildDataCell('${s.alertsTriggered} flags'),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildHeaderCell(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF374151), fontSize: 13),
      ),
    );
  }

  Widget _buildDataCell(String text, {bool isBold = false, Color? color}) {
    return TableCell(
      verticalAlignment: TableCellVerticalAlignment.middle,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
        child: Text(
          text,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: color ?? const Color(0xFF1F2937),
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLogTile(PostureSession s) {
    final dateStr = s.timestamp.toLocal().toString().split('.')[0];
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(dateStr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Text(
                  'Duration: ${s.duration}s • Good: ${s.goodPercentage.round()}% • Alerts: ${s.alertsTriggered}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: scoreColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$score%',
              style: TextStyle(color: scoreColor, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
