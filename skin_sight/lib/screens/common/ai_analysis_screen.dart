import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/ai_analysis_model.dart';
import 'dart:math' as math;

class AiAnalysisScreen extends StatefulWidget {
  final AiAnalysisModel analysis;
  
  const AiAnalysisScreen({
    Key? key, 
    required this.analysis,
  }) : super(key: key);

  @override
  State<AiAnalysisScreen> createState() => _AiAnalysisScreenState();
}

class _AiAnalysisScreenState extends State<AiAnalysisScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Analysis Results'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Area'),
            Tab(text: 'PASI'),
            Tab(text: 'Details'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildAreaAnalysisTab(),
          _buildPasiTab(),
          _buildDetailsTab(),
        ],
      ),
    );
  }
  
  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryCard(),
          const SizedBox(height: 16),
          _buildDiagnosisCard(),
          const SizedBox(height: 16),
          _buildSeverityIndicator(),
        ],
      ),
    );
  }
  
  Widget _buildAreaAnalysisTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAreaMetricsCard(),
          const SizedBox(height: 16),
          _buildAreaVisualizationCard(),
          const SizedBox(height: 16),
          if (widget.analysis.areaAnalysis.lesionDetails.isNotEmpty)
            _buildLesionDetailsCard(),
        ],
      ),
    );
  }
  
  Widget _buildPasiTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPasiScoreCard(),
          const SizedBox(height: 16),
          _buildPasiComponentsCard(),
          const SizedBox(height: 16),
          _buildPasiRecommendationsCard(),
        ],
      ),
    );
  }
  
  Widget _buildDetailsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildColorAnalysisCard(),
          const SizedBox(height: 16),
          _buildTechnicalDetailsCard(),
        ],
      ),
    );
  }
  
  // Overview Tab Widgets
  Widget _buildSummaryCard() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getSeverityColor(widget.analysis.diagnosis.severity).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.medical_services_outlined,
                    color: _getSeverityColor(widget.analysis.diagnosis.severity),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.analysis.diagnosis.condition,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Body Region: ${widget.analysis.pasiAssessment.bodyRegion}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Affected Area: ${widget.analysis.areaCalculation.psoriasisAreaCm2.toStringAsFixed(2)} cm²',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'PASI Score: ${widget.analysis.pasiAssessment.pasiScore.toStringAsFixed(1)}',
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiagnosisCard() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Diagnosis',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              widget.analysis.diagnosis.description,
              style: const TextStyle(fontSize: 16),
            ),
            if (widget.analysis.diagnosis.differentialDiagnosis.isNotEmpty) ...[  
              const SizedBox(height: 16),
              const Text(
                'Differential Diagnosis:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ...widget.analysis.diagnosis.differentialDiagnosis.map((diagnosis) =>
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.arrow_right, size: 20),
                      const SizedBox(width: 4),
                      Expanded(child: Text(diagnosis)),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSeverityIndicator() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Severity Assessment',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSeverityStep('Mild', widget.analysis.diagnosis.severity == 'Mild'),
                _buildSeverityDivider(),
                _buildSeverityStep('Moderate', widget.analysis.diagnosis.severity == 'Moderate'),
                _buildSeverityDivider(),
                _buildSeverityStep('Severe', widget.analysis.diagnosis.severity == 'Severe'),
                _buildSeverityDivider(),
                _buildSeverityStep('Very Severe', widget.analysis.diagnosis.severity == 'Very Severe'),
              ],
            ),
            const SizedBox(height: 16),
            if (widget.analysis.diagnosis.recommendations.isNotEmpty) ...[  
              const Text(
                'Recommendations:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ...widget.analysis.diagnosis.recommendations.map((rec) =>
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.check_circle_outline, size: 20, color: Colors.green),
                      const SizedBox(width: 8),
                      Expanded(child: Text(rec)),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildSeverityStep(String label, bool isActive) {
    return Column(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: isActive ? _getSeverityColor(label) : Colors.grey[300],
            shape: BoxShape.circle,
          ),
          child: isActive ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive ? _getSeverityColor(label) : Colors.grey[600],
          ),
        ),
      ],
    );
  }
  
  Widget _buildSeverityDivider() {
    return Container(
      width: 20,
      height: 2,
      color: Colors.grey[300],
    );
  }
  
  // Area Analysis Tab Widgets
  Widget _buildAreaMetricsCard() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Area Metrics',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildMetricRow(
              'Affected Area',
              '${widget.analysis.areaCalculation.psoriasisAreaCm2.toStringAsFixed(2)} cm²',
              Icons.straighten,
              Colors.blue,
            ),
            const Divider(height: 24),
            _buildMetricRow(
              'Percentage of Region',
              '${(widget.analysis.areaAnalysis.areaPercentage).toStringAsFixed(2)}%',
              Icons.pie_chart,
              Colors.orange,
            ),
            const Divider(height: 24),
            _buildMetricRow(
              'Lesion Count',
              widget.analysis.areaAnalysis.lesionDetails.length.toString(),
              Icons.format_list_numbered,
              Colors.purple,
            ),
            if (widget.analysis.areaAnalysis.lesionDetails.isNotEmpty) ...[  
              const Divider(height: 24),
              _buildMetricRow(
                'Largest Lesion',
                '${widget.analysis.areaAnalysis.lesionDetails.map((d) => d.areaPixels).reduce((a, b) => a > b ? a : b)} pixels',
                Icons.zoom_out_map,
                Colors.teal,
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildAreaVisualizationCard() {
    final areaPercentage = widget.analysis.areaAnalysis.areaPercentage;
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Area Visualization',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: SizedBox(
                height: 180,
                width: 180,
                child: CustomPaint(
                  painter: AreaPainter(areaPercentage),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${(areaPercentage).toStringAsFixed(2)}%',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          'Affected',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            LinearProgressIndicator(
              value: areaPercentage,
              backgroundColor: Colors.grey[200],
              color: _getAreaColor(areaPercentage),
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '0%',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                Text(
                  '50%',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                Text(
                  '100%',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildLesionDetailsCard() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Lesion Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...widget.analysis.areaAnalysis.lesionDetails.asMap().entries.map((entry) {
              final index = entry.key;
              final lesion = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.blue[100],
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[800],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Region: ${lesion.region}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text('Area: ${lesion.areaPixels} pixels'),
                          Text('Avg Depth: ${lesion.avgDepth.toStringAsFixed(2)}'),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
  
  // PASI Tab Widgets
  Widget _buildPasiScoreCard() {
    final pasiScore = widget.analysis.pasiAssessment.pasiScore;
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getPasiColor(pasiScore).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.assessment_outlined,
                    color: _getPasiColor(pasiScore),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'PASI Score',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.analysis.pasiAssessment.pasiSeverity,
                        style: TextStyle(
                          fontSize: 16,
                          color: _getPasiColor(pasiScore),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  pasiScore.toStringAsFixed(1),
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: _getPasiColor(pasiScore),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            LinearProgressIndicator(
              value: pasiScore / 72, // Max PASI is 72
              backgroundColor: Colors.grey[200],
              color: _getPasiColor(pasiScore),
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildPasiScoreLabel('Mild', 0, 5, pasiScore),
                _buildPasiScoreLabel('Moderate', 5, 10, pasiScore),
                _buildPasiScoreLabel('Severe', 10, 20, pasiScore),
                _buildPasiScoreLabel('Very Severe', 20, 72, pasiScore),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Body Region: ${widget.analysis.pasiAssessment.bodyRegion}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Regional PASI: ${widget.analysis.pasiAssessment.regionalPasi.toStringAsFixed(1)}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Estimated Total PASI: ${widget.analysis.pasiAssessment.estimatedTotalPasi.toStringAsFixed(1)}',
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPasiComponentsCard() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'PASI Components',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildPasiComponentRow(
              'Area',
              widget.analysis.pasiAssessment.areaScore,
              4,
              Colors.blue,
            ),
            const SizedBox(height: 16),
            _buildPasiComponentRow(
              'Erythema',
              widget.analysis.pasiAssessment.erythemaScore,
              4,
              Colors.red,
            ),
            const SizedBox(height: 16),
            _buildPasiComponentRow(
              'Induration',
              widget.analysis.pasiAssessment.indurationScore,
              4,
              Colors.purple,
            ),
            const SizedBox(height: 16),
            _buildPasiComponentRow(
              'Desquamation',
              widget.analysis.pasiAssessment.desquamationScore,
              4,
              Colors.amber,
            ),
            const SizedBox(height: 24),
            const Text(
              'PASI Formula:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Regional PASI = ${widget.analysis.pasiAssessment.regionWeight} × (${widget.analysis.pasiAssessment.erythemaScore} + ${widget.analysis.pasiAssessment.indurationScore} + ${widget.analysis.pasiAssessment.desquamationScore}) × ${widget.analysis.pasiAssessment.areaScore}',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              '= ${widget.analysis.pasiAssessment.regionalPasi.toStringAsFixed(1)}',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPasiRecommendationsCard() {
    if (widget.analysis.pasiAssessment.recommendations.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'PASI-Based Recommendations',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...widget.analysis.pasiAssessment.recommendations.map((rec) =>
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.check_circle, color: Colors.green[600], size: 20),
                    const SizedBox(width: 12),
                    Expanded(child: Text(rec)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Details Tab Widgets
  Widget _buildColorAnalysisCard() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Color Analysis',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildMetricRow(
              'Erythema Score',
              widget.analysis.colorAnalysis.erythemaScore.toString(),
              Icons.colorize,
              Colors.red,
            ),
            const Divider(height: 24),
            _buildMetricRow(
              'Average Redness',
              '${(widget.analysis.colorAnalysis.averageRednessPercentage).toStringAsFixed(2)}%',
              Icons.opacity,
              Colors.redAccent,
            ),
            const SizedBox(height: 16),
            const Text(
              'Redness Details:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...widget.analysis.colorAnalysis.rednessDetails.map((detail) =>
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Color.fromRGBO(
                          255, 
                          (255 * (1 - detail.redPercentage)).toInt(),
                          (255 * (1 - detail.redPercentage)).toInt(),
                          1,
                        ),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${detail.region}: ${(detail.redPercentage).toStringAsFixed(2)}% (Intensity: ${detail.redIntensity.toStringAsFixed(1)})',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTechnicalDetailsCard() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Technical Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Sticker Found', widget.analysis.areaCalculation.stickerFound ? 'Yes' : 'No'),
            _buildInfoRow('Sticker Radius', '${widget.analysis.areaCalculation.stickerRadiusPixels} pixels'),
            _buildInfoRow('Sticker Area', '${widget.analysis.areaCalculation.stickerAreaMm2.toStringAsFixed(2)} mm²'),
            _buildInfoRow('Scale Factor', widget.analysis.areaCalculation.scaleFactor.toStringAsFixed(5)),
            _buildInfoRow('Psoriasis Area (pixels)', widget.analysis.areaCalculation.psoriasisAreaPixels.toStringAsFixed(1)),
            _buildInfoRow('Psoriasis Area (mm²)', widget.analysis.areaCalculation.psoriasisAreaMm2.toStringAsFixed(2)),
            _buildInfoRow('Affected Pixels', widget.analysis.areaAnalysis.affectedPixels.toString()),
            _buildInfoRow('Total Pixels', widget.analysis.areaAnalysis.totalPixels.toString()),
            if (widget.analysis.note != null && widget.analysis.note!.isNotEmpty)
              _buildInfoRow('Note', widget.analysis.note!),
          ],
        ),
      ),
    );
  }
  
  // Helper Methods
  Widget _buildMetricRow(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
  
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPasiScoreLabel(String label, double min, double max, double score) {
    final bool isInRange = score >= min && score < max;
    return Text(
      label,
      style: TextStyle(
        fontSize: 12,
        fontWeight: isInRange ? FontWeight.bold : FontWeight.normal,
        color: isInRange ? _getPasiColor(score) : Colors.grey[600],
      ),
    );
  }
  
  Widget _buildPasiComponentRow(String label, int value, int maxValue, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '$value / $maxValue',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: value / maxValue,
          backgroundColor: Colors.grey[200],
          color: color,
          minHeight: 6,
          borderRadius: BorderRadius.circular(3),
        ),
      ],
    );
  }

  // Color Utility Methods
  Color _getPasiColor(double pasi) {
    if (pasi < 5) return Colors.green;
    if (pasi < 10) return Colors.orange;
    if (pasi < 20) return Colors.deepOrange;
    return Colors.red;
  }
  
  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'mild':
        return Colors.green;
      case 'moderate':
        return Colors.orange;
      case 'severe':
        return Colors.deepOrange;
      case 'very severe':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }
  
  Color _getAreaColor(double percentage) {
    if (percentage < 0.1) return Colors.green;
    if (percentage < 0.3) return Colors.amber;
    if (percentage < 0.5) return Colors.orange;
    return Colors.red;
  }
}

// Custom Painter for Area Visualization
class AreaPainter extends CustomPainter {
  final double percentage;
  
  AreaPainter(this.percentage);
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    
    // Draw background circle
    final backgroundPaint = Paint()
      ..color = Colors.grey[200]!
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, backgroundPaint);
    
    // Draw affected area
    final affectedPaint = Paint()
      ..color = _getColorForPercentage(percentage)
      ..style = PaintingStyle.fill;
    
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,  // Start from top
      2 * math.pi * percentage,  // Arc angle based on percentage
      true,  // Use center
      affectedPaint,
    );
    
    // Draw border
    final borderPaint = Paint()
      ..color = Colors.grey[400]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, radius, borderPaint);
  }
  
  Color _getColorForPercentage(double percentage) {
    if (percentage < 0.1) return Colors.green[400]!;
    if (percentage < 0.3) return Colors.amber[400]!;
    if (percentage < 0.5) return Colors.orange[400]!;
    return Colors.red[400]!;
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
