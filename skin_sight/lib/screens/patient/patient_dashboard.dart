import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../models/report_model.dart';
import '../../services/report_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/report_card.dart';
import '../../screens/ai_analysis_screen.dart';
import '../../models/ai_analysis_model.dart';
import 'add_patient_report_screen.dart';

class PatientDashboard extends StatefulWidget {
  final UserModel user;
  
  const PatientDashboard({super.key, required this.user});

  @override
  State<PatientDashboard> createState() => _PatientDashboardState();
}

class _PatientDashboardState extends State<PatientDashboard> {
  List<ReportModel> _reports = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final reports = await ReportService.getPatientReports(widget.user.uid);
      
      if (mounted) {
        setState(() {
          _reports = reports;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading reports: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Gradient header with patient info
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).primaryColor,
                    Theme.of(context).primaryColor.withOpacity(0.7),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    spreadRadius: 2,
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'My Psoriasis Reports',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.logout, color: Colors.white),
                        onPressed: () async {
                          await AuthService.signOut();
                          if (context.mounted) {
                            Navigator.of(context).pushReplacementNamed('/welcome');
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.white.withOpacity(0.9),
                        radius: 30,
                        child: const Icon(Icons.person, color: Color(0xFF0A8754), size: 30),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.user.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            if (widget.user.pid != null)
                              Text(
                                'ID: ${widget.user.pid}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.white70,
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
            
            // Reports list or empty state
            if (_isLoading)
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_reports.isEmpty)
              _buildEmptyReportsState()
            else
              _buildReportsList(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddPatientReportScreen(patient: widget.user),
            ),
          ).then((_) => _loadReports());
        },
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.add_photo_alternate),
      ),
    );
  }

  Widget _buildReportsList() {
    return Expanded(
      child: RefreshIndicator(
        onRefresh: _loadReports,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _reports.length,
          itemBuilder: (context, index) {
            final report = _reports[index];
            
            return ReportCard(
              report: report,
              patient: widget.user,
              onTap: () => _showReportDetails(report),
              showPatientInfo: false,
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyReportsState() {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.medical_information_outlined,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No Reports Yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Add your first psoriasis report to start tracking your condition',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddPatientReportScreen(patient: widget.user),
                  ),
                ).then((_) => _loadReports());
              },
              icon: const Icon(Icons.add_photo_alternate),
              label: const Text('Add First Report'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showReportDetails(ReportModel report) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Report Details',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Image preview
              if (report.imageUrl != null && report.imageUrl!.isNotEmpty) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    children: [
                      Image.network(
                        report.imageUrl!,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 200,
                            width: double.infinity,
                            color: Colors.grey.shade200,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.broken_image,
                                  size: 50,
                                  color: Colors.grey.shade700,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Failed to load image',
                                  style: TextStyle(color: Colors.red.shade700),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              // Report details
              _buildInfoRow('Date:', _formatDate(report.timestamp)),
              _buildInfoRow('Severity:', report.severity),
              if (report.diagnosis != null)
                _buildInfoRow('Diagnosis:', report.diagnosis!),
              
              // Doctor's notes
              if (report.notes != null && report.notes!.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Text(
                  'Doctor\'s Notes:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(12),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Text(report.notes!),
                ),
              ],
              
              // AI Analysis button
              if (report.imageUrl != null && report.imageUrl!.isNotEmpty) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      AiAnalysisModel? aiAnalysis;
                      if (report.additionalData != null) {
                        try {
                          aiAnalysis = AiAnalysisModel.fromJson(report.additionalData!);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AiAnalysisScreen(analysis: aiAnalysis!),
                            ),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error loading AI analysis: $e')),
                          );
                        }
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('No AI analysis data available')),
                        );
                      }
                    },
                    icon: const Icon(Icons.analytics),
                    label: const Text('View AI Analysis'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade700,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
              
              // Status indicator
              if (report.diagnosis == 'Awaiting doctor review') ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.pending, color: Colors.orange),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'This report is pending review by your doctor',
                          style: TextStyle(color: Colors.orange),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 4),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
