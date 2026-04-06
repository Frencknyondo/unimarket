import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_compress/video_compress.dart';

import '../models/user_model.dart';
import '../services/listing_service.dart';

class CreateListingPage extends StatefulWidget {
  final User user;

  const CreateListingPage({super.key, required this.user});

  @override
  State<CreateListingPage> createState() => _CreateListingPageState();
}

class _CreateListingPageState extends State<CreateListingPage> {
  final _listingService = ListingService();
  final _picker = ImagePicker();
  final _titleController = TextEditingController();
  final _priceController = TextEditingController();
  final _specificLocationController = TextEditingController();
  final _descriptionController = TextEditingController();

  final List<_SelectedImage> _selectedImages = [];
  XFile? _selectedVideo;
  bool _isSubmitting = false;

  String? _selectedCategory;
  String _selectedLocation = 'Main campus';

  final List<String> _categories = const ['Stationary', 'Clothing', 'Food'];

  final List<String> _locations = const [
    'Main campus',
    'Mabibo stend',
    'Mabibo hostel',
  ];

  String get _specificLocationLabel =>
      'Specific location at $_selectedLocation';

  bool get _isFormComplete {
    return _selectedImages.isNotEmpty &&
        _titleController.text.trim().isNotEmpty &&
        _priceController.text.trim().isNotEmpty &&
        _selectedCategory != null &&
        _selectedLocation.trim().isNotEmpty &&
        _specificLocationController.text.trim().isNotEmpty &&
        _descriptionController.text.trim().isNotEmpty;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _specificLocationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration(String hintText, {Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 15),
      filled: true,
      fillColor: const Color(0xFFF7F7F7),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF4A3DE0), width: 1.2),
      ),
      suffixIcon: suffixIcon,
    );
  }

  Future<void> _pickImages() async {
    List<XFile> pickedFiles;
    try {
      pickedFiles = _isDesktopPlatform
          ? await _picker.pickMultiImage()
          : await _picker.pickMultiImage(imageQuality: 100);
    } catch (_) {
      if (!mounted) return;
      await _showStatusCard(
        title: 'Photo upload failed',
        message: 'We could not prepare the selected photos. Try again.',
      );
      return;
    }

    if (pickedFiles.isEmpty) return;

    final availableSlots = 3 - _selectedImages.length;
    if (availableSlots <= 0) {
      await _showStatusCard(
        title: 'Photo limit reached',
        message: 'You can upload up to 3 photos only.',
      );
      return;
    }

    final filesToUse = pickedFiles.take(availableSlots).toList();
    if (filesToUse.length < pickedFiles.length && mounted) {
      await _showStatusCard(
        title: 'Only 3 photos allowed',
        message: 'Extra photos were skipped because the limit is 3.',
      );
    }

    _showLoadingCard('Preparing photos...');
    try {
      final selectedImages = <_SelectedImage>[];
      for (final file in filesToUse) {
        selectedImages.add(
          _SelectedImage(
            file: file,
            previewBytes: await file.readAsBytes(),
          ),
        );
      }
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      setState(() {
        _selectedImages.addAll(selectedImages);
      });
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      await _showStatusCard(
        title: 'Photo upload failed',
        message: 'We could not read the selected images. Try different photos.',
      );
    }
  }

  Future<void> _pickVideo() async {
    final pickedFile = await _picker.pickVideo(source: ImageSource.gallery);
    if (pickedFile == null) return;

    _showLoadingCard(kIsWeb ? 'Preparing video...' : 'Compressing video...');
    try {
      final preparedVideo = kIsWeb
          ? pickedFile
          : await _compressVideo(File(pickedFile.path));
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      setState(() {
        _selectedVideo = preparedVideo;
      });
    } catch (_) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      await _showStatusCard(
        title: 'Video upload failed',
        message: 'We could not prepare the selected video. Try another file.',
      );
    }
  }

  Future<XFile> _compressVideo(File videoFile) async {
    await VideoCompress.deleteAllCache();
    final info = await VideoCompress.compressVideo(
      videoFile.path,
      quality: VideoQuality.MediumQuality,
      deleteOrigin: false,
      includeAudio: true,
    );

    final compressedPath = info?.file?.path;
    if (compressedPath == null) {
      throw Exception('Video compression failed');
    }

    final compressedFile = File(compressedPath);
    final sizeInMb = await compressedFile.length() / (1024 * 1024);
    if (sizeInMb > 5) {
      throw Exception('Compressed video is larger than 5MB');
    }

    return XFile(compressedPath);
  }

  Future<void> _submitListing() async {
    if (!_isFormComplete) {
      await _showStatusCard(
        title: 'Incomplete form',
        message: 'Please fill all required fields and add at least one photo.',
      );
      return;
    }

    final price = double.tryParse(_priceController.text.trim());
    if (price == null) {
      await _showStatusCard(
        title: 'Invalid price',
        message: 'Please enter a valid amount in Tsh.',
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });
    _showLoadingCard('Processing listing...');

    final result = await _listingService.createListing(
      seller: widget.user,
      title: _titleController.text,
      price: price,
      category: _selectedCategory!,
      location: _selectedLocation,
      specificLocation: _specificLocationController.text,
      description: _descriptionController.text,
      images: _selectedImages.map((image) => image.file).toList(),
      video: _selectedVideo,
    );

    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop();
    setState(() {
      _isSubmitting = false;
    });

    await _showStatusCard(
      title: result['success'] ? 'Success' : 'Upload failed',
      message: result['message'] as String,
    );

    if (result['success'] == true && mounted) {
      Navigator.of(context).pop();
    }
  }

  void _showLoadingCard(String message) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return PopScope(
          canPop: false,
          child: Dialog(
            backgroundColor: Colors.transparent,
            child: _CenterStatusCard(
              title: 'Please wait',
              message: message,
              trailing: const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2F65FF)),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showStatusCard({
    required String title,
    required String message,
  }) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: _CenterStatusCard(
            title: title,
            message: message,
            trailing: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2F65FF),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('OK'),
              ),
            ),
          ),
        );
      },
    );
  }

  String _fileName(XFile file) {
    final normalizedPath = file.path.replaceAll('\\', '/');
    return normalizedPath.split('/').last;
  }

  bool get _isDesktopPlatform =>
      !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);

  @override
  Widget build(BuildContext context) {
    final buttonColor = _isFormComplete
        ? const Color(0xFF2F65FF)
        : const Color(0xFFBDBDBD);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        titleSpacing: 0,
        title: const Text(
          'Create Listing',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Media',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _MediaPickerCard(
                      title: 'Photos',
                      actionLabel: _selectedImages.isEmpty
                          ? 'Add Photos'
                          : 'Edit Photos',
                      countLabel: '${_selectedImages.length}/3',
                      icon: Icons.add_rounded,
                      preview: _selectedImages.isEmpty
                          ? null
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.memory(
                                _selectedImages.first.previewBytes,
                                height: 42,
                                width: 42,
                                fit: BoxFit.cover,
                              ),
                            ),
                      onTap: _pickImages,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _MediaPickerCard(
                      title: 'Video',
                      actionLabel: _selectedVideo == null
                          ? 'Add Video'
                          : 'Change Video',
                      countLabel: '1',
                      icon: Icons.videocam_rounded,
                      preview: _selectedVideo == null
                          ? null
                          : Text(
                              _fileName(_selectedVideo!),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                      onTap: _pickVideo,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'Details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              const _FieldLabel('Item Title', isRequired: true),
              const SizedBox(height: 8),
              TextField(
                controller: _titleController,
                onChanged: (_) => setState(() {}),
                decoration: _inputDecoration('What are you selling?'),
              ),
              const SizedBox(height: 16),
              const _FieldLabel('Price', isRequired: true),
              const SizedBox(height: 8),
              TextField(
                controller: _priceController,
                onChanged: (_) => setState(() {}),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: _inputDecoration('0.00').copyWith(
                  prefixIcon: const Padding(
                    padding: EdgeInsets.fromLTRB(14, 14, 8, 14),
                    child: Text(
                      'Tsh',
                      style: TextStyle(
                        color: Color(0xFF2F65FF),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  prefixIconConstraints: const BoxConstraints(
                    minWidth: 0,
                    minHeight: 0,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const _FieldLabel('Category', isRequired: true),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: _inputDecoration('Select Category'),
                icon: const Icon(Icons.keyboard_arrow_down_rounded),
                items: _categories
                    .map(
                      (category) => DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              const _FieldLabel('Location'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _selectedLocation,
                decoration: _inputDecoration('Select Location'),
                icon: const Icon(Icons.keyboard_arrow_down_rounded),
                items: _locations
                    .map(
                      (location) => DropdownMenuItem(
                        value: location,
                        child: Text(location),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _selectedLocation = value;
                  });
                },
              ),
              const SizedBox(height: 10),
              Text(
                _specificLocationLabel,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _specificLocationController,
                onChanged: (_) => setState(() {}),
                decoration: _inputDecoration('Enter the exact place'),
              ),
              const SizedBox(height: 16),
              const _FieldLabel('Description'),
              const SizedBox(height: 8),
              TextField(
                controller: _descriptionController,
                maxLines: 4,
                maxLength: 300,
                onChanged: (_) => setState(() {}),
                decoration: _inputDecoration('Describe your item...').copyWith(
                  counterText: '${_descriptionController.text.length}/300',
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitListing,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: buttonColor,
                    disabledBackgroundColor: buttonColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'List Item for Sale',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectedImage {
  final XFile file;
  final Uint8List previewBytes;

  const _SelectedImage({
    required this.file,
    required this.previewBytes,
  });
}

class _MediaPickerCard extends StatelessWidget {
  final String title;
  final String actionLabel;
  final String countLabel;
  final IconData icon;
  final Widget? preview;
  final VoidCallback onTap;

  const _MediaPickerCard({
    required this.title,
    required this.actionLabel,
    required this.countLabel,
    required this.icon,
    required this.onTap,
    this.preview,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Ink(
            height: 146,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFDCDFF1)),
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (preview == null)
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF3B82F6),
                            width: 1.6,
                          ),
                        ),
                        child: Icon(
                          icon,
                          size: 32,
                          color: const Color(0xFF3B82F6),
                        ),
                      )
                    else
                      preview!,
                    const SizedBox(height: 8),
                    Text(
                      actionLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF3B82F6),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      countLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFFB0B0B0),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;
  final bool isRequired;

  const _FieldLabel(this.label, {this.isRequired = false});

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: Colors.black87,
        ),
        children: [
          if (isRequired)
            const TextSpan(
              text: ' *',
              style: TextStyle(color: Colors.redAccent),
            ),
        ],
      ),
    );
  }
}

class _CenterStatusCard extends StatelessWidget {
  final String title;
  final String message;
  final Widget trailing;

  const _CenterStatusCard({
    required this.title,
    required this.message,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            message,
            style: const TextStyle(
              fontSize: 15,
              height: 1.5,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 18),
          trailing,
        ],
      ),
    );
  }
}
