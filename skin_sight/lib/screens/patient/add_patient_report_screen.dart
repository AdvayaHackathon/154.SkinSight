import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/user_model.dart';
import '../../services/report_service.dart';
import '../../services/storage_service.dart';

class AddPatientReportScreen extends StatefulWidget {
  final UserModel patient;
  
  const AddPatientReportScreen({Key? key, required this.patient}) : super(key: key);

  @override
  State<AddPatientReportScreen> createState() => _AddPatientReportScreenState();
}

class _AddPatientReportScreenState extends State<AddPatientReportScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final TextEditingController _notesController = TextEditingController();
  
  String _selectedSeverity = 'Mild';
  String? _imageUrl;
  XFile? _selectedImage;
  
  bool _isLoading = false;
  String? _errorMessage;

  final List<String> _severityLevels = ['Mild', 'Moderate', 'Severe', 'Very Severe'];

  @override
  void dispose() {
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

  Future<void> _takePicture() async {
    try {
      final XFile? image = await StorageService.pickImage(source: ImageSource.camera);
      if (image != null) {
        setState(() {
          _selectedImage = image;
          _imageUrl = null; // Clear previous URL since we have a new image
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error taking picture: ${e.toString()}')),
      );
    }
  }

  Future<void> _addReport() async {
    if (_formKey.currentState!.validate()) {
      // Check if doctor is assigned
      if (widget.patient.doctorId == null) {
        setState(() {
          _errorMessage = 'You need to be assigned to a doctor before submitting reports.';
        });
        return;
      }
      
      // Check if image is uploaded
      if (_selectedImage == null && _imageUrl == null) {
        setState(() {
          _errorMessage = 'Please upload an image of your skin condition.';
        });
        return;
      }

      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        // Add additional validation
        if (widget.patient.pid == null || widget.patient.pid!.isEmpty) {
          throw Exception('Patient ID is missing. Please contact support.');
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

        final report = await ReportService.addReport(
          patientId: widget.patient.uid,
          doctorId: widget.patient.doctorId!,
          pid: widget.patient.pid!,
          severity: _selectedSeverity,
          diagnosis: 'Awaiting doctor review', // Default diagnosis until doctor reviews
          imageUrl: _imageUrl,
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        );

        if (mounted) {
          // Check if report was successfully created
          if (report.id.isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Report submitted successfully to your doctor'),
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
                : 'Error submitting report: ${e.toString()}';
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Submit Skin Report'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Patient Instruction Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.blue, size: 28),
                        const SizedBox(height: 8),
                        const Text(
                          'Submit a Skin Condition Report',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Take a clear photo of your skin condition and provide details about your symptoms. Your doctor will review your submission.',
                          textAlign: TextAlign.center,
                        ),
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
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            ElevatedButton.icon(
                                              onPressed: _pickImage,
                                              icon: const Icon(Icons.photo_library),
                                              label: const Text('Gallery'),
                                            ),
                                            const SizedBox(width: 16),
                                            ElevatedButton.icon(
                                              onPressed: _takePicture,
                                              icon: const Icon(Icons.camera_alt),
                                              label: const Text('Camera'),
                                            ),
                                          ],
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
                              const Icon(Icons.add_a_photo, size: 60, color: Colors.grey),
                              const SizedBox(height: 8),
                              const Text(
                                'Take or upload a photo of your skin condition',
                                style: TextStyle(color: Colors.grey),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: _pickImage,
                                    icon: const Icon(Icons.photo_library),
                                    label: const Text('Gallery'),
                                  ),
                                  const SizedBox(width: 16),
                                  ElevatedButton.icon(
                                    onPressed: _takePicture,
                                    icon: const Icon(Icons.camera_alt),
                                    label: const Text('Camera'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                ),
                const SizedBox(height: 16),
                
                // Severity Dropdown
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'How severe is your condition?',
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
                
                // Notes Field
                TextFormField(
                  controller: _notesController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Describe your symptoms and concerns',
                    hintText: 'Include information about pain, itching, when it started, etc.',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please describe your symptoms';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                
                // Doctor Assignment Warning
                if (widget.patient.doctorId == null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.yellow.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.yellow.shade800),
                    ),
                    child: const Text(
                      'You are not assigned to a doctor yet. Please contact a healthcare provider to be added to their patient list.',
                      style: TextStyle(color: Colors.brown),
                    ),
                  ),
                
                const SizedBox(height: 16),
                
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
                
                // Submit Report Button
                ElevatedButton(
                  onPressed: widget.patient.doctorId == null || _isLoading ? null : _addReport,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    backgroundColor: Colors.green,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Submit Report to Doctor', 
                          style: TextStyle(fontSize: 16, color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}