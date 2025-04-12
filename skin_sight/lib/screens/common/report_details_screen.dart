import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/report_model.dart';
import '../../models/user_model.dart';
import '../../models/ai_analysis_model.dart';
import 'ai_analysis_screen.dart';
import '../../widgets/ai_analysis_button.dart';
import '../doctor/review_patient_report_screen.dart';

class ReportDetailsScreen extends StatelessWidget {
  final ReportModel report;
  final UserModel viewer; // The current user viewing the report
  final UserModel patient; // The patient the report belongs to
  final Function? onReportUpdated; // Callback to refresh reports list
  
  const ReportDetailsScreen({
    Key? key,
    required this.report,
    required this.viewer,
    required this.patient,
    this.onReportUpdated,
  }) : super(key: key);

  bool get isDoctor => viewer.userType == 'doctor';
  bool get needsReview => report.diagnosis == 'Awaiting doctor review';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Details'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (isDoctor && needsReview)
            TextButton.icon(
              onPressed: () => _navigateToReview(context),
              icon: const Icon(Icons.edit, color: Colors.white),
              label: const Text(
                'Review',
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status banner for pending review
            if (needsReview)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.pending_actions, color: Colors.orange.shade800),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        isDoctor 
                            ? 'This report is awaiting your review'
                            : 'This report is awaiting doctor review',
                        style: TextStyle(
                          color: Colors.orange.shade800,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
            // Report summary card - new addition
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.history, color: Colors.grey),
                            const SizedBox(width: 8),
                            Text(
                              'Created: ${DateFormat('MMM d, yyyy').format(report.timestamp)}',
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                        _buildSeverityChip(report.severity),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoTile(
                            icon: Icons.medical_information,
                            title: 'Status',
                            value: needsReview ? 'Pending Review' : 'Reviewed',
                            color: needsReview ? Colors.orange : Colors.green,
                          ),
                        ),
                        if (_getBodyRegion().isNotEmpty)
                          Expanded(
                            child: _buildInfoTile(
                              icon: Icons.accessibility_new,
                              title: 'Body Region',
                              value: _capitalizeFirstLetter(_getBodyRegion()),
                              color: Colors.blue,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Patient Info (for doctors)
            if (isDoctor) ...[
              _buildSectionHeader('Patient Information'),
              Card(
                elevation: 0,
                color: Colors.blue.shade50,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.blue.shade100),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.blue.shade100,
                            radius: 24,
                            child: const Icon(Icons.person, color: Colors.blue),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  patient.name,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (patient.pid != null)
                                  Text(
                                    'ID: ${patient.pid}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                  ),
                                if (patient.email.isNotEmpty)
                                  Text(
                                    patient.email,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                  ),
                                if (patient.phoneNumber != null && patient.phoneNumber!.isNotEmpty)
                                  Text(
                                    'Phone: ${patient.phoneNumber}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
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
              ),
              const SizedBox(height: 24),
            ],
            
            // Image Section
            if (report.imageUrl != null && report.imageUrl!.isNotEmpty) ...[
              _buildSectionHeader('Skin Image'),
              GestureDetector(
                onTap: () => _showFullImageView(context),
                child: Hero(
                  tag: 'report_image_${report.id}',
                  child: Container(
                    height: 300, // Increased height for better visibility
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(
                            report.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey.shade200,
                                child: const Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.broken_image, size: 48, color: Colors.grey),
                                      SizedBox(height: 8),
                                      Text('Image not available'),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                          Positioned(
                            right: 12,
                            bottom: 12,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Row(
                                children: [
                                  Icon(
                                    Icons.zoom_in,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Tap to zoom',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
            
            // Diagnosis Section
            if (report.diagnosis != null && report.diagnosis != 'Awaiting doctor review') ...[
              _buildSectionHeader('Diagnosis'),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    report.diagnosis!,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
            
            // Notes Section
            if (report.notes != null && report.notes!.isNotEmpty) ...[
              _buildSectionHeader('Notes'),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    report.notes!,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
            
            // AI Analysis Section
            _buildSectionHeader('AI Analysis'),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _hasAiAnalysis() ? Icons.check_circle : Icons.pending,
                          color: _hasAiAnalysis() ? Colors.green : Colors.orange,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _hasAiAnalysis() 
                              ? 'AI analysis has been performed for this report'
                              : 'No AI analysis has been performed yet',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_hasAiAnalysis()) ...[
                      // Display key AI insights if analysis exists
                      _buildAiInsightRow(
                        'Severity',
                        _getAiAnalysis()?.diagnosis.severity ?? 'Unknown',
                      ),
                      _buildAiInsightRow(
                        'PASI Score',
                        '${_getAiAnalysis()?.pasiAssessment.pasiScore.toStringAsFixed(1) ?? 'Unknown'}',
                      ),
                      _buildAiInsightRow(
                        'Affected Area',
                        '${(_getAiAnalysis()?.areaAnalysis.areaPercentage ?? 0) * 100}% of ${_capitalizeFirstLetter(_getBodyRegion())}',
                      ),
                      const SizedBox(height: 16),
                    ],
                    SizedBox(
                      width: double.infinity,
                      child: AiAnalysisButton(
                        existingAnalysis: _getAiAnalysis(),
                        bodyRegion: _getBodyRegion(),
                        imageUrl: report.imageUrl,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: isDoctor && needsReview
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton(
                  onPressed: () => _navigateToReview(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Review Report',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildAiInsightRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
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

  Widget _buildSeverityChip(String severity) {
    Color color;
    switch (severity.toLowerCase()) {
      case 'mild':
        color = Colors.green;
        break;
      case 'moderate':
        color = Colors.orange;
        break;
      case 'severe':
        color = Colors.red;
        break;
      case 'very severe':
        color = Colors.purple;
        break;
      default:
        color = Colors.blue;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color),
      ),
      child: Row(
        children: [
          Icon(Icons.circle, size: 12, color: color),
          const SizedBox(width: 6),
          Text(
            severity,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _showFullImageView(BuildContext context) {
    if (report.imageUrl == null || report.imageUrl!.isEmpty) return;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            elevation: 0,
            title: const Text('Image Viewer'),
          ),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: InteractiveViewer(
                    panEnabled: true,
                    boundaryMargin: const EdgeInsets.all(80),
                    minScale: 0.5,
                    maxScale: 5.0,
                    child: Hero(
                      tag: 'report_image_${report.id}',
                      child: Image.network(
                        report.imageUrl!,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.broken_image, size: 60, color: Colors.white),
                              SizedBox(height: 16),
                              Text(
                                'Failed to load image',
                                style: TextStyle(color: Colors.white),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
                // Instructions for interactive viewing
                Container(
                  color: Colors.black,
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.pinch, color: Colors.white70),
                      const SizedBox(width: 8),
                      Text(
                        'Pinch to zoom, drag to pan',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToReview(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReviewPatientReportScreen(
          report: report,
          patient: patient,
        ),
      ),
    ).then((result) {
      if (result == true && onReportUpdated != null) {
        onReportUpdated!();
      }
    });
  }

  bool _hasAiAnalysis() {
    if (report.additionalData == null) return false;
    
    try {
      AiAnalysisModel.fromJson(report.additionalData!);
      return true;
    } catch (e) {
      return false;
    }
  }

  AiAnalysisModel? _getAiAnalysis() {
    if (!_hasAiAnalysis()) return null;
    
    try {
      return AiAnalysisModel.fromJson(report.additionalData!);
    } catch (e) {
      return null;
    }
  }

  String _getBodyRegion() {
    if (report.additionalData != null && report.additionalData!.containsKey('bodyRegion')) {
      return report.additionalData!['bodyRegion'] as String;
    }
    
    if (_hasAiAnalysis()) {
      try {
        final analysis = AiAnalysisModel.fromJson(report.additionalData!);
        return analysis.pasiAssessment.bodyRegion;
      } catch (e) {
        return 'trunk';
      }
    }
    
    return 'trunk';
  }
  
  String _capitalizeFirstLetter(String text) {
    if (text.isEmpty) return '';
    return text[0].toUpperCase() + text.substring(1);
  }
} 