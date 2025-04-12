import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/user_model.dart';
import '../../models/report_model.dart';
import '../../services/report_service.dart';
import '../../services/storage_service.dart';
import '../../models/ai_analysis_model.dart';
import '../../widgets/ai_analysis_button.dart';

class ReportManagementScreen extends StatefulWidget {
  final UserModel user; // The current user (patient or doctor)
  final UserModel? patient; // The patient (null if user is the patient)
  final ReportModel? reportToEdit; // Report to edit if in edit mode
  final bool isViewOnly; // Whether this is view-only mode

  const ReportManagementScreen({
    Key? key,
    required this.user,
    this.patient,
    this.reportToEdit,
    this.isViewOnly = false,
  }) : super(key: key);

  @override
  State<ReportManagementScreen> createState() => _ReportManagementScreenState();
}

class _ReportManagementScreenState extends State<ReportManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers for form inputs
  final TextEditingController _diagnosisController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  
  // Form state
  String _selectedSeverity = 'Mild';
  String _selectedBodyRegion = 'Trunk';
  String? _imageUrl;
  XFile? _selectedImage;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isEditing = false;
  
  // Lists for dropdown options
  final List<String> _severityLevels = ['Mild', 'Moderate', 'Severe', 'Very Severe'];
  final List<String> _bodyRegions = ['Trunk', 'Arms', 'Legs', 'Head'];

  // Computed properties
  bool get isDoctor => widget.user.userType == 'doctor';
  bool get isPatient => widget.user.userType == 'patient';
  UserModel get patient => widget.patient ?? widget.user;

  @override
  void initState() {
    super.initState();
    _initializeFormData();
  }

  void _initializeFormData() {
    // Check if editing an existing report
    if (widget.reportToEdit != null) {
      _isEditing = true;
      _selectedSeverity = widget.reportToEdit!.severity;
      _diagnosisController.text = widget.reportToEdit!.diagnosis ?? '';
      _notesController.text = widget.reportToEdit!.notes ?? '';
      _imageUrl = widget.reportToEdit!.imageUrl;
      
      // Try to extract body region from AI analysis if available
      if (widget.reportToEdit!.additionalData != null) {
        try {
          final aiAnalysis = AiAnalysisModel.fromJson(widget.reportToEdit!.additionalData!);
          final bodyRegion = aiAnalysis.pasiAssessment.bodyRegion;
          if (bodyRegion.isNotEmpty) {
            _selectedBodyRegion = bodyRegion.substring(0, 1).toUpperCase() + bodyRegion.substring(1);
          }
        } catch (e) {
          // Ignore errors in parsing AI data
        }
      }
    }
  }

  @override
  void dispose() {
    _diagnosisController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await StorageService.pickImage(source: source);
      if (image != null) {
        setState(() {
          _selectedImage = image;
          _imageUrl = null; // Clear previous URL since we have a new image
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error selecting image: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _submitReport() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        // For patients, ensure diagnosis is set appropriately
        if (isPatient && _diagnosisController.text.trim().isEmpty) {
          _diagnosisController.text = 'Awaiting doctor review';
        }
        
        // For doctors, validate required fields
        if (isDoctor && _diagnosisController.text.trim().isEmpty) {
          throw Exception('Diagnosis is required');
        }
        
        // Upload image if selected
        if (_selectedImage != null) {
          // Show uploading indicator
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Uploading image...'),
                duration: Duration(seconds: 1),
              ),
            );
          }
          
          // Upload to Firebase Storage
          _imageUrl = await StorageService.uploadImage(
            _selectedImage!, 
            'psoriasis_images/${patient.uid}'
          );
          
          if (_imageUrl == null) {
            throw Exception('Failed to upload image. Please try again.');
          }
        }
        
        // Validate image
        if (_imageUrl == null && !_isEditing) {
          if (isPatient) {
            throw Exception('Please upload an image of your skin condition.');
          } else {
            // For doctors, we'll just show a warning but continue
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('No image was uploaded. This is recommended but not required.'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }

        ReportModel report;
        
        if (_isEditing && widget.reportToEdit != null) {
          // Update existing report
          report = await ReportService.updateReport(
            reportId: widget.reportToEdit!.id,
            severity: _selectedSeverity,
            diagnosis: _diagnosisController.text.trim(),
            imageUrl: _imageUrl ?? widget.reportToEdit!.imageUrl,
            notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
          );
        } else {
          // Add new report
          if (isDoctor) {
            // Doctor adding report for patient
            report = await ReportService.addReport(
              patientId: patient.uid,
              doctorId: widget.user.uid,
              pid: patient.pid!,
              severity: _selectedSeverity,
              diagnosis: _diagnosisController.text.trim(),
              imageUrl: _imageUrl,
              notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
            );
          } else {
            // Patient adding own report
            report = await ReportService.addPatientReport(
              patientId: widget.user.uid,
              severity: _selectedSeverity,
              bodyRegion: _selectedBodyRegion.toLowerCase(),
              imageUrl: _imageUrl!,
              notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
            );
          }
        }

        if (mounted) {
          // Check if report was successfully created/updated
          if (report.id.isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(_isEditing ? 'Report updated successfully' : 'Report added successfully'),
                backgroundColor: Colors.green,
              ),
            );
            
            // Return true to indicate success
            Navigator.pop(context, true);
          } else {
            throw Exception(_isEditing ? 'Failed to update report' : 'Failed to create report');
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = e.toString();
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
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
        title: Text(_getAppBarTitle()),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isDoctor && widget.patient != null) ...[
                      _buildPatientInfoCard(),
                      const SizedBox(height: 24),
                    ],
                    
                    // Image Upload Section
                    _buildSectionHeader('Skin Photo'),
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            if (!widget.isViewOnly) ...[
                              Text(
                                'Upload a clear photo of the affected skin area',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                            
                            // Image Preview
                            Container(
                              height: 200,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: _getImageWidget(),
                            ),
                            
                            if (!widget.isViewOnly) ...[
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Camera Button
                                  ElevatedButton.icon(
                                    onPressed: () => _pickImage(ImageSource.camera),
                                    icon: const Icon(Icons.camera_alt),
                                    label: const Text('Camera'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  // Gallery Button
                                  ElevatedButton.icon(
                                    onPressed: () => _pickImage(ImageSource.gallery),
                                    icon: const Icon(Icons.photo_library),
                                    label: const Text('Gallery'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Theme.of(context).primaryColor,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Severity Selection
                    _buildSectionHeader('Severity Assessment'),
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
                            DropdownButtonFormField<String>(
                              decoration: InputDecoration(
                                labelText: 'Severity Level',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                enabled: !widget.isViewOnly,
                              ),
                              value: _selectedSeverity,
                              items: _severityLevels.map((severity) {
                                return DropdownMenuItem(
                                  value: severity,
                                  child: Text(severity),
                                );
                              }).toList(),
                              onChanged: widget.isViewOnly 
                                  ? null 
                                  : (value) {
                                      if (value != null) {
                                        setState(() {
                                          _selectedSeverity = value;
                                        });
                                      }
                                    },
                            ),
                            
                            if (isPatient) ...[
                              const SizedBox(height: 16),
                              DropdownButtonFormField<String>(
                                decoration: InputDecoration(
                                  labelText: 'Body Region',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  enabled: !widget.isViewOnly,
                                ),
                                value: _selectedBodyRegion,
                                items: _bodyRegions.map((region) {
                                  return DropdownMenuItem(
                                    value: region,
                                    child: Text(region),
                                  );
                                }).toList(),
                                onChanged: widget.isViewOnly 
                                    ? null 
                                    : (value) {
                                        if (value != null) {
                                          setState(() {
                                            _selectedBodyRegion = value;
                                          });
                                        }
                                      },
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Diagnosis Field (Doctor only)
                    if (isDoctor) ...[
                      _buildSectionHeader('Medical Assessment'),
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: TextFormField(
                            controller: _diagnosisController,
                            decoration: InputDecoration(
                              labelText: 'Diagnosis',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              enabled: !widget.isViewOnly,
                            ),
                            maxLines: 3,
                            validator: isDoctor ? (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter a diagnosis';
                              }
                              return null;
                            } : null,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                    
                    // Notes Field
                    _buildSectionHeader(isPatient ? 'Symptoms & Notes' : 'Additional Notes'),
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: TextFormField(
                          controller: _notesController,
                          decoration: InputDecoration(
                            labelText: isPatient 
                                ? 'Describe your symptoms and any other relevant information'
                                : 'Treatment recommendations, follow-up instructions, etc.',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            enabled: !widget.isViewOnly,
                          ),
                          maxLines: 5,
                        ),
                      ),
                    ),
                    
                    // Error Message
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 24),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline, color: Colors.red.shade700),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(color: Colors.red.shade700),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    
                    const SizedBox(height: 32),
                    
                    // Submit Button
                    if (!widget.isViewOnly)
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submitReport,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            _isEditing ? 'Update Report' : 'Submit Report',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
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

  Widget _buildPatientInfoCard() {
    return Card(
      elevation: 0,
      color: Colors.blue.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.blue.shade100),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
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
                  const Text(
                    'Patient:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.blue,
                    ),
                  ),
                  Text(
                    widget.patient!.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (widget.patient!.pid != null)
                    Text(
                      'ID: ${widget.patient!.pid}',
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
      ),
    );
  }

  Widget _getImageWidget() {
    if (_selectedImage != null) {
      // Show selected image file
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(
          File(_selectedImage!.path),
          fit: BoxFit.cover,
        ),
      );
    } else if (_imageUrl != null && _imageUrl!.isNotEmpty) {
      // Show existing image URL
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          _imageUrl!,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.broken_image, size: 40, color: Colors.grey),
                  const SizedBox(height: 8),
                  Text(
                    'Failed to load image',
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                ],
              ),
            );
          },
        ),
      );
    } else {
      // Show placeholder
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate,
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 8),
            Text(
              'No image selected',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }
  }

  String _getAppBarTitle() {
    if (widget.isViewOnly) {
      return 'View Report';
    } else if (_isEditing) {
      return 'Edit Report';
    } else {
      return isDoctor ? 'Add Medical Report' : 'Add Skin Report';
    }
  }
} 