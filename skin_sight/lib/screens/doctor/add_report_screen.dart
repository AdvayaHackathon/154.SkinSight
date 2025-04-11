import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/user_model.dart';
import '../../services/report_service.dart';
import '../../services/storage_service.dart';

class AddReportScreen extends StatefulWidget {
  final UserModel patient;
  
  const AddReportScreen({Key? key, required this.patient}) : super(key: key);

  @override
  State<AddReportScreen> createState() => _AddReportScreenState();
}

class _AddReportScreenState extends State<AddReportScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final TextEditingController _diagnosisController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  
  String _selectedSeverity = 'Mild';
  String? _imageUrl;
  XFile? _selectedImage;
  
  bool _isLoading = false;
  String? _errorMessage;

  final List<String> _severityLevels = ['Mild', 'Moderate', 'Severe', 'Very Severe'];

  @override
  void dispose() {
    _diagnosisController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await StorageService.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _selectedImage = image;
          _imageUrl = null; // Clear previous URL since we have a new image
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error selecting image: ${e.toString()}')),
      );
    }
  }

  Future<void> _addReport() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        // Validate required fields
        if (_diagnosisController.text.trim().isEmpty) {
          throw Exception('Diagnosis is required');
        }
        
        // Upload image if selected
        if (_selectedImage != null) {
          // Show uploading indicator
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Uploading image...'),
              duration: Duration(seconds: 1),
            ),
          );
          
          // Upload to Firebase Storage
          _imageUrl = await StorageService.uploadImage(
            _selectedImage!, 
            'psoriasis_images/${widget.patient.uid}'
          );
          
          if (_imageUrl == null) {
            throw Exception('Failed to upload image. Please try again.');
          }
        }
        
        // Validate image (optional for doctor but recommended)
        if (_imageUrl == null) {
          // For doctors, we'll just show a warning but continue
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No image was uploaded. This is recommended but not required.'),
              backgroundColor: Colors.orange,
            ),
          );
        }

        final report = await ReportService.addReport(
          patientId: widget.patient.uid,
          doctorId: widget.patient.doctorId!,
          pid: widget.patient.pid!,
          severity: _selectedSeverity,
          diagnosis: _diagnosisController.text.trim(),
          imageUrl: _imageUrl,
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        );

        if (mounted) {
          // Check if report was successfully created
          if (report.id.isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Report added successfully'),
                backgroundColor: Colors.green,
              ),
            );
            
            // Return true to indicate success
            Navigator.pop(context, true);
          } else {
            throw Exception('Failed to create report. Please try again.');
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _errorMessage = e.toString().contains('Exception:') 
                ? e.toString().split('Exception:')[1].trim() 
                : 'Error adding report: ${e.toString()}';
            _isLoading = false;
          });
          
          // Show error in SnackBar for better visibility
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_errorMessage!),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Psoriasis Report'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Patient Info
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Patient Information',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildInfoRow('Name:', widget.patient.name),
                        _buildInfoRow('PID:', widget.patient.pid!),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Image Upload
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _selectedImage != null
                      ? Stack(
                          fit: StackFit.expand,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(7),
                              child: Image.file(
                                File(_selectedImage!.path),
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.image, size: 60, color: Colors.grey),
                                        const SizedBox(height: 8),
                                        const Text('Image Preview Not Available'),
                                        const SizedBox(height: 16),
                                        ElevatedButton.icon(
                                          onPressed: _pickImage,
                                          icon: const Icon(Icons.upload),
                                          label: const Text('Change Image'),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                            Positioned(
                              right: 8,
                              top: 8,
                              child: CircleAvatar(
                                backgroundColor: Colors.black54,
                                radius: 16,
                                child: IconButton(
                                  padding: EdgeInsets.zero,
                                  icon: const Icon(Icons.close, size: 16, color: Colors.white),
                                  onPressed: () {
                                    setState(() {
                                      _selectedImage = null;
                                    });
                                  },
                                ),
                              ),
                            ),
                          ],
                        )
                      : Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.image, size: 60, color: Colors.grey),
                              const SizedBox(height: 8),
                              Text(
                                _imageUrl == null ? 'No Image Selected' : 'Image Uploaded',
                                style: const TextStyle(color: Colors.grey),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: _pickImage,
                                icon: const Icon(Icons.upload),
                                label: const Text('Upload Image'),
                              ),
                            ],
                          ),
                        ),
                ),
                const SizedBox(height: 16),
                
                // Severity Dropdown
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Severity',
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
                
                // Notes Field
                TextFormField(
                  controller: _notesController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Notes (Optional)',
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
                
                // Add Report Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _addReport,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Add Report', style: TextStyle(fontSize: 16)),
                ),
              ],
            ),
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
}