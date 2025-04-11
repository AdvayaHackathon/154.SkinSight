import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../models/report_model.dart';
import '../../services/report_service.dart';
import '../../services/auth_service.dart';
import 'add_patient_report_screen.dart';

class PatientDashboard extends StatefulWidget {
  final UserModel user;
  
  const PatientDashboard({Key? key, required this.user}) : super(key: key);

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
      appBar: AppBar(
        title: const Text('My Psoriasis Reports'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadReports,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService.signOut();
              if (context.mounted) {
                Navigator.of(context).pushReplacementNamed('/welcome');
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Patient Info Card
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.green.shade100,
                        radius: 30,
                        child: const Icon(Icons.person, color: Colors.green, size: 30),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.user.name,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(widget.user.email),
                            if (widget.user.phoneNumber != null) ...[
                              const SizedBox(height: 4),
                              Text('Phone: ${widget.user.phoneNumber}'),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  if (widget.user.pid != null)
                    Text(
                      'Patient ID: ${widget.user.pid}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  if (widget.user.doctorId != null) ...[
                    const SizedBox(height: 8),
                    const Text(
                      'You are currently under a doctor\'s care',
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          
          // Reports Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Your Psoriasis Reports',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddPatientReportScreen(
                          patient: widget.user,
                        ),
                      ),
                    );
                    
                    if (result == true) {
                      _loadReports();
                    }
                  },
                  icon: const Icon(Icons.add_photo_alternate),
                  label: const Text('New Report'),
                ),
              ],
            ),
          ),
          
          // Reports List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _reports.isEmpty
                    ? _buildEmptyReportsState()
                    : _buildReportsList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddPatientReportScreen(
                patient: widget.user,
              ),
            ),
          );
          
          if (result == true) {
            _loadReports();
          }
        },
        backgroundColor: Colors.green,
        child: const Icon(Icons.add_a_photo),
        tooltip: 'Submit new skin report',
      ),
    );
  }

  Widget _buildEmptyReportsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.description_outlined,
            size: 80,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            'No Reports Yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Submit your first skin report or wait for your doctor to add reports',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddPatientReportScreen(
                    patient: widget.user,
                  ),
                ),
              );
              
              if (result == true) {
                _loadReports();
              }
            },
            icon: const Icon(Icons.add_a_photo),
            label: const Text('Submit First Report'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _reports.length,
      itemBuilder: (context, index) {
        final report = _reports[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Report #${index + 1}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _formatDate(report.timestamp),
                      style: TextStyle(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (report.imageUrl != null) ...[
                  Container(
                    height: 150,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: const Text('Image Preview'),
                      // In a real app, you'd load the image:
                      // Image.network(
                      //   report.imageUrl!,
                      //   fit: BoxFit.cover,
                      // ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                _buildInfoRow('Severity:', report.severity),
                if (report.diagnosis != null)
                  _buildInfoRow('Diagnosis:', report.diagnosis!),
                if (report.notes != null && report.notes!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Doctor\'s Notes:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(report.notes!),
                ],
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (report.diagnosis == 'Awaiting doctor review')
                      Chip(
                        label: const Text('Pending Review'),
                        backgroundColor: Colors.orange.shade100,
                        avatar: const Icon(Icons.pending, size: 16, color: Colors.orange),
                      ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () {
                        // View detailed report
                      },
                      icon: const Icon(Icons.visibility),
                      label: const Text('View Details'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
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