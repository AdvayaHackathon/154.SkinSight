import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
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
}
