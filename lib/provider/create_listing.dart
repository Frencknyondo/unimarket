import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_model.dart';

class CreateListingPage extends StatefulWidget {
  final User user;

  const CreateListingPage({super.key, required this.user});

  @override
  State<CreateListingPage> createState() => _CreateListingPageState();
}

class _CreateListingPageState extends State<CreateListingPage> {
  final _titleController = TextEditingController();
  final _priceController = TextEditingController();
  final _specificLocationController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _videoUrlController = TextEditingController();

  final List<String> _imageUrls = [];
  String? _videoUrl;
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
    return _titleController.text.trim().isNotEmpty &&
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
    _imageUrlController.dispose();
    _videoUrlController.dispose();
    super.dispose();
  }

  bool isValidUrl(String url) {
    return Uri.tryParse(url)?.hasAbsolutePath ?? false;
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

  void _addImageUrl() {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Enter Image URL"),
          content: TextField(
            controller: _imageUrlController,
            decoration: const InputDecoration(hintText: "https://example.com/image.jpg"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                if (_imageUrls.length >= 3) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("You can add up to 3 image URLs.")),
                  );
                  return;
                }

                final url = _imageUrlController.text.trim();
                if (url.isNotEmpty && isValidUrl(url)) {
                  setState(() {
                    _imageUrls.add(url);
                  });
                  _imageUrlController.clear();
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Please enter a valid URL")),
                  );
                }
              },
              child: const Text("Add"),
            ),
          ],
        );
      },
    );
  }

  void _addVideoUrl() {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Enter Video URL"),
          content: TextField(
            controller: _videoUrlController,
            decoration: const InputDecoration(hintText: "https://example.com/video.mp4"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                final url = _videoUrlController.text.trim();
                if (url.isEmpty || isValidUrl(url)) {
                  setState(() {
                    _videoUrl = url.isEmpty ? null : url;
                  });
                  _videoUrlController.clear();
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Please enter a valid URL")),
                  );
                }
              },
              child: const Text("Add"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _submitListing() async {
    if (!_isFormComplete) {
      await _showStatusCard(
        title: 'Incomplete form',
        message: 'Please fill all required fields.',
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

    // Validate URLs
    for (final url in _imageUrls) {
      if (!isValidUrl(url)) {
        await _showStatusCard(
          title: 'Invalid Image URL',
          message: 'One or more image URLs are invalid.',
        );
        return;
      }
    }
    if (_videoUrl != null && !isValidUrl(_videoUrl!)) {
      await _showStatusCard(
        title: 'Invalid Video URL',
        message: 'The video URL is invalid.',
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });
    _showLoadingCard('Creating listing...');

    try {
      await FirebaseFirestore.instance.collection('listings').add({
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'price': price,
        'currency': 'Tsh',
        'category': _selectedCategory,
        'location': _selectedLocation,
        'specificLocation': _specificLocationController.text.trim(),
        'imageUrls': _imageUrls,
        'videoUrl': _videoUrl,
        'sellerId': widget.user.uid,
        'sellerName': widget.user.fullName,
        'sellerEmail': widget.user.email,
        'userId': widget.user.uid,
        'createdAt': Timestamp.now(),
      });

      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      setState(() {
        _isSubmitting = false;
      });

      await _showStatusCard(
        title: 'Success',
        message: 'Your listing has been created successfully!',
      );

      // Clear form
      _titleController.clear();
      _priceController.clear();
      _specificLocationController.clear();
      _descriptionController.clear();
      _imageUrls.clear();
      _videoUrl = null;
      _selectedCategory = null;
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      setState(() {
        _isSubmitting = false;
      });
      await _showStatusCard(
        title: 'Error',
        message: 'Failed to create listing. Please try again.',
      );
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
                      actionLabel: _imageUrls.isEmpty
                          ? 'Add Photos'
                          : 'Edit Photos',
                      countLabel: '${_imageUrls.length}/3',
                      icon: Icons.add_rounded,
                      preview: _imageUrls.isEmpty
                          ? null
                          : Text(
                              '${_imageUrls.length} URL${_imageUrls.length > 1 ? 's' : ''}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                      onTap: _addImageUrl,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _MediaPickerCard(
                      title: 'Video',
                      actionLabel: _videoUrl == null
                          ? 'Add Video'
                          : 'Change Video',
                      countLabel: '1',
                      icon: Icons.videocam_rounded,
                      preview: _videoUrl == null
                          ? null
                          : const Text(
                              '1 URL',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                      onTap: _addVideoUrl,
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
