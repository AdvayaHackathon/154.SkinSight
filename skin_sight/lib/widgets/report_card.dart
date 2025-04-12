import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/ai_analysis_model.dart';
import '../models/report_model.dart';
import '../models/user_model.dart';
import 'ai_analysis_button.dart';

class ReportCard extends StatelessWidget {
  final ReportModel report;
  final UserModel? patient;
  final UserModel? doctor;
  final VoidCallback? onTap;
  final bool showPatientInfo;
  final bool showDoctorInfo;
  
  const ReportCard({
    Key? key,
    required this.report,
    this.patient,
    this.doctor,
    this.onTap,
    this.showPatientInfo = false,
    this.showDoctorInfo = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Try to extract AI analysis data if available
    AiAnalysisModel? aiAnalysis;
    if (report.additionalData != null) {
      try {
        aiAnalysis = AiAnalysisModel.fromJson(report.additionalData!);
      } catch (e) {
        print('Error parsing AI analysis data: $e');
      }
    }
    
    // Determine body region for AI analysis
    String bodyRegion = 'trunk';
    if (aiAnalysis != null && aiAnalysis.pasiAssessment.bodyRegion.isNotEmpty) {
      bodyRegion = aiAnalysis.pasiAssessment.bodyRegion;
    }
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date and Severity Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DateFormat('MMM d, yyyy').format(report.timestamp),
                        style: const TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      _buildSeverityChip(report.severity),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Patient Info (if showing)
                  if (showPatientInfo && patient != null) ...[
                    Row(
                      children: [
                        const Icon(Icons.person, size: 16, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text(
                          'Patient: ${patient!.name}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    if (patient!.pid != null)
                      Padding(
                        padding: const EdgeInsets.only(left: 24.0),
                        child: Text('ID: ${patient!.pid}'),
                      ),
                    const SizedBox(height: 12),
                  ],
                  
                  // Doctor Info (if showing)
                  if (showDoctorInfo && doctor != null) ...[
                    Row(
                      children: [
                        const Icon(Icons.medical_services, size: 16, color: Colors.green),
                        const SizedBox(width: 8),
                        Text(
                          'Doctor: ${doctor!.name}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                  
                  // Diagnosis
                  if (report.diagnosis != null && report.diagnosis!.isNotEmpty) ...[
                    const Text(
                      'Diagnosis:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      report.diagnosis!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                  ],
                  
                  // Notes (preview only)
                  if (report.notes != null && report.notes!.isNotEmpty) ...[
                    const Text(
                      'Notes:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      report.notes!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                  ],
                  
                  // Image Preview
                  if (report.imageUrl != null && report.imageUrl!.isNotEmpty) ...[
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            report.imageUrl!,
                            height: 150,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 150,
                                width: double.infinity,
                                color: Colors.grey.shade200,
                                child: const Center(
                                  child: Icon(Icons.broken_image, size: 50, color: Colors.grey),
                                ),
                              );
                            },
                          ),
                        ),
                        Positioned(
                          bottom: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.fullscreen, color: Colors.white, size: 12),
                                SizedBox(width: 4),
                                Text(
                                  'View Full Image',
                                  style: TextStyle(color: Colors.white, fontSize: 10),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  // AI Analysis Button
                  AiAnalysisButton(
                    existingAnalysis: aiAnalysis,
                    imageUrl: report.imageUrl,
                    bodyRegion: bodyRegion,
                  ),
                ],
              ),
            ),
            // View details indicator in the top right
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.visibility, color: Colors.white, size: 12),
                    SizedBox(width: 4),
                    Text(
                      'View Details',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color),
      ),
      child: Text(
        severity,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}