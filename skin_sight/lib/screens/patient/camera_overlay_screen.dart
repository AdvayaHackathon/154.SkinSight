import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path/path.dart' show join;
import 'package:path_provider/path_provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/storage_service.dart';
import '../../utils/permission_utils.dart';

class CameraOverlayScreen extends StatefulWidget {
  final String bodyLocation;
  final XFile? previousImage;
  
  const CameraOverlayScreen({
    super.key, 
    required this.bodyLocation,
    this.previousImage,
  });

  @override
  State<CameraOverlayScreen> createState() => _CameraOverlayScreenState();
}

class _CameraOverlayScreenState extends State<CameraOverlayScreen> with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  bool _isProcessing = false;
  
  // Overlay properties
  double _overlayOpacity = 0.3;
  XFile? _overlayImage;
  Color _overlayTint = Colors.blue.withOpacity(0.1); // Slight blue tint to distinguish overlay
  bool _showGrid = true; // Show alignment grid on overlay
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setOverlayImage();
    _setupCamera();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // App lifecycle state has changed, check if camera needs to be reopened
    if (_controller == null || !_controller!.value.isInitialized) {
      return;
    }
    
    if (state == AppLifecycleState.inactive) {
      // App is in background or being closed, dispose camera
      _controller?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      // App is in foreground again, reinitialize camera
      _setupCamera();
    }
  }
  
  Future<void> _setupCamera() async {
    final hasPermission = await PermissionUtils.requestCameraPermission(context);
    
    if (hasPermission) {
      _initializeCamera();
    } else {
      // Handle no permission case - navigator pop is handled in PermissionUtils
    }
  }
  
  void _setOverlayImage() {
    setState(() {
      _overlayImage = widget.previousImage;
    });
  }
  
  Future<void> _initializeCamera() async {
    try {
      debugPrint('Starting camera initialization...');
      
      // Add timeout to availableCameras call
      _cameras = await availableCameras().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint('Camera detection timed out');
          throw Exception('Camera detection timed out. Please restart the app and try again.');
        },
      );
      
      if (_cameras == null || _cameras!.isEmpty) {
        debugPrint('No cameras found on device');
        // Show error to user instead of silent failure
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No cameras found on device')),
          );
          // Add a way to go back if no cameras
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) Navigator.of(context).pop();
          });
        }
        return;
      }
      
      debugPrint('Found ${_cameras!.length} cameras: ${_cameras!.map((c) => c.name).join(', ')}');
      
      final CameraDescription rearCamera = _cameras!.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras!.first,
      );
      
      debugPrint('Selected camera: ${rearCamera.name}');
      
      // Clean up any existing controller
      await _controller?.dispose();
      
      _controller = CameraController(
        rearCamera,
        ResolutionPreset.medium, // Use medium instead of high for better performance
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      
      debugPrint('Camera controller created, initializing...');
      
      // Add timeout to controller initialization
      await _controller!.initialize().timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          debugPrint('Camera initialization timed out');
          throw Exception('Camera initialization timed out. Please restart the app and try again.');
        },
      );
      
      // Extra check to verify controller is actually initialized
      if (!_controller!.value.isInitialized) {
        throw Exception('Camera failed to initialize properly');
      }
      
      debugPrint('Camera controller initialized successfully');
      
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Error initializing camera: $e');
      if (mounted) {
        setState(() {
          // Show error UI instead of infinite loading
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Camera error: ${e.toString()}'),
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'Close',
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ),
          );
          // Add a way to go back if camera fails
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) Navigator.of(context).pop();
          });
        });
      }
    }
  }
  
  @override
  void dispose() {
    // Properly dispose of the camera controller
    if (_controller != null) {
      try {
        debugPrint('Disposing camera controller...');
        _controller!.dispose();
        debugPrint('Camera controller disposed successfully');
      } catch (e) {
        debugPrint('Error disposing camera controller: $e');
      }
    }
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  
  Future<void> _takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized || _isProcessing) {
      return;
    }
    
    setState(() {
      _isProcessing = true;
    });
    
    try {
      final XFile image = await _controller!.takePicture();
      
      // Save the image locally
      await StorageService.saveLocalImage(
        image,
        widget.bodyLocation,
      );
      
      if (mounted) {
        Navigator.pop(context, image);
      }
    } catch (e) {
      debugPrint('Error taking picture: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error taking picture: ${e.toString()}')),
        );
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (!_isInitialized || _controller == null || !_controller!.value.isInitialized) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text('Loading Camera...', style: TextStyle(color: Colors.white)),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                color: Color(0xFF0A8754),
              ),
              const SizedBox(height: 20),
              Text(
                _getLoadingStatusMessage(),
                style: const TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: LinearProgressIndicator(
                  backgroundColor: Colors.grey[800],
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0A8754)),
                ),
              ),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[800],
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 20),
                  ElevatedButton(
                    onPressed: _retryInitialization,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0A8754),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera preview
          Center(
            child: _controller!.value.isInitialized
                ? CameraPreview(_controller!)
                : const Center(child: Text('Camera initializing...', style: TextStyle(color: Colors.white))),
          ),
          
          // Overlay image
          if (_overlayImage != null)
            Positioned.fill(
              child: Stack(
                children: [
                  // Image with tint
                  Opacity(
                    opacity: _overlayOpacity,
                    child: ColorFiltered(
                      colorFilter: ColorFilter.mode(
                        _overlayTint,
                        BlendMode.srcATop,
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: const Color(0xFF0A8754).withOpacity(0.8),
                            width: 2.0,
                          ),
                        ),
                        child: Image.file(
                          File(_overlayImage!.path),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  
                  // Optional grid overlay for alignment
                  if (_showGrid)
                    Opacity(
                      opacity: _overlayOpacity * 0.6,
                      child: CustomPaint(
                        painter: GridPainter(
                          lineColor: Colors.white.withOpacity(0.5),
                          lineWidth: 1,
                          gridSize: 3, // 3x3 grid
                        ),
                        size: Size.infinite,
                      ),
                    ),
                ],
              ),
            ),
          
          // Camera controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              color: Colors.black.withOpacity(0.5),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Opacity slider
                  if (_overlayImage != null)
                    Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.opacity, color: Colors.white),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Slider(
                                value: _overlayOpacity,
                                min: 0.0,
                                max: 1.0, // Increased from 0.7 to 1.0 (100%)
                                divisions: 10, // More granular control
                                activeColor: const Color(0xFF0A8754),
                                inactiveColor: Colors.white24,
                                label: 'Overlay: ${(_overlayOpacity * 100).round()}%',
                                onChanged: (value) {
                                  setState(() {
                                    _overlayOpacity = value;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  
                  // Camera buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Back button
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white, size: 32),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      
                      // Capture button
                      GestureDetector(
                        onTap: _isProcessing ? null : _takePicture,
                        child: Container(
                          height: 70,
                          width: 70,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            color: _isProcessing ? Colors.grey : const Color(0xFF0A8754),
                          ),
                          child: _isProcessing
                              ? const Center(
                                  child: SizedBox(
                                    width: 30,
                                    height: 30,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  ),
                                )
                              : const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 32,
                                ),
                        ),
                      ),
                      
                      // Toggle overlay button
                      IconButton(
                        icon: Icon(
                          _overlayImage != null && _overlayOpacity > 0
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: Colors.white,
                          size: 32,
                        ),
                        onPressed: () {
                          if (_overlayImage != null) {
                            setState(() {
                              _overlayOpacity = _overlayOpacity > 0 ? 0 : 0.3;
                            });
                          }
                        },
                      ),
                      
                      // Toggle grid button
                      if (_overlayImage != null)
                        IconButton(
                          icon: Icon(
                            _showGrid ? Icons.grid_on : Icons.grid_off,
                            color: Colors.white,
                            size: 28,
                          ),
                          onPressed: () {
                            setState(() {
                              _showGrid = !_showGrid;
                            });
                          },
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          // Guide text
          Positioned(
            top: 50,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              color: Colors.black54,
              child: const Text(
                'Align with previous photo using the overlay',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to provide appropriate loading status
  String _getLoadingStatusMessage() {
    if (_cameras == null) {
      return 'Searching for cameras...\nPlease ensure camera permissions are granted';
    } else if (_cameras!.isEmpty) {
      return 'No cameras found on device';
    } else if (_controller == null) {
      return 'Preparing camera...';
    } else if (!_controller!.value.isInitialized) {
      return 'Initializing camera...\nThis may take a moment';
    } else {
      return 'Camera ready!';
    }
  }
  
  // Method to retry camera initialization
  void _retryInitialization() {
    setState(() {
      _isInitialized = false;
    });
    _setupCamera();
  }
}

// Grid painter for alignment guides
class GridPainter extends CustomPainter {
  final Color lineColor;
  final double lineWidth;
  final int gridSize;

  GridPainter({
    required this.lineColor,
    required this.lineWidth,
    required this.gridSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = lineWidth
      ..style = PaintingStyle.stroke;

    // Draw vertical lines
    final verticalSpacing = size.width / gridSize;
    for (int i = 1; i < gridSize; i++) {
      final x = verticalSpacing * i;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Draw horizontal lines
    final horizontalSpacing = size.height / gridSize;
    for (int i = 1; i < gridSize; i++) {
      final y = horizontalSpacing * i;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    
    // Draw center target/crosshair
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final crosshairSize = size.width * 0.05;
    
    // Horizontal crosshair line
    canvas.drawLine(
      Offset(centerX - crosshairSize, centerY),
      Offset(centerX + crosshairSize, centerY),
      paint..color = Colors.red.withOpacity(0.8)..strokeWidth = lineWidth * 1.5,
    );
    
    // Vertical crosshair line
    canvas.drawLine(
      Offset(centerX, centerY - crosshairSize),
      Offset(centerX, centerY + crosshairSize),
      paint,
    );
    
    // Circle at center
    canvas.drawCircle(
      Offset(centerX, centerY),
      crosshairSize / 2,
      paint..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
} 