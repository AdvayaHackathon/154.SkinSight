import 'package:flutter/material.dart';
import '../../models/ai_analysis_model.dart';

class AiAnalysisScreen extends StatelessWidget {
  final AiAnalysisModel analysis;
  
  const AiAnalysisScreen({super.key, required this.analysis});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Analysis Results'),
        backgroundColor: const Color(0xFF0A8754),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary Card
            _buildSummaryCard(),
            const SizedBox(height: 16),
            
            // Diagnosis Section
            _buildSectionHeader('Diagnosis & Recommendations'),
            _buildDiagnosisCard(),
            const SizedBox(height: 16),
            
            // PASI Assessment Section
            _buildSectionHeader('PASI Assessment'),
            _buildPasiCard(),
            const SizedBox(height: 16),
            
            // Area Analysis Section
            _buildSectionHeader('Area Analysis'),
            _buildAreaAnalysisCard(),
            const SizedBox(height: 16),
            
            // Color Analysis Section
            _buildSectionHeader('Color Analysis'),
            _buildColorAnalysisCard(),
            const SizedBox(height: 16),
            
            // Technical Details Section
            _buildSectionHeader('Technical Details'),
            _buildTechnicalDetailsCard(),
            const SizedBox(height: 24),
            
            // Note
            if (analysis.note != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.amber.shade800),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        analysis.note!,
                        style: TextStyle(color: Colors.amber.shade900),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF0A8754),
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: _getSeverityColor(analysis.diagnosis.severity).withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.medical_information,
                  color: _getSeverityColor(analysis.diagnosis.severity),
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Severity: ${analysis.diagnosis.severity}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _getSeverityColor(analysis.diagnosis.severity),
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
            const SizedBox(height: 8),
            Text(
              'PASI Score: ${analysis.pasiAssessment.pasiScore}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              'Affected Area: ${analysis.areaAnalysis.areaPercentage}% of ${analysis.pasiAssessment.bodyRegion}',
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiagnosisCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              analysis.diagnosis.description,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Recommended Treatments:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...analysis.diagnosis.recommendations.map((rec) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.check_circle, color: Color(0xFF0A8754), size: 20),
                  const SizedBox(width: 8),
                  Expanded(child: Text(rec)),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildPasiCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildPasiItem(
                    'PASI Score',
                    analysis.pasiAssessment.pasiScore.toString(),
                    'Total score',
                  ),
                ),
                Expanded(
                  child: _buildPasiItem(
                    'Body Region',
                    analysis.pasiAssessment.bodyRegion,
                    'Weight: ${analysis.pasiAssessment.regionWeight}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildPasiItem(
                    'Erythema',
                    analysis.pasiAssessment.erythemaScore.toString(),
                    'Redness score',
                  ),
                ),
                Expanded(
                  child: _buildPasiItem(
                    'Induration',
                    analysis.pasiAssessment.indurationScore.toString(),
                    'Thickness score',
                  ),
                ),
                Expanded(
                  child: _buildPasiItem(
                    'Desquamation',
                    analysis.pasiAssessment.desquamationScore.toString(),
                    'Scaling score',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildPasiItem(
              'Area Score',
              analysis.pasiAssessment.areaScore.toString(),
              'Based on ${analysis.areaAnalysis.areaPercentage}% coverage',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasiItem(String title, String value, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildAreaAnalysisCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildMetricItem(
                    'Area',
                    '${analysis.areaCalculation.psoriasisAreaCm2} cm²',
                    '${analysis.areaCalculation.psoriasisAreaMm2} mm²',
                  ),
                ),
                Expanded(
                  child: _buildMetricItem(
                    'Coverage',
                    '${analysis.areaAnalysis.areaPercentage}%',
                    'of body region',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Lesion Details:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...analysis.areaAnalysis.lesionDetails.map((lesion) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text('Region: ${lesion.region}\nArea: ${lesion.areaPixels} pixels'),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildColorAnalysisCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildMetricItem(
                    'Redness',
                    '${analysis.colorAnalysis.averageRednessPercentage}%',
                    'average percentage',
                  ),
                ),
                Expanded(
                  child: _buildMetricItem(
                    'Erythema Score',
                    analysis.colorAnalysis.erythemaScore.toString(),
                    'severity level',
                  ),
                ),
              ],
            ),
            if (analysis.colorAnalysis.rednessDetails.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Redness Details:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ...analysis.colorAnalysis.rednessDetails.map((detail) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(
                  'Region: ${detail.region}\nRedness: ${detail.redPercentage}%\nIntensity: ${detail.redIntensity}',
                ),
              )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTechnicalDetailsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildMetricItem(
                    'Reference Sticker',
                    analysis.areaCalculation.stickerFound ? 'Detected' : 'Not Found',
                    analysis.areaCalculation.stickerFound 
                        ? '${analysis.areaCalculation.stickerAreaMm2} mm²' 
                        : 'Using estimated scale',
                  ),
                ),
                Expanded(
                  child: _buildMetricItem(
                    'Scale Factor',
                    analysis.areaCalculation.scaleFactor.toStringAsFixed(5),
                    'mm² per pixel',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildMetricItem(
                    'Image Size',
                    '${analysis.areaAnalysis.totalPixels} px',
                    'total pixels',
                  ),
                ),
                Expanded(
                  child: _buildMetricItem(
                    'Affected Area',
                    '${analysis.areaAnalysis.affectedPixels} px',
                    'pixels with psoriasis',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricItem(String title, String value, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'mild':
        return Colors.green;
      case 'moderate':
        return Colors.orange;
      case 'severe':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }
}
