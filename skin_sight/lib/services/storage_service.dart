import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' show join;
import 'package:path_provider/path_provider.dart';
import 'firebase_service.dart';

class StorageService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static const String _bucketUrl = 'gs://skinsight-916ed.appspot.com';
  
  // Upload image to Firebase Storage
  static Future<String?> uploadImage(XFile imageFile, String folder) async {
    try {
      // Create a unique filename using timestamp
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String fileName = 'image_$timestamp.jpg';
      final String path = '$folder/$fileName';
      
      // Create a reference to the file location
      final Reference ref = _storage.ref().child(path);
      
      // Upload the file
      UploadTask uploadTask;
      
      if (kIsWeb) {
        // Handle web platform
        uploadTask = ref.putData(await imageFile.readAsBytes());
      } else {
        // Handle mobile platforms
        uploadTask = ref.putFile(File(imageFile.path));
      }
      
      // Wait for the upload to complete
      final TaskSnapshot snapshot = await uploadTask;
      
      // Get the download URL
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }
  
  // Pick image from gallery or camera
  static Future<XFile?> pickImage({required ImageSource source}) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      return image;
    } catch (e) {
      print('Error picking image: $e');
      return null;
    }
  }
  
  // Delete image from Firebase Storage
  static Future<bool> deleteImage(String imageUrl) async {
    try {
      // Extract the path from the URL
      final Reference ref = _storage.refFromURL(imageUrl);
      
      // Delete the file
      await ref.delete();
      
      return true;
    } catch (e) {
      print('Error deleting image: $e');
      return false;
    }
  }
  
  // Save image locally for overlay functionality
  static Future<void> saveLocalImage(XFile imageFile, String bodyLocation) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final localPath = join(directory.path, 'psoriasis_images');
      
      // Create directory if it doesn't exist
      final Directory localDir = Directory(localPath);
      if (!await localDir.exists()) {
        await localDir.create(recursive: true);
      }
      
      // Create a filename based on body location
      final String fileName = '${bodyLocation.toLowerCase().replaceAll(' ', '_')}_last.jpg';
      final String filePath = join(localPath, fileName);
      
      // Copy the file to the local storage
      final File localFile = File(imageFile.path);
      await localFile.copy(filePath);
      
    } catch (e) {
      print('Error saving local image: $e');
    }
  }
  
  // Get the last image for a specific body location
  static Future<XFile?> getLastImage(String bodyLocation) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final localPath = join(directory.path, 'psoriasis_images');
      
      // Create a filename based on body location
      final String fileName = '${bodyLocation.toLowerCase().replaceAll(' ', '_')}_last.jpg';
      final String filePath = join(localPath, fileName);
      
      // Check if file exists
      final File file = File(filePath);
      if (await file.exists()) {
        return XFile(filePath);
      }
      
      return null;
    } catch (e) {
      print('Error getting last image: $e');
      return null;
    }
  }
}
