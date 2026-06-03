import 'package:flutter/material.dart';
import 'models/user_model.dart';
import 'models/product_listing.dart';
import 'services/search_service.dart';
import 'student/listing_details.dart';

class SearchPage extends StatefulWidget {
  final User? currentUser;

  const SearchPage({super.key, this.currentUser});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  SearchResult? _searchResult;
  bool _isLoading = false;
  String _lastSearchQuery = '';

  String _selectedCategory = 'All';
  String _selectedPriceRange = 'All Price';
  String _selectedSortBy = 'Newest First';

  static const List<String> _categories = [
    'All',
    'Textbooks',
    'Electronics',
    'Furniture',
    'Clothing',
    'Medicine',
    'Beauty',
    'Baby',
    'Stationary',
    'Food',
  ];

  static const List<String> _priceRangeOptions = [
    'All Price',
    'Under 10,000 TSH',
    '11,000 - 30,000 TSH',
    'Over 30,000 TSH',
  ];

  static const List<String> _sortOptions = [
    'Newest First',
    'Price: Low to High',
    'Price: High to Low',
    'Most Popular',
  ];

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResult = null;
        _lastSearchQuery = '';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _lastSearchQuery = query;
    });

    try {
      final result = await SearchService.performSearch(query);
      if (mounted) {
        setState(() {
          _searchResult = result;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Search error: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  void _onSuggestionTap(String suggestion) {
    _searchController.text = suggestion;
    _performSearch(suggestion);
  }

  void _openFilters() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: _FilterSheet(
              selectedCategory: _selectedCategory,
              selectedPriceRange: _selectedPriceRange,
              selectedSortBy: _selectedSortBy,
              onCategorySelected: (value) {
                setState(() => _selectedCategory = value);
              },
              onPriceRangeSelected: (value) {
                setState(() => _selectedPriceRange = value);
              },
              onSortBySelected: (value) {
                setState(() => _selectedSortBy = value);
              },
              onClearAll: () {
                setState(() {
                  _selectedCategory = 'All';
                  _selectedPriceRange = 'All Price';
                  _selectedSortBy = 'Newest First';
                });
              },
            ),
          ),
        );
      },
    );
  }

  void _showAlgorithmInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Algorithm'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Fuzzy Matching with Levenshtein Distance',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
              SizedBox(height: 12),
              Text(
                'How it works:\n\n'
                '1. Exact Match: First searches for exact keyword matches in product titles, descriptions, and categories.\n\n'
                '2. Fuzzy Suggestions: Uses Levenshtein distance algorithm to find similar words even with typos.\n\n'
                '3. Similarity Score: Calculates how similar each suggestion is (0-100%), minimum 60% to show.\n\n'
                '4. "Did you mean?": Shows top 5 suggestions if exact search has few results.\n\n'
                'Example: Searching "kndl" suggests "kindle" with high similarity score.',
                style: TextStyle(fontSize: 13, height: 1.6),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        title: const Text(
          'Search',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline_rounded),
            onPressed: _showAlgorithmInfo,
            tooltip: 'Search Algorithm Info',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F7F7),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.search_rounded,
                          color: Color(0xFF9CA3AF),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            textInputAction: TextInputAction.search,
                            onSubmitted: _performSearch,
                            decoration: const InputDecoration(
                              hintText: 'Search textbooks, electronics...',
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  height: 56,
                  width: 56,
                  child: OutlinedButton(
                    onPressed: _openFilters,
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFF4A3DE0)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      padding: EdgeInsets.zero,
                    ),
                    child: const Icon(
                      Icons.filter_list_rounded,
                      size: 26,
                      color: Color(0xFF4A3DE0),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Suggestions section (Google-style "Did you mean?")
          if (_searchResult != null && _searchResult!.hasSuggestions)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: const Color(0xFFF0F4FF),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.lightbulb_outline_rounded,
                        size: 18,
                        color: Color(0xFF2563EB),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Did you mean?',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _searchResult!.suggestions
                        .map(
                          (suggestion) => GestureDetector(
                            onTap: () => _onSuggestionTap(suggestion),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: const Color(0xFF2563EB),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                suggestion,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF2563EB),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),

          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_lastSearchQuery.isEmpty) {
      return _EmptySearchState();
    }

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_searchResult == null || _searchResult!.products.isEmpty) {
      return _NoResultsState(
        query: _lastSearchQuery,
        suggestions: _searchResult?.suggestions ?? [],
        onSuggestionTap: _onSuggestionTap,
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Results for "$_lastSearchQuery" (${_searchResult!.products.length} found)',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF6A5AE0),
            ),
          ),
          const SizedBox(height: 14),
          _MasonryProductGrid(
            listings: _searchResult!.products,
            currentUser: widget.currentUser,
          ),
        ],
      ),
    );
  }
}

