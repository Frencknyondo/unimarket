import 'dart:async';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';

import '../models/product_listing.dart';
import '../models/user_model.dart';

class ListingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  static const Duration _requestTimeout = Duration(minutes: 10);
  static const String _productsCollection = 'products';

  Future<Uint8List> _prepareImageBytes(XFile image) async {
    var bytes = await image.readAsBytes();
    if (bytes.lengthInBytes <= 600 * 1024) {
      return bytes;
    }

    var quality = 85;
    while (quality >= 35) {
      final compressed = await FlutterImageCompress.compressWithList(
        bytes,
        quality: quality,
        format: CompressFormat.jpeg,
      );

      if (compressed.lengthInBytes <= 600 * 1024 || quality == 35) {
        return compressed;
      }

      bytes = compressed;
      quality -= 10;
    }

    return bytes;
  }

  Stream<List<ProductListing>> watchListings() {
    return _firestore
        .collection(_productsCollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ProductListing.fromMap(doc.data()))
              .toList(),
        );
  }

  Future<Map<String, dynamic>> createListing({
    required User seller,
    required String title,
    required double price,
    required String category,
    required String location,
    required String specificLocation,
    required String description,
    required List<XFile> images,
    XFile? video,
  }) async {
    try {
      final listingRef = _firestore.collection(_productsCollection).doc();
      final listingId = listingRef.id;
      final basePath = 'listings/${seller.uid}/$listingId';

      final imageUrls = <String>[];
      for (var index = 0; index < images.length; index++) {
        final imageBytes = await _prepareImageBytes(images[index]);
        final imageRef = _storage.ref('$basePath/image${index + 1}.jpg');
        await imageRef
            .putData(
              imageBytes,
              SettableMetadata(contentType: 'image/jpeg'),
            )
            .timeout(_requestTimeout);
        imageUrls.add(await imageRef.getDownloadURL().timeout(_requestTimeout));
      }

      String? videoUrl;
      if (video != null) {
        final videoRef = _storage.ref('$basePath/video.mp4');
        await videoRef
            .putData(await video.readAsBytes())
            .timeout(_requestTimeout);
        videoUrl = await videoRef.getDownloadURL().timeout(_requestTimeout);
      }

      await listingRef.set({
        'productId': listingId,
        'sellerId': seller.uid,
        'sellerName': seller.fullName.trim(),
        'sellerEmail': seller.email.trim().toLowerCase(),
        'title': title.trim(),
        'price': price,
        'currency': 'Tsh',
        'category': category,
        'location': location,
        'specificLocation': specificLocation.trim(),
        'description': description.trim(),
        'images': imageUrls,
        'primaryImage': imageUrls.isNotEmpty ? imageUrls.first : null,
        'storagePath': basePath,
        'video': videoUrl,
        'createdAt': FieldValue.serverTimestamp(),
      }).timeout(_requestTimeout);

      return {
        'success': true,
        'message': 'Item listed successfully.',
        'listingId': listingId,
      };
    } on TimeoutException {
      return {
        'success': false,
        'message': 'Upload timed out. Check your connection and try again.',
      };
    } on FirebaseException catch (e) {
      return {
        'success': false,
        'message': e.message ?? 'Firebase error occurred.',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: ${e.toString()}',
      };
    }
  }
}
