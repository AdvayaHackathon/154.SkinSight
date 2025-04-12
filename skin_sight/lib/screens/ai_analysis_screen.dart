import 'package:flutter/material.dart';
import '../models/ai_analysis_model.dart';

class AiAnalysisScreen extends StatelessWidget {
  final AiAnalysisModel analysis;
  
  const AiAnalysisScreen({
    Key? key, 
    required this.analysis,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Analysis Results'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Diagnosis'),
            _buildDiagnosisSection(),
            
            const SizedBox(height: 24),
            _buildSectionHeader('Area Analysis'),
            _buildAreaAnalysisSection(),
            
            const SizedBox(height: 24),
            _buildSectionHeader('Color Analysis'),
            _buildColorAnalysisSection(),
            
            const SizedBox(height: 24),
            _buildSectionHeader('PASI Assessment'),
            _buildPasiSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Color(0xFF0A8754),
        ),
      ),
    );
  }

  Widget _buildDiagnosisSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.medical_services,
                  color: _getSeverityColor(analysis.diagnosis.severity),
                  size: 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    analysis.diagnosis.severity,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              analysis.diagnosis.description,
              style: const TextStyle(fontSize: 16),
            ),
            if (analysis.diagnosis.recommendations.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Recommendations:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ...analysis.diagnosis.recommendations.map((rec) => 
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text('• $rec'),
                )
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAreaAnalysisSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Affected Area:', '${analysis.areaCalculation.psoriasisAreaCm2.toStringAsFixed(2)} cm²'),
            _buildInfoRow('Percentage of Region:', '${(analysis.areaAnalysis.areaPercentage * 100).toStringAsFixed(1)}%'),
            _buildInfoRow('Lesion Count:', analysis.areaAnalysis.lesionDetails.length.toString()),
            if (analysis.areaAnalysis.lesionDetails.isNotEmpty)
              _buildInfoRow('Largest Lesion:', '${analysis.areaAnalysis.lesionDetails.map((d) => d.areaPixels).reduce((a, b) => a > b ? a : b)} pixels'),
          ],
        ),
      ),
    );
  }

  Widget _buildColorAnalysisSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Erythema Score:', analysis.colorAnalysis.erythemaScore.toString()),
            _buildInfoRow('Average Redness:', '${(analysis.colorAnalysis.averageRednessPercentage * 100).toStringAsFixed(1)}%'),
            const SizedBox(height: 12),
            const Text(
              'Redness Details:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...analysis.colorAnalysis.rednessDetails.map((detail) => 
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('${detail.region}: ${(detail.redPercentage * 100).toStringAsFixed(1)}% (Intensity: ${detail.redIntensity.toStringAsFixed(1)})'),
              )
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasiSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Body Region:', analysis.pasiAssessment.bodyRegion),
            _buildInfoRow('Region Weight:', analysis.pasiAssessment.regionWeight.toString()),
            _buildInfoRow('Area Score:', analysis.pasiAssessment.areaScore.toString()),
            _buildInfoRow('Erythema Score:', analysis.pasiAssessment.erythemaScore.toString()),
            _buildInfoRow('Induration Score:', analysis.pasiAssessment.indurationScore.toString()),
            _buildInfoRow('Desquamation Score:', analysis.pasiAssessment.desquamationScore.toString()),
            _buildInfoRow('Regional PASI:', analysis.pasiAssessment.regionalPasi.toStringAsFixed(1)),
            _buildInfoRow('Total PASI Score:', analysis.pasiAssessment.pasiScore.toStringAsFixed(1)),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: analysis.pasiAssessment.pasiScore / 72, // Max PASI is 72
              backgroundColor: Colors.grey.shade200,
              color: _getPasiColor(analysis.pasiAssessment.pasiScore),
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 8),
            Text(
              analysis.pasiAssessment.pasiSeverity,
              style: TextStyle(
                color: _getPasiColor(analysis.pasiAssessment.pasiScore),
                fontWeight: FontWeight.bold,
              ),
            ),
            if (analysis.pasiAssessment.recommendations.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Recommendations:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ...analysis.pasiAssessment.recommendations.map((rec) => 
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text('• $rec'),
                )
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

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
}