class _EmptySearchState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.search_off_rounded, size: 80, color: Color(0xFFE5E7EB)),
          SizedBox(height: 16),
          Text(
            'Search for products',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Enter a product name to get started',
            style: TextStyle(fontSize: 14, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}

class _NoResultsState extends StatelessWidget {
  final String query;
  final List<String> suggestions;
  final Function(String) onSuggestionTap;

  const _NoResultsState({
    required this.query,
    required this.suggestions,
    required this.onSuggestionTap,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.sentiment_dissatisfied_rounded,
              size: 80,
              color: Color(0xFFE5E7EB),
            ),
            const SizedBox(height: 16),
            Text(
              'No results for "$query"',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Try a different search or check the suggestions below',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
            if (suggestions.isNotEmpty) ...[
              const SizedBox(height: 24),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Suggestions:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...suggestions.map(
                    (suggestion) => GestureDetector(
                      onTap: () => onSuggestionTap(suggestion),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.arrow_forward_rounded,
                              size: 16,
                              color: Color(0xFF6A5AE0),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                suggestion,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF2563EB),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MasonryProductGrid extends StatelessWidget {
  final List<ProductListing> listings;
  final User? currentUser;

  const _MasonryProductGrid({
    required this.listings,
    required this.currentUser,
  });

  @override
  Widget build(BuildContext context) {
    final leftItems = <ProductListing>[];
    final rightItems = <ProductListing>[];

    for (var index = 0; index < listings.length; index++) {
      if (index.isEven) {
        leftItems.add(listings[index]);
      } else {
        rightItems.add(listings[index]);
      }
    }

    Widget column(List<ProductListing> items) {
      return Column(
        children: [
          for (var index = 0; index < items.length; index++) ...[
            _SearchProductCard(product: items[index], currentUser: currentUser),
            if (index != items.length - 1) const SizedBox(height: 12),
          ],
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: column(leftItems)),
        const SizedBox(width: 10),
        Expanded(child: column(rightItems)),
      ],
    );
  }
}

class _SearchProductCard extends StatelessWidget {
  final ProductListing product;
  final User? currentUser;

  const _SearchProductCard({required this.product, required this.currentUser});

  String _formatPrice(double value) {
    final whole = value.round();
    return 'Tsh $whole';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: currentUser != null
          ? () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ListingDetailsPage(
                    product: product,
                    currentUser: currentUser!,
                  ),
                ),
              );
            }
          : null,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF5F6F8),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              child: AspectRatio(
                aspectRatio: 1,
                child: product.images.isEmpty
                    ? Container(
                        color: const Color(0xFFE6E6E6),
                        child: const Icon(
                          Icons.image_not_supported_outlined,
                          color: Color(0xFF9A9A9A),
                        ),
                      )
                    : Image.network(
                        product.images.first,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: const Color(0xFFE6E6E6),
                            child: const Icon(
                              Icons.broken_image_rounded,
                              color: Color(0xFF9A9A9A),
                            ),
                          );
                        },
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatPrice(product.price),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1E88E5),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    product.sellerName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF8A8A8A),
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
}

class _FilterSheet extends StatelessWidget {
  final String selectedCategory;
  final String selectedPriceRange;
  final String selectedSortBy;
  final ValueChanged<String> onCategorySelected;
  final ValueChanged<String> onPriceRangeSelected;
  final ValueChanged<String> onSortBySelected;
  final VoidCallback onClearAll;

  const _FilterSheet({
    required this.selectedCategory,
    required this.selectedPriceRange,
    required this.selectedSortBy,
    required this.onCategorySelected,
    required this.onPriceRangeSelected,
    required this.onSortBySelected,
    required this.onClearAll,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            width: 60,
            height: 6,
            decoration: BoxDecoration(
              color: const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            const Expanded(
              child: Text(
                'Filters',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
              ),
            ),
            TextButton(
              onPressed: onClearAll,
              child: const Text(
                'Clear All',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF4A3DE0),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const Text(
          'Category',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _SearchPageState._categories.map((label) {
            final isActive = label == selectedCategory;
            return _FilterChip(
              label: label,
              isActive: isActive,
              onTap: () => onCategorySelected(label),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        const Text(
          'Price Range',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _SearchPageState._priceRangeOptions.map((label) {
            final isActive = label == selectedPriceRange;
            return _FilterChip(
              label: label,
              isActive: isActive,
              onTap: () => onPriceRangeSelected(label),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        const Text(
          'Sort By',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _SearchPageState._sortOptions.map((label) {
            final isActive = label == selectedSortBy;
            return _FilterChip(
              label: label,
              isActive: isActive,
              onTap: () => onSortBySelected(label),
            );
          }).toList(),
        ),
        const SizedBox(height: 30),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF4A3DE0)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: Color(0xFF4A3DE0),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A3DE0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'Apply Filters',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF4A3DE0) : const Color(0xFFF3F3F3),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
