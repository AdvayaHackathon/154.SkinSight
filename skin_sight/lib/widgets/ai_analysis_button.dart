import 'dart:io';
import 'package:flutter/material.dart';
import '../models/ai_analysis_model.dart';
import '../screens/common/ai_analysis_screen.dart';
import '../services/api_service.dart';

class AiAnalysisButton extends StatefulWidget {
  final File? imageFile;
  final String? imageUrl;
  final String bodyRegion;
  final Function(AiAnalysisModel)? onAnalysisComplete;
  final AiAnalysisModel? existingAnalysis;

  const AiAnalysisButton({
    Key? key,
    this.imageFile,
    this.imageUrl,
    required this.bodyRegion,
    this.onAnalysisComplete,
    this.existingAnalysis,
  }) : super(key: key);

  @override
  State<AiAnalysisButton> createState() => _AiAnalysisButtonState();
}

class _AiAnalysisButtonState extends State<AiAnalysisButton> {
  bool _isAnalyzing = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    // If we already have analysis results, show the "View Analysis" button
    if (widget.existingAnalysis != null) {
      return ElevatedButton.icon(
        icon: const Icon(Icons.analytics),
        label: const Text('View AI Analysis'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AiAnalysisScreen(
                analysis: widget.existingAnalysis!,
              ),
            ),
          );
        },
      );
    }

    // If no image is provided, don't show the button
    if (widget.imageFile == null && widget.imageUrl == null) {
      return const SizedBox.shrink();
    }

    // Show the "Analyze with AI" button
    return ElevatedButton.icon(
      icon: _isAnalyzing 
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
          : const Icon(Icons.analytics),
      label: Text(_isAnalyzing ? 'Analyzing...' : 'Analyze with AI'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      onPressed: _isAnalyzing ? null : _analyzeImage,
    );
  }

  Future<void> _analyzeImage() async {
    if (widget.imageFile == null && widget.imageUrl == null) {
      setState(() {
        _errorMessage = 'No image available for analysis';
      });
      _showErrorSnackBar();
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _errorMessage = null;
    });

    try {
      // Show analyzing indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Analyzing image with AI...'),
          duration: Duration(seconds: 2),
        ),
      );
      
      // Call API service to analyze the image
      Map<String, dynamic> result;
      
      if (widget.imageFile != null) {
        // Use local file
        result = await ApiService.analyzeSkinImage(
          widget.imageFile!,
          widget.bodyRegion,
        );
      } else if (widget.imageUrl != null && widget.imageUrl!.isNotEmpty) {
        // Use remote URL
        result = await ApiService.analyzeSkinImageFromUrl(
          widget.imageUrl!,
          widget.bodyRegion,
        );
      } else {
        throw Exception('No image file or URL provided');
      }
      
      // Convert result to AiAnalysisModel
      final analysis = AiAnalysisModel.fromJson(result);
      
      setState(() {
        _isAnalyzing = false;
      });
      
      // Call the callback if provided
      if (widget.onAnalysisComplete != null) {
        widget.onAnalysisComplete!(analysis);
      }
      
      // Navigate to the analysis screen
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AiAnalysisScreen(analysis: analysis),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error analyzing image: ${e.toString()}';
        _isAnalyzing = false;
      });
      _showErrorSnackBar();
    }
  }
  
  void _showErrorSnackBar() {
    if (_errorMessage != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_errorMessage!),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
