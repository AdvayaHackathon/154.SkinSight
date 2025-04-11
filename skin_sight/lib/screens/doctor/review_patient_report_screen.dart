import 'package:flutter/material.dart';
import '../../models/report_model.dart';
import '../../models/user_model.dart';
import '../../services/report_service.dart';

class ReviewPatientReportScreen extends StatefulWidget {
  final ReportModel report;
  final UserModel patient;
  
  const ReviewPatientReportScreen({
    super.key, 
    required this.report, 
    required this.patient,
  });

  @override
  State<ReviewPatientReportScreen> createState() => _ReviewPatientReportScreenState();
}

class _ReviewPatientReportScreenState extends State<ReviewPatientReportScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final TextEditingController _diagnosisController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  
  String _selectedSeverity = 'Mild';
  bool _isLoading = false;
  String? _errorMessage;

  final List<String> _severityLevels = ['Mild', 'Moderate', 'Severe', 'Very Severe'];

  @override
  void initState() {
    super.initState();
    // Initialize with existing report data
    _selectedSeverity = widget.report.severity;
    _diagnosisController.text = widget.report.diagnosis ?? '';
    _notesController.text = widget.report.notes ?? '';
  }

  @override
  void dispose() {
    _diagnosisController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _updateReport() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        // Update in Firestore using the new method signature
        await ReportService.updateReport(
          reportId: widget.report.id,
          severity: _selectedSeverity,
          diagnosis: _diagnosisController.text.trim(),
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Report updated successfully')),
          );
          
          // Return true to indicate success
          Navigator.pop(context, true);
        }
      } catch (e) {
        setState(() {
          _errorMessage = 'Error updating report: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Patient Report'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Patient Info Card
                Card(
                  color: Colors.blue.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.person, color: Colors.blue),
                            const SizedBox(width: 8),
                            Text(
                              widget.patient.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('Patient ID: ${widget.patient.pid}'),
                        const SizedBox(height: 4),
                        Text('Submitted on: ${_formatDate(widget.report.timestamp)}'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Patient's Image
                if (widget.report.imageUrl != null) ...[
                  const Text(
                    'Patient\'s Image:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade400),
                    ),
                    child: const Center(
                      child: Text('Image Preview'),
                      // In a real app, you'd load the image:
                      // Image.network(
                      //   widget.report.imageUrl!,
                      //   fit: BoxFit.cover,
                      // ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                
                // Patient's Notes
                if (widget.report.notes != null && widget.report.notes!.isNotEmpty) ...[
                  const Text(
                    'Patient\'s Notes:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Text(widget.report.notes!),
                  ),
                  const SizedBox(height: 16),
                ],
                
                const Divider(),
                const SizedBox(height: 8),
                
                const Text(
                  'Doctor\'s Assessment',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Severity Dropdown
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Severity Assessment',
                    border: OutlineInputBorder(),
                  ),
                  value: _selectedSeverity,
                  items: _severityLevels.map((severity) {
                    return DropdownMenuItem(
                      value: severity,
                      child: Text(severity),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedSeverity = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                
                // Diagnosis Field
                TextFormField(
                  controller: _diagnosisController,
                  decoration: const InputDecoration(
                    labelText: 'Diagnosis',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a diagnosis';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Doctor's Notes Field
                TextFormField(
                  controller: _notesController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Additional Notes',
                    hintText: 'Add treatment recommendations, follow-up instructions, etc.',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Error Message
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ),
                
                // Update Report Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _updateReport,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    backgroundColor: Colors.blue,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Save Assessment', style: TextStyle(fontSize: 16, color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
} 