import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recoveryplus/services/export_service.dart';
import 'package:recoveryplus/services/statistics_service.dart';
import 'package:recoveryplus/providers/theme_provider.dart';

class StatisticsScreen extends StatefulWidget {
  @override
  _StatisticsScreenState createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  Map<String, dynamic> _statistics = {};
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      final stats = await StatisticsService.getRecoveryStatistics();
      setState(() {
        _statistics = stats;
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  Future<void> _exportStatistics() async {
    try {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Preparing statistics report...')));

      await ExportService.exportStatisticsReport();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Statistics report exported successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Export failed: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: Text('Recovery Statistics'),
        backgroundColor: isDarkMode
            ? Colors.grey.shade900
            : Colors.blue.shade700,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadStatistics,
            tooltip: 'Refresh Statistics',
          ),
          IconButton(
            icon: Icon(Icons.download),
            onPressed: _exportStatistics,
            tooltip: 'Export Statistics Report',
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _hasError
          ? _buildErrorState(isDarkMode)
          : _statistics.isEmpty
          ? _buildEmptyState(isDarkMode)
          : RefreshIndicator(
              onRefresh: _loadStatistics,
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildOverallScore(isDarkMode),
                    SizedBox(height: 20),
                    _buildPainStatistics(isDarkMode),
                    SizedBox(height: 20),
                    _buildMedicationStatistics(isDarkMode),
                    SizedBox(height: 20),
                    _buildExerciseStatistics(isDarkMode),
                    SizedBox(height: 20),
                    _buildWeeklyProgressChart(isDarkMode),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildErrorState(bool isDarkMode) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red),
          SizedBox(height: 16),
          Text(
            'Failed to load statistics',
            style: TextStyle(
              fontSize: 18,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Please check your connection and try again',
            style: TextStyle(
              color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
          SizedBox(height: 20),
          ElevatedButton(onPressed: _loadStatistics, child: Text('Try Again')),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDarkMode) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.analytics, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No data available yet',
            style: TextStyle(
              fontSize: 18,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Start tracking your recovery to see statistics',
            style: TextStyle(
              color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverallScore(bool isDarkMode) {
    final score = _statistics['overall_recovery_score'] ?? 0;
    return Card(
      color: isDarkMode ? Colors.grey.shade800 : Colors.white,
      elevation: 3,
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              'Overall Recovery Score',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            SizedBox(height: 16),
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 120,
                  height: 120,
                  child: CircularProgressIndicator(
                    value: score / 100,
                    strokeWidth: 12,
                    backgroundColor: isDarkMode
                        ? Colors.grey.shade600
                        : Colors.grey.shade300,
                    valueColor: AlwaysStoppedAnimation(_getScoreColor(score)),
                  ),
                ),
                Text(
                  '${score.toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Text(
              _getScoreDescription(score),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPainStatistics(bool isDarkMode) {
    final pain = _statistics['pain'] as Map<String, dynamic>?;
    if (pain == null || pain.isEmpty) return SizedBox();

    return Card(
      color: isDarkMode ? Colors.grey.shade800 : Colors.white,
      elevation: 3,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.health_and_safety, color: Colors.red),
                SizedBox(width: 8),
                Text(
                  'Pain Analysis',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            _buildStatRow(
              'Average Pain',
              '${pain['average_pain']?.toStringAsFixed(1) ?? "0"} / 10',
              isDarkMode,
            ),
            _buildStatRow(
              'Highest Pain',
              '${pain['max_pain']?.toStringAsFixed(1) ?? "0"} / 10',
              isDarkMode,
            ),
            _buildStatRow(
              'Lowest Pain',
              '${pain['min_pain']?.toStringAsFixed(1) ?? "0"} / 10',
              isDarkMode,
            ),
            _buildStatRow(
              'Trend',
              pain['trend_description'] ?? 'No data',
              isDarkMode,
            ),
            _buildStatRow(
              'Total Entries',
              '${pain['total_entries'] ?? 0}',
              isDarkMode,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicationStatistics(bool isDarkMode) {
    final meds = _statistics['medications'] as Map<String, dynamic>?;
    if (meds == null || meds.isEmpty) return SizedBox();

    return Card(
      color: isDarkMode ? Colors.grey.shade800 : Colors.white,
      elevation: 3,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.medication, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Medication Adherence',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            _buildStatRow(
              'Adherence Rate',
              '${meds['adherence_rate']?.toStringAsFixed(1) ?? "0"}%',
              isDarkMode,
            ),
            _buildStatRow(
              'Level',
              meds['adherence_level'] ?? 'No data',
              isDarkMode,
            ),
            _buildStatRow(
              'Taken',
              '${meds['taken_medications']} / ${meds['total_medications']}',
              isDarkMode,
            ),
            _buildStatRow(
              'Missed',
              '${meds['missed_medications']}',
              isDarkMode,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseStatistics(bool isDarkMode) {
    final exercises = _statistics['exercises'] as Map<String, dynamic>?;
    if (exercises == null || exercises.isEmpty) return SizedBox();

    return Card(
      color: isDarkMode ? Colors.grey.shade800 : Colors.white,
      elevation: 3,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.fitness_center, color: Colors.green),
                SizedBox(width: 8),
                Text(
                  'Exercise Progress',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            _buildStatRow(
              'Completion Rate',
              '${exercises['completion_rate']?.toStringAsFixed(1) ?? "0"}%',
              isDarkMode,
            ),
            _buildStatRow(
              'Level',
              exercises['completion_level'] ?? 'No data',
              isDarkMode,
            ),
            _buildStatRow(
              'Completed',
              '${exercises['completed_exercises']} / ${exercises['total_exercises']}',
              isDarkMode,
            ),
            _buildStatRow(
              'Pending',
              '${exercises['pending_exercises']}',
              isDarkMode,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyProgressChart(bool isDarkMode) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: StatisticsService.getWeeklyProgress(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) return SizedBox();

        final weeklyData = snapshot.data!;
        return Card(
          color: isDarkMode ? Colors.grey.shade800 : Colors.white,
          elevation: 3,
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.timeline, color: Colors.orange),
                    SizedBox(width: 8),
                    Text(
                      'Weekly Pain Trend',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                ...weeklyData.map(
                  (week) => _buildWeekProgress(week, isDarkMode),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWeekProgress(Map<String, dynamic> week, bool isDarkMode) {
    final pain = (week['average_pain'] ?? 0).toDouble();
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              week['week'],
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: LinearProgressIndicator(
              value: pain / 10,
              backgroundColor: isDarkMode
                  ? Colors.grey.shade600
                  : Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation(_getPainColor(pain)),
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            flex: 1,
            child: Text(
              pain.toStringAsFixed(1),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, bool isDarkMode) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }

  Color _getPainColor(double pain) {
    if (pain <= 3) return Colors.green;
    if (pain <= 6) return Colors.orange;
    return Colors.red;
  }

  String _getScoreDescription(double score) {
    if (score >= 80) return 'Excellent recovery progress! Keep it up!';
    if (score >= 60) return 'Good progress. You\'re on the right track!';
    if (score >= 40) return 'Steady progress. Keep following your plan.';
    return 'Let\'s work on improving your recovery routine.';
  }
}
